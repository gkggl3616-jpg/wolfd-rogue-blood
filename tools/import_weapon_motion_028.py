"""Preserve exact PV animation events and import the missing grenade throw tracks."""
import argparse,concurrent.futures,gzip,hashlib,json
from pathlib import Path
import numpy as np
from convert_character import load
from ltb_metadata import inspect_ltb
from pc_source_cache import PcSourceCache
ROOT=Path(__file__).resolve().parents[1]
def run(cache):
 source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',cache);library=json.loads((ROOT/'godot/assets/library/weapons.json').read_text());models=library['models'];grenades={r['model'] for r in library['items'] if r['category']=='grenade'}
 rules=json.loads((ROOT/'godot/assets/weapons/native-rules.json').read_text())['items'];shell_models={r['model'] for r in library['items'] if r['category']=='shotgun' and rules[r['id']]['ammoName'].lower()=='supas'}
 paths=sorted({'root/'+m['source'].replace('\\','/').lower().removeprefix('root/') for m in models.values()})
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
  for count,_ in enumerate(pool.map(source.get,paths),1):
   if count%40==0:print('WEAPON_MOTION_PREFETCH',count,'/',len(paths),flush=True)
 out=ROOT/'godot/assets/weapons/animations';out.mkdir(exist_ok=True);records={};issues=[]
 for ident,m in sorted(models.items()):
  path='root/'+m['source'].replace('\\','/').lower().removeprefix('root/');raw=source.get(path)
  assert hashlib.sha256(raw).hexdigest()==m['sourceSha256']
  try:
   info=inspect_ltb(raw);entry={'source':path,'sourceSha256':m['sourceSha256'],'skeletonSha256':info['skeletonSha256'],'bones':info['bones'],'animations':{a['name']:{'durationMs':a['durationMs'],'events':a['keyEvents']} for a in info['animations']}}
   names={a['name'].casefold():a['name'] for a in info['animations']};wanted={names[name] for name in ['prefire','postfire'] if name in names} if ident in grenades else set()
   if ident in shell_models and 'reload2' in names:wanted.add(names['reload2'])
   if wanted:
    model=load(raw,wanted);clips={}
    for name in sorted(wanted):
     clip=model['animations'][name];tracks=[]
     for bone,track in zip(model['info']['bones'],clip['tracks']):
      assert np.isfinite(track['translation']).all() and np.isfinite(track['rotation']).all()
      tracks.append({'bone':bone['name'],'positions':track['translation'].tolist(),'rotations':track['rotation'].tolist()})
     clips[name.casefold()]={'sourceClip':name,'times':clip['times'],'tracks':tracks,'events':entry['animations'][name]['events']}
    body=json.dumps({'sourceSha256':m['sourceSha256'],'bones':info['bones'],'clips':clips},separators=(',',':')).encode();p=out/(ident+'.json.gz');p.write_bytes(gzip.compress(body,mtime=0));entry.update(asset='res://'+str(p.relative_to(ROOT/'godot')),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),throwClips=list(clips))
   records[ident]=entry
  except Exception as error:issues.append({'model':ident,'source':path,'reason':str(error)})
  if len(records)%40==0:print('WEAPON_MOTION_DECODED',len(records),'/',len(models),flush=True)
 result={'schemaVersion':1,'models':records,'issues':issues,'scope':'Literal original animation durations/events; grenade prefire/postfire TRS tracks. Bone hierarchy must match before runtime installation.'}
 (out/'index.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n');proof={'models':len(records),'grenadeModels':len(grenades),'grenadeModelsWithThrowClips':sum('asset' in r for k,r in records.items() if k in grenades),'issues':issues,'scope':result['scope']};(ROOT/'docs/weapon-motion-source-028.json').write_text(json.dumps(proof,indent=2)+'\n');print('WEAPON_MOTION_COMPLETE',proof,flush=True)
if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('cache',type=Path);run(p.parse_args().cache)
