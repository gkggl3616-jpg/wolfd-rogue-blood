"""Import fifteen reproducibly shuffled, distinct PC maps for the expanded local edition."""
import concurrent.futures,hashlib,json,pathlib,random,sys
from pc_source_cache import PcSourceCache
import convert_world as cv
from build_map_catalog import read_modes,read_mode_maps,read_attribute_references,match_links
ROOT=pathlib.Path(__file__).resolve().parents[1]
source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',sys.argv[1]);cv.recover_entry=lambda _,row:source.get(row['name'])
selection=json.loads((ROOT/'docs/map-selection.json').read_text());catalog=json.loads((ROOT/'godot/assets/maps/catalog.json').read_text());existing=set(json.loads((ROOT/'docs/map-expansion-015.json').read_text())['original']) if (ROOT/'docs/map-expansion-015.json').exists() else set(catalog['selection'])
catalog['maps']=[r for r in catalog['maps'] if r['number'] in existing];catalog['selection']=[n for n in catalog['selection'] if n in existing]
# Avoid duplicate themed derivatives and previously excluded entrance/two-temple maps.
candidates=[r for r in selection['maps'] if r['number'] not in existing and r['menuDefinitions'] and r['bytes']<30000000 and not any(w in r['path'].lower() for w in ['temple','arrival','entrance','wolfrush','celebrity','christmas','_conq','_ai','_wtas','_rush'])]
random.Random(20261105).shuffle(candidates)
raw_modes=source.get('root/wt_attributes/modelist.dat');raw_links=source.get('root/wt_attributes/modemaplist.dat');raw_attr=source.get('root/wt_interface/attributes/map/mapattribute.dat')
modes=read_modes(raw_modes);links=read_mode_maps(raw_links);attrs,_=read_attribute_references(raw_attr);definitions={r['id']:r for r in modes}
report=[r for r in json.loads((ROOT/'docs/map-conversion.json').read_text()) if r['number'] in existing];added=[];failures=[];base=ROOT/'godot/assets/maps'
for entry in candidates:
 if len(added)==15:break
 key='root/worlds/retailmultiplayer/'+entry['path'].lower()
 matches,unknown=match_links('worlds/retailmultiplayer/'+entry['path'].lower(),links,attrs,definitions)
 title=next((r['sourceName'] for r in matches),pathlib.Path(entry['path']).stem.replace('_',' ').title())
 if title.casefold() in {r['displayName'].casefold() for r in catalog['maps']}:continue
 try:
  print('FETCH_MAP',entry['number'],entry['path'],flush=True);raw=source.get(key);blocks,objects,info=cv.parse_world(raw)
  teams={o['properties'].get('Team') for o in objects if o['type']=='GameStartPoint' and o['properties'].get('SpawnPoint') and not o['properties'].get('Locked')}
  if not ('Team1' in teams and ('Team0' in teams or 'NoTeam' in teams)):raise ValueError('two source spawn groups absent')
  textures=set()
  for b in blocks:
   if b['model']:continue
   for s in b['sections']:
    k='root/'+s['texture'].replace('\\','/').casefold()
    if k in source.lookup and k.endswith('.dtx') and s['shader'] not in (0,2,5,6,7,10):textures.add(k)
  with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
   results=list(pool.map(source.get,sorted(textures)))
  result=cv.write_glb(blocks,objects,source.lookup,None,base/'geometry'/f"{entry['number']}.glb",base/'textures')
  if result['missingTextures']:raise ValueError('unresolved world textures '+str(len(result['missingTextures'])))
  result.update(number=entry['number'],source=key,sourceSha256=hashlib.sha256(raw).hexdigest(),parse=info,objects=len(objects),previewAsset=f"res://assets/maps/geometry/{entry['number']}.glb",fullPort=False)
  (base/f"{entry['number']}-objects.json").write_text(json.dumps(objects,ensure_ascii=False,indent=2,allow_nan=False))
  matches,unknown=match_links('worlds/retailmultiplayer/'+entry['path'].lower(),links,attrs,definitions);ids=sorted({r['modeId'] for r in matches})
  title=next((r['sourceName'] for r in matches),pathlib.Path(entry['path']).stem.replace('_',' ').title())
  catalog['maps'].append(dict(number=entry['number'],path=entry['path'],displayName=title,allowedModeIds=ids,modeEvidence=matches,status='mode_verified_gameplay_pending' if ids else 'mode_unverified',enabled=False,asset=None,previewAvailable=bool(ids),sourceBytes=entry['bytes']))
  report.append(result);added.append(entry['number']);print('IMPORTED_MAP',entry['number'],title,result['triangles'],flush=True)
 except Exception as error:failures.append({'number':entry['number'],'reason':str(error)});print('MAP_REJECTED',entry['number'],str(error),flush=True)
for candidate in candidates:
 if candidate['number'] not in existing and candidate['number'] not in added:
  (base/'geometry'/f"{candidate['number']}.glb").unlink(missing_ok=True);(base/f"{candidate['number']}-objects.json").unlink(missing_ok=True)
selected=list(catalog['selection'])+added;catalog['selection']=selected
for mode in modes:
 mode['mapNumbers']=[r['number'] for r in catalog['maps'] if mode['id'] in r['allowedModeIds']];mode['implementationStatus']='catalog_only'
catalog['modes']=[r for r in modes if r['mapNumbers']]
for r in selection['maps']:r['selected']=r['number'] in selected
selection['userSelectedNumbers']=selected
for name,data in [('godot/assets/maps/catalog.json',catalog),('docs/selected-map-modes.json',catalog),('web/maps.json',catalog),('docs/map-selection.json',selection),('docs/map-conversion.json',report)]:
 (ROOT/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
(ROOT/'docs/map-expansion-015.json').write_text(json.dumps({'seed':20261105,'added':added,'original':sorted(existing),'rejected':failures,'requestedAdditional':15},ensure_ascii=False,indent=2)+'\n')
assert len(added)==15,('Expected fifteen complete source maps',added)
