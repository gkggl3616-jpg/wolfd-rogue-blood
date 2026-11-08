"""Decode bounded per-mode native fire/reload/select sound fields and event IDs."""
import argparse,concurrent.futures,gzip,hashlib,json,struct
from pathlib import Path
from pc_source_cache import PcSourceCache
ROOT=Path(__file__).resolve().parents[1]
def normalize(path):return 'root/'+path.replace('\\','/').lower().removeprefix('root/')
def run(cache):
 raw=gzip.decompress((ROOT/'docs/pc_sources_017/weapondata.dat.gz').read_bytes());lib=json.loads((ROOT/'godot/assets/library/weapons.json').read_text());media=json.loads((ROOT/'godot/assets/shared_media/catalog.json').read_text())['sounds'];records={};references=set();issues=[]
 for item in lib['items']:
  p=int(item['sourceModelOffset'])
  def text():
   nonlocal p
   n=struct.unpack_from('<H',raw,p)[0];assert n<2048;p+=2;v=raw[p:p+n*2].decode('utf-16le');p+=n*2;return v
  model=text()
  assert normalize(model)==normalize(lib['models'][item['model']]['source'])
  for _ in range(27):text()
  p+=24;pv_fx=text();hh_model=text();hh_skin=text();hh_fx=text();fire_pos=p;fire=text();radius,volume=struct.unpack_from('<fH',raw,p);p+=6
  reloads=[text() for _ in range(3)];reload_radius=struct.unpack_from('<f',raw,p)[0];p+=4;select=text();select_radius=struct.unpack_from('<f',raw,p)[0]
  values={'10':fire,'1':reloads[0],'2':reloads[1],'3':reloads[2],'4':select}
  assert all(not n or n.lower().startswith(('wt_snd\\','guns\\')) for n in values.values())
  keys={k:normalize(n) for k,n in values.items() if n};references.update(keys.values())
  records[item['id']]={'sourceId':int(item['sourceId']),'modelOffset':int(item['sourceModelOffset']),'fireFieldOffset':fire_pos,'keys':keys,'fireRadius':radius,'fireVolume':volume,'reloadRadius':reload_radius,'selectRadius':select_radius,'hhModel':hh_model,'hhSkin':hh_skin,'hhMuzzleFx':hh_fx}
 source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',cache);out=ROOT/'godot/assets/weapons/audio';out.mkdir(exist_ok=True);sounds={}
 needed=sorted(n for n in references if n not in media and n in source.lookup)
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
  for path,b in zip(needed,pool.map(source.get,needed)):
   assert b[:4]==b'RIFF' and b[8:12]==b'WAVE';p=out/(hashlib.sha256(path.encode()).hexdigest()[:24]+'.wav');p.write_bytes(b);sounds[path]={'asset':'res://'+str(p.relative_to(ROOT/'godot')),'sha256':hashlib.sha256(b).hexdigest(),'sourceSha256':hashlib.sha256(b).hexdigest(),'source':path}
 for n in references:
  if n not in media and n not in sounds:issues.append({'source':n,'reason':'Exact source sound is absent from the supplied archive'})
 result={'schemaVersion':1,'sourceSha256':hashlib.sha256(raw).hexdigest(),'items':records,'sounds':sounds,'issues':issues,'scope':'Native sound keys1-3 reload,4 select,10 fire, matched to original animation events. Other native sound-key meanings remain unverified.'}
 (ROOT/'godot/assets/weapons/audio.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n');proof={'records':len(records),'uniqueSounds':len(references),'addedOriginalSounds':len(sounds),'issues':issues,'sourceSha256':result['sourceSha256'],'scope':result['scope']};(ROOT/'docs/weapon-audio-source-028.json').write_text(json.dumps(proof,indent=2)+'\n');print('WEAPON_AUDIO_COMPLETE',proof,flush=True)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('cache',type=Path);run(p.parse_args().cache)
