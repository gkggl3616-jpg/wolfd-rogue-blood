"""Read exact DTX surface flags and original shoot-through limits, without name guesses."""
import argparse,concurrent.futures,gzip,hashlib,json,struct
from pathlib import Path
from clientfx import parse_butes
from pc_source_cache import PcSourceCache
ROOT=Path(__file__).resolve().parents[1]
def run(cache):
 cache=Path(cache);source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',cache)
 raw=source.get('root/attributes/surface.txt');props=parse_butes(raw)
 surfaces={str(int(r['Id'])):r for r in props.values() if 'Id' in r and 'Name' in r}
 keys=set()
 for path in (ROOT/'godot/assets/maps/geometry').glob('*.glb'):
  with path.open('rb') as stream:stream.seek(12);size,_=struct.unpack('<II',stream.read(8));doc=json.loads(stream.read(size))
  keys.update(m.get('name','').replace('\\','/').lower() for m in doc.get('materials',[]))
 pending=cache/'surface-material-progress.json';records=json.loads(pending.read_text()) if pending.exists() else {}
 def fetch(key):
  if not key.endswith('.dtx') or 'root/'+key not in source.lookup:return key,{'unavailable':'Original DTX material absent'}
  data=source.get('root/'+key);assert struct.unpack_from('<I',data)[0]==0
  flags=struct.unpack_from('<I',data,20)[0];ident=flags&255
  if str(ident) not in surfaces:return key,{'unavailable':'Unrecognized original DTX surface flag','userFlags':flags}
  origin=source.lookup['root/'+key]['name'].replace('\\','/').casefold();target=cache/(hashlib.sha256(origin.encode()).hexdigest()[:24]+Path(origin).suffix)
  result={'surface':ident,'userFlags':flags,'sourceSha256':hashlib.sha256(data).hexdigest()}
  target.unlink(missing_ok=True) # Reproducible header-only cache; never remove game assets.
  return key,result
 with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
  tasks={pool.submit(fetch,k):k for k in sorted(keys) if k not in records}
  for future in concurrent.futures.as_completed(tasks):
   key=tasks[future]
   try:key,result=future.result();records[key]=result
   except Exception as error:records[key]={'unavailable':str(error)}
   if len(records)%25==0:pending.write_text(json.dumps(records));print('SURFACE_HEADERS',len(records),'/',len(keys),flush=True)
 pending.write_text(json.dumps(records));result={'schemaVersion':1,'source':'root/attributes/surface.txt','sourceSha256':hashlib.sha256(raw).hexdigest(),
  'surfaces':surfaces,'materials':records,'sourceWorldScale':.016,
  'policy':'DTX userFlags low byte only; no filename/material-name inference. Unknown flags block penetration. Brush-specific overrides remain separate source data.'}
 (ROOT/'godot/assets/gameplay/surfaces.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
 (ROOT/'docs/surface-source-027.json').write_text(json.dumps({'sourceSha256':result['sourceSha256'],'materials':len(records),'surfaceDefinitions':len(surfaces),'knownFlags':sum('surface' in v for v in records.values()),'shootThroughMaterials':sum(bool(surfaces[str(v['surface'])].get('CanShootThrough')) for v in records.values() if 'surface' in v),'unavailable':[{'material':k,**v} for k,v in records.items() if 'unavailable' in v]},ensure_ascii=False,indent=2)+'\n')
 proof_path=ROOT/'docs/surface-source-027.json';proof=json.loads(proof_path.read_text())
 sounds=json.loads((ROOT/'godot/assets/shared_media/catalog.json').read_text())['sounds']
 groups=json.loads((ROOT/'godot/assets/clientfx/catalog.json').read_text())['groups'];case={k.casefold() for k in groups}
 used={str(r['surface']) for r in records.values() if 'surface' in r}
 refs={'root/'+r[k].replace('\\','/').lower() for i,r in surfaces.items() if i in used for k in ['BulletImpactSnd1','BulletImpactSnd2'] if r.get(k)}
 proof.update(usedSurfaceIds=sorted(map(int,used)),usedImpactSounds=len(refs),usedImpactSoundsAvailable=len(refs&set(sounds)),missingUsedImpactSounds=sorted(refs-set(sounds)),missingUsedImpactEffects=sorted({r[k] for i,r in surfaces.items() if i in used for k in ['ImpactFXName','ExitFXName'] if r.get(k) and r[k].casefold() not in case}))
 proof_path.write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n')
 print('SURFACE_IMPORT_COMPLETE',len(records),flush=True)
if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('cache',type=Path);run(parser.parse_args().cache)
