"""Import a diverse finite NPC arsenal from verified supplied HH models/skins."""
import argparse,concurrent.futures,hashlib,json
from pathlib import Path
from convert_character import load,glb,texture_png
from pc_source_cache import PcSourceCache
from ltb_metadata import inspect_ltb
ROOT=Path(__file__).resolve().parents[1]
LIMITS={'rifle':8,'smg':4,'shotgun':4,'machinegun':4,'pistol':8,'knife':8,'sniper':8,'grenade':8,'heavy':2,'rocket':3,'launcher':2}
def run(cache):
 source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',cache);library=json.loads((ROOT/'godot/assets/library/weapons.json').read_bytes());banks=json.loads((ROOT/'godot/assets/weapons/audio.json').read_bytes())['items'];rules=json.loads((ROOT/'godot/assets/weapons/native-rules.json').read_bytes())['items'];media=json.loads((ROOT/'godot/assets/shared_media/catalog.json').read_bytes())['sounds'];motion=json.loads((ROOT/'godot/assets/weapons/animations/index.json').read_bytes())['models'];selected=[]
 def path(value):return 'root/'+value.replace('\\','/').lower().removeprefix('root/')
 for category,limit in LIMITS.items():
  rows=[w for w in library['items'] if w['category']==category and w.get('available') and w['id'] in banks and path(banks[w['id']]['hhModel']) in source.lookup and path(banks[w['id']]['hhSkin']) in source.lookup and w['name']!='EM-2 HB' and (category!='grenade' or rules[w['id']]['splashDamage']>0)]
  chosen=[];models=set();skins=set()
  for distinct in ['model','skin']:
   for w in rows:
    b=banks[w['id']];m=path(b['hhModel']);s=path(b['hhSkin'])
    if w['id'] in {a['id'] for a in chosen} or len(chosen)>=limit:continue
    if (distinct=='model' and m not in models) or (distinct=='skin' and (m,s) not in skins):chosen.append(w);models.add(m);skins.add((m,s))
  selected.extend(chosen)
 needed={path(banks[w['id']][key]) for w in selected for key in ['hhModel','hhSkin']}
 with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
  for _ in pool.map(source.get,sorted(needed)):pass
 out=ROOT/'godot/assets/bots/arsenal';out.mkdir(exist_ok=True);profiles={};textures={}
 for w in selected:
  bank=banks[w['id']];model_path=path(bank['hhModel']);skin_path=path(bank['hhSkin']);raw=source.get(model_path);skin=source.get(skin_path);a=load(raw,set());metadata=inspect_ltb(raw);png=texture_png(skin);skins={slot:(skin_path,png) for slot in {mesh['material'] for mesh in a['meshes']}};target=out/(w['id']+'.glb');glb(a,a,skins,{},target,root_scale=.016,freeze_root=False,alpha_mask=False,external_texture_dir=out)
  native=rules[w['id']];reload=next((v['durationMs']/1000 for k,v in motion[w['model']]['animations'].items() if k.lower()=='reload'),float(w['gameplayTuning']['reloadSeconds']))
  profiles[w['id']]={'itemId':w['id'],'name':w['name'],'category':w['category'],'asset':'res://'+str(target.relative_to(ROOT/'godot')),'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'source':model_path,'sourceSha256':hashlib.sha256(raw).hexdigest(),'skinSource':skin_path,'skinSourceSha256':hashlib.sha256(skin).hexdigest(),'native':native,'capacity':native['capacity'],'fireInterval':native['fireIntervalMs']/1000,'reloadSeconds':reload,'reloadPerShell':native['ammoName'].lower()=='supas' and any(k.lower()=='reload2' for k in motion[w['model']]['animations']),'reloadFinishSeconds':next((v['durationMs']/1000 for k,v in motion[w['model']]['animations'].items() if k.lower()=='reload2'),0),'fireSound':media.get(bank['keys'].get('10',''),{}).get('asset',''),'reloadSound':media.get(bank['keys'].get('1',''),{}).get('asset',''),'sockets':metadata['socketDefinitions'],'bones':metadata['bones'],'hhMuzzleFx':bank['hhMuzzleFx']}
  print('NPC_NATIVE_ARSENAL',len(profiles),len(selected),w['name'],flush=True)
 for stale in out.glob('*.glb'):
  if stale.name not in {w['itemId']+'.glb' for w in profiles.values()}:stale.unlink();stale.with_suffix('.glb.import').unlink(missing_ok=True)
 for p in out.glob('*.png'):textures[p.name]={'asset':'res://'+str(p.relative_to(ROOT/'godot')),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
 result={'schemaVersion':1,'profiles':profiles,'textures':textures,'scope':'Native supplied model/skin, capacity/cadence and reload clip duration. NPC hit damage remains8 for every difficulty. Roster choices/tactics are local simulation; no account ownership or PC bot implementation is claimed.'};(ROOT/'godot/assets/bots/arsenal.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n');proof={**result,'categories':{c:sum(w['category']==c for w in profiles.values()) for c in LIMITS}};(ROOT/'docs/bot-arsenal-source-029.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('cache',type=Path);run(p.parse_args().cache)
