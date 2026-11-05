import sys,pathlib,json,concurrent.futures,hashlib
# Install tools/archive-requirements.txt; libarchive must support RAR5.
from build_map_catalog import read_attribute_references,normalized
from pc_source_cache import PcSourceCache
from convert_character import texture_png
import argparse
ROOT=pathlib.Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description='Restore exact PC map photographs from mapattribute.dat associations')
parser.add_argument('--cache',type=pathlib.Path,required=True)
args=parser.parse_args();folder=args.cache.resolve();folder.mkdir(parents=True,exist_ok=True)
source_cache=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',folder)
attribute_path=folder/'mapattribute.dat'
if not attribute_path.is_file() or __import__('hashlib').sha256(attribute_path.read_bytes()).hexdigest()!=__import__('json').loads((ROOT/'godot/assets/maps/catalog.json').read_bytes())['sourceTables']['attributes']['sha256']:attribute_path.write_bytes(source_cache.get('root/wt_interface/attributes/map/mapattribute.dat'))
attrs,unresolved=read_attribute_references(attribute_path.read_bytes());catalog=json.loads((ROOT/'godot/assets/maps/catalog.json').read_text())
files=json.loads(__import__('gzip').decompress((ROOT/'docs/pc-archive-inventory.json.gz').read_bytes()))['files'];lookup={normalized(row['name']):row['name'] for row in files}
out=ROOT/'godot/assets/maps/thumbnails';out.mkdir(exist_ok=True)
ui=json.loads((ROOT/'godot/assets/ui/catalog.json').read_text())['textures']
previous={r['number']:r for r in json.loads((ROOT/'godot/assets/maps/photos.json').read_text())['maps']}
def get(m):
 path=normalized('worlds/retailmultiplayer/'+m['path']);matches=[row for row in attrs if row['path']==path];sources={normalized(row['thumbnail']) for row in matches};assert len(sources)==1
 source=sources.pop();member=lookup[normalized('wolfteam kurtları/Root/'+source)];raw=folder/(str(m['number'])+'.dtx')
 if m['number'] in previous:return previous[m['number']]
 native=ui.get(source)
 if native:
  png=ROOT/'godot'/native['asset'].removeprefix('res://')
  return {'number':m['number'],'name':m['displayName'],'asset':native['asset'],'sha256':hashlib.sha256(png.read_bytes()).hexdigest(),'source':member,'sourceSha256':native['sourceSha256'],'attributeOffsets':[x['sourceOffset'] for x in matches]}
 if not raw.is_file():raw.write_bytes(source_cache.get(member))
 png=out/(str(m['number'])+'.png');png.write_bytes(texture_png(raw.read_bytes()))
 return {'number':m['number'],'name':m['displayName'],'asset':'res://assets/maps/thumbnails/'+png.name,'sha256':hashlib.sha256(png.read_bytes()).hexdigest(),'source':member,'sourceSha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'attributeOffsets':[x['sourceOffset'] for x in matches]}
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:rows=list(pool.map(get,catalog['maps']))
result={'schemaVersion':1,'sourceAttributeSha256':hashlib.sha256((folder/'mapattribute.dat').read_bytes()).hexdigest(),'maps':rows,'association':'Exact world-file reference and thumbnail path from typed PC mapattribute.dat record; not a name guess.'}
(ROOT/'godot/assets/maps/photos.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print('SOURCE_MAP_PHOTOS',len(rows),flush=True)
