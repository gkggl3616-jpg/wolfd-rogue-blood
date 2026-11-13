"""Import literal projectile/impact definitions and the exact provided flight models."""
import argparse,concurrent.futures,gzip,hashlib,json
from pathlib import Path
from clientfx import parse_butes
from convert_character import load,glb,texture_png
from pc_source_cache import PcSourceCache
from ltb_metadata import inspect_ltb
ROOT=Path(__file__).resolve().parents[1]
def key(path):return path.replace('\\','/').lower().removeprefix('root/')
def run(cache):
 source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',cache)
 raw=gzip.decompress((ROOT/'docs/pc_sources_017/fx.txt.gz').read_bytes());tables=parse_butes(raw)
 rules=json.loads((ROOT/'godot/assets/weapons/native-rules.json').read_text())['items'];needed={r['projectile'] for r in rules.values() if r['projectile']};impact_names={r['impactFx'] for r in rules.values() if r['impactFx']}
 fx=json.loads((ROOT/'godot/assets/clientfx/catalog.json').read_text());known={n.casefold():n for n in fx['groups']}
 shared=json.loads((ROOT/'godot/assets/shared_media/catalog.json').read_text())['sounds'];textures=dict(fx['textures']);sounds={};models={};projectiles={};issues=[];impacts={}
 out=ROOT/'godot/assets/weapons/projectiles';out.mkdir(exist_ok=True)
 def texture(name):
  path=key(name)
  if path in textures:return textures[path]
  b=source.get('root/'+path);png=texture_png(b);p=out/(hashlib.sha256(path.encode()).hexdigest()[:24]+'.png');p.write_bytes(png)
  textures[path]={'asset':'res://'+str(p.relative_to(ROOT/'godot')),'sha256':hashlib.sha256(png).hexdigest(),'source':path,'sourceSha256':hashlib.sha256(b).hexdigest()};return textures[path]
 def sound(name):
  if not name or name.casefold()=='surface':return ''
  path='root/'+key(name)
  if path in shared:return shared[path]['asset']
  if path in sounds:return sounds[path]['asset']
  if path not in source.lookup:
   issues.append({'type':'sound','source':path,'reason':'Not provided in the PC archive'});return ''
  b=source.get(path)
  if not (b[:4]==b'RIFF' and b[8:12]==b'WAVE'):raise ValueError('Invalid original sound '+path)
  p=out/(hashlib.sha256(path.encode()).hexdigest()[:24]+'.wav');p.write_bytes(b);sounds[path]={'asset':'res://'+str(p.relative_to(ROOT/'godot')),'source':path,'sourceSha256':hashlib.sha256(b).hexdigest(),'sha256':hashlib.sha256(b).hexdigest()};return sounds[path]['asset']
 paths=set()
 for section,props in tables.items():
  if (section.startswith('ProjectileFX') and props.get('Name') in needed) or (section.startswith('ImpactFX') and props.get('Name') in impact_names):
   for field in ['Model','Skin','Sound']:
    path='root/'+key(props.get(field,''))
    if path in source.lookup:paths.add(path)
 with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
  for number,_ in enumerate(pool.map(source.get,sorted(paths)),1):
   if number%20==0:print('SOURCE_PROJECTILE_PREFETCH',number,'/',len(paths),flush=True)
 for section,props in tables.items():
  if not section.startswith('ImpactFX') or props.get('Name') not in impact_names:continue
  impacts[props['Name']]={'properties':props,'sourceSection':section,'fx':known.get(str(props.get('FXName','')).casefold(),''),'sound':sound(props.get('Sound',''))}
 for section,props in tables.items():
  if not section.startswith('ProjectileFX') or props.get('Name') not in needed:continue
  name=props['Name'];record={'properties':props,'sourceSection':section,'trailFx':known.get(str(props.get('FXName','')).casefold(),''),'indicateFx':known.get(str(props.get('IndicateFXName','')).casefold(),''),'sound':sound(props.get('Sound','')),'availableModel':False}
  path=key(props.get('Model',''));skin=key(props.get('Skin',''));model_key=hashlib.sha256((path+'|'+skin).encode()).hexdigest()[:24]
  try:
   if model_key not in models:
    b=source.get('root/'+path);a=load(b,set());info=inspect_ltb(b);skins={}
    if skin:
     t=texture(skin);png=(ROOT/'godot'/t['asset'].removeprefix('res://')).read_bytes()
     for slot in {m['material'] for m in a['meshes']}:skins[slot]=(skin,png)
    p=out/(model_key+'.glb');glb(a,a,skins,{},p,root_scale=.016,freeze_root=False,alpha_mask=False,external_texture_dir=out,allow_untextured=True)
    models[model_key]={'asset':'res://'+str(p.relative_to(ROOT/'godot')),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'source':'root/'+path,'sourceSha256':hashlib.sha256(b).hexdigest(),'skin':skin,'bones':info['bones'],'sockets':{r['name']:r for r in info['socketDefinitions']},'visibleModel':bool(skin),'triangles':sum(len(m['indices'])//3 for m in a['meshes'])}
   record.update(models[model_key]);record['availableModel']=True
  except Exception as error:record['unavailableReason']=str(error);issues.append({'type':'model','name':name,'source':path,'reason':str(error)})
  projectiles[name]=record;print('NATIVE_PROJECTILE',len(projectiles),'/',len(needed),name,record['availableModel'],flush=True)
 assert set(projectiles)==needed
 issues=list({json.dumps(i,sort_keys=True):i for i in issues}.values())
 result={'schemaVersion':1,'source':'root/attributes/fx.txt','sourceSha256':hashlib.sha256(raw).hexdigest(),'projectiles':projectiles,'impacts':impacts,'sounds':sounds,'models':models,'textures':{k:v for k,v in textures.items() if v['asset'].startswith('res://assets/weapons/projectiles/')},'issues':issues,
  'scope':'Exact supplied source models, skins, class names, velocity/gravity/lifetime and impact associations. Collision shape, bounce and area-damage falloff remain explicit local simulation adapters.'}
 (ROOT/'godot/assets/gameplay/projectiles.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
 proof={k:result[k] for k in ['source','sourceSha256','issues','scope']};proof.update(projectiles=len(projectiles),models=len(models),availableModels=sum(r['availableModel'] for r in projectiles.values()),impacts=len(impacts),addedOriginalSounds=len(sounds),classes=sorted({r['properties']['Class'] for r in projectiles.values()}),missingImpactDefinitions=sorted(impact_names-set(impacts)))
 (ROOT/'docs/projectile-source-028.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n');print('PROJECTILE_IMPORT_COMPLETE',json.dumps(proof),flush=True)
if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('cache',type=Path);run(p.parse_args().cache)
