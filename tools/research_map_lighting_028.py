"""Read native light block layout without changing map geometry or claiming lighting parity."""
import argparse,collections,hashlib,json
from pathlib import Path
from pc_source_cache import PcSourceCache
ROOT=Path(__file__).resolve().parents[1]
def run(cache):
 code=(ROOT/'tools/convert_world.py').read_text()
 before='w,h,size=r.unpack(\'3I\');r.take(size)';after='w,h,size=r.unpack(\'3I\');lightmap=r.take(size)'
 assert code.count(before)==1 and code.count('effect=effect))')==1
 code=code.replace(before,after).replace('effect=effect))','effect=effect,lightWidth=w,lightHeight=h,compressedBytes=size,lightSha256=hashlib.sha256(lightmap).hexdigest()))')
 namespace={'__file__':str(ROOT/'tools/convert_world.py'),'__name__':'light_layout_probe'};exec(code,namespace)
 source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',cache);catalog=json.loads((ROOT/'docs/map-conversion.json').read_bytes());rows=[]
 for number in [37,72,106]:
  original=next(r for r in catalog if int(r['number'])==number);raw=source.get(original['source']);assert hashlib.sha256(raw).hexdigest()==original['sourceSha256']
  blocks,objects,info=namespace['parse_world'](raw);sections=[s for b in blocks for s in b['sections'] if s['compressedBytes']]
  sizes=collections.Counter((s['lightWidth'],s['lightHeight'],s['compressedBytes']) for s in sections)
  rows.append({'map':number,'source':original['source'],'sourceSha256':original['sourceSha256'],'parse':info,'lightSections':len(sections),'compressedBytes':sum(s['compressedBytes'] for s in sections),'layouts':[{'width':w,'height':h,'bytes':size,'count':count} for (w,h,size),count in sorted(sizes.items())],'nativeWorldModelNames':sorted({b['model'] for b in blocks if b['model']})})
 result={'maps':rows,'runtimeLightingChanged':False,'fullyDecoded':False,'scope':'Exact native compressed block dimensions/lengths, full DAT render consumption and source hashes only. Codec, UV/light response and native BSP collision remain unresolved. No invisible geometry or substitute lightmap was generated.'}
 (ROOT/'docs/map-lighting-research-028.json').write_text(json.dumps(result,indent=2)+'\n');print('NATIVE_LIGHT_LAYOUT',[(r['map'],r['lightSections']) for r in rows])
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('cache',type=Path);run(p.parse_args().cache)
