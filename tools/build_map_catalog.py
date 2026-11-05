"""Preserve source mode/map joins for the exact maps selected by the user.

Modern binary tables use (world category, map index), not the display name.
Legacy FM_* definitions are retained as separate evidence, never merged by name.
"""
import argparse,collections,hashlib,json,re,struct
from pathlib import Path
from scan_xfs import unpack_index,recover_entry

ROOT=Path(__file__).resolve().parents[1]
ORIGINAL_SELECTED=(58,59,65,72,1,2,26,31,44,46,50,110,57,100,97,92,82,83,84)
SELECTED=ORIGINAL_SELECTED+(36,69,87,17,51,89,37,42,20,24,68,41,56,61,106)

def normalized(path):return re.sub('/+','/',path.replace('\\','/')).casefold()

def read_modes(data):
    rows=[];pos=0
    while pos<len(data):
        start=pos
        if pos+4>len(data):raise ValueError('Truncated mode definition')
        ident,size=struct.unpack_from('<HH',data,pos);pos+=4
        if not 1<=size<=200 or pos+size*2+16>len(data):raise ValueError('Invalid mode string')
        name=data[pos:pos+size*2].decode('utf-16le');pos+=size*2
        flags=list(data[pos:pos+16]);pos+=16
        rows.append(dict(id=ident,sourceName=name,sourceFlags=flags,sourceOffset=start))
    if len({r['id'] for r in rows})!=len(rows):raise ValueError('Duplicate source mode id')
    return rows

def read_mode_maps(data):
    rows=[];pos=0
    while pos<len(data):
        start=pos
        if pos+11>len(data):raise ValueError('Truncated mode/map record')
        ident,map_index,sort_order,field,category,size=struct.unpack_from('<HBIBBH',data,pos);pos+=11
        if not 1<=size<=200 or pos+size*2+8>len(data):raise ValueError('Invalid mode/map string')
        name=data[pos:pos+size*2].decode('utf-16le');pos+=size*2
        flags=list(data[pos:pos+8]);pos+=8
        rows.append(dict(modeId=ident,mapIndex=map_index,category=category,sourceName=name,sourceSort=sort_order,sourceField=field,sourceFlags=flags,sourceOffset=start))
    return rows

def read_attribute_references(data):
    """Extract validated typed record headers and their single world-file reference.

    Unrecognised or ambiguous records are returned for review, not guessed.
    This is a reference extractor, not a decoder of all map gameplay properties.
    """
    headers=[]
    for match in re.finditer(rb'W\x00T\x00_\x00I\x00n\x00t\x00e\x00r\x00f\x00a\x00c\x00e\x00',data,re.I):
        start=match.start()-17
        if start<0:continue
        category,index,caption,description=struct.unpack_from('<BBII',data,start)
        size=struct.unpack_from('<H',data,match.start()-2)[0]
        if not 1<=category<=31 or not 1000<=caption<=1000000 or not 1000<=description<=1000000 or not 10<=size<=255:continue
        raw=data[match.start():match.start()+size*2]
        if len(raw)!=size*2 or any(raw[i+1] or not 32<=raw[i]<127 for i in range(0,len(raw),2)):continue
        headers.append(dict(category=category,mapIndex=index,captionId=caption,sourceOffset=start,thumbnail=raw.decode('utf-16le')))
    records=[];unresolved=[]
    for i,header in enumerate(headers):
        end=headers[i+1]['sourceOffset'] if i+1<len(headers) else len(data)
        paths=re.findall(rb'w\x00o\x00r\x00l\x00d\x00s\x00(?:[\x20-\x7e]\x00){1,250}?d\x00a\x00t\x00',data[header['sourceOffset']:end],re.I)
        if len(paths)!=1:unresolved.append(dict(**header,reason='world_reference_count',count=len(paths)));continue
        records.append(dict(**header,path=normalized(paths[0].decode('utf-16le'))))
    return records,unresolved

def match_links(path,links,attributes,definitions):
    by_key=collections.defaultdict(list)
    for record in attributes:by_key[(record['category'],record['mapIndex'])].append(record)
    matches=[];undefined=[]
    for link in links:
        refs=by_key.get((link['category'],link['mapIndex']),[])
        if {normalized(r['path']) for r in refs}!={normalized(path)}:continue
        if link['modeId'] not in definitions:
            undefined.append(link);continue
        matches.append(dict(**link,attributeEvidence=[r['sourceOffset'] for r in refs]))
    return matches,undefined

def build(folder):
    archive=folder/'wolf.xfs';entries=unpack_index(archive);lookup={normalized(e['path']):e for e in entries}
    names=dict(modes='Root/wt_attributes/modelist.dat',links='Root/wt_attributes/modemaplist.dat',attributes='Root/wt_interface/attributes/map/mapattribute.dat')
    raw={key:recover_entry(archive,lookup[normalized(name)]) for key,name in names.items()}
    modes=read_modes(raw['modes']);links=read_mode_maps(raw['links']);attributes,unresolved=read_attribute_references(raw['attributes'])
    definitions={m['id']:m for m in modes}
    selection=json.loads((ROOT/'docs/map-selection.json').read_text(encoding='utf-8'))
    for entry in selection['maps']:entry['selected']=entry['number'] in SELECTED
    selection['selectionPending']=False;selection['userSelectedNumbers']=list(SELECTED)
    selected=[];undefined=[]
    preview_path=ROOT/'godot/assets/maps/previews.json'
    previews={int(p['number']):p for p in json.loads(preview_path.read_text(encoding='utf-8'))} if preview_path.exists() else {}
    for entry in selection['maps']:
        if not entry['selected']:continue
        path=normalized('worlds/retailmultiplayer/'+entry['path'])
        matches,unknown=match_links(path,links,attributes,definitions)
        undefined.extend(dict(mapNumber=entry['number'],**link) for link in unknown)
        ids=sorted({r['modeId'] for r in matches})
        display=next((r['sourceName'] for r in matches),Path(entry['path']).stem.replace('_',' ').title())
        preview=previews.get(entry['number'],{})
        selected.append(dict(number=entry['number'],path=entry['path'],displayName=display,allowedModeIds=ids,modeEvidence=matches,status='mode_verified_gameplay_pending' if ids and preview.get('previewValidated') else ('mode_verified_asset_pending' if ids else 'mode_unverified'),enabled=False,asset=None,previewAvailable=bool(ids and preview.get('previewValidated')),sourceBytes=entry['bytes']))
    for mode in modes:
        mode['mapNumbers']=[m['number'] for m in selected if mode['id'] in m['allowedModeIds']]
        mode['implementationStatus']='catalog_only'
    result=dict(schemaVersion=1,title='Wolf Rogue Blood',selection=list(SELECTED),sourceTables={k:dict(path=names[k],sha256=hashlib.sha256(v).hexdigest(),bytes=len(v)) for k,v in raw.items()},modes=[m for m in modes if m['mapNumbers']],maps=selected,unresolvedModeLinks=undefined,unresolvedAttributeRecords=unresolved,policy='Mode-specific allowlist only. A selected file without a verified exact mode/category/map-index join stays disabled. Random selection is restricted to ready maps in the selected mode.')
    (ROOT/'docs/map-selection.json').write_text(json.dumps(selection,ensure_ascii=False,indent=2),encoding='utf-8')
    return result

def main():
    parser=argparse.ArgumentParser();parser.add_argument('folder',type=Path);args=parser.parse_args()
    result=build(args.folder)
    for name in ['godot/assets/maps/catalog.json','docs/selected-map-modes.json','web/maps.json']:
        path=ROOT/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    lines=['# Seçilen haritalar ve doğrulanan modlar','','19 kullanıcı seçimi. Mod eşleşmeleri yeni ikili tablolardan kategori + harita kimliği üzerinden alınır; isim benzerliği kullanılmaz. 19 temel geometri dönüştürüldü ve doğma noktaları/üretilen çarpışmalar motor içinde kontrol edildi. Eşleşmesi doğrulanan 18 haritada gezinti önizlemesi açılır; özgün mod kuralları hâlâ bekliyor. Tam harita/mod portu değildir.','','| No | Harita | Doğrulanan modlar |','|---:|---|---|']
    mode_lookup={m['id']:m for m in result['modes']}
    for m in result['maps']:
        lines.append(f"| {m['number']} | {m['displayName']} | {', '.join(mode_lookup[i]['sourceName'] for i in m['allowedModeIds']) or 'Doğrulanamadı; seçime kapalı'} |")
    (ROOT/'docs/SECILEN_HARITA_MODLARI.md').write_text('\n'.join(lines),encoding='utf-8')
    print(json.dumps(dict(selected=len(result['maps']),verified=sum(bool(m['allowedModeIds']) for m in result['maps']),modeCount=len(result['modes']),unverified=[m['path'] for m in result['maps'] if not m['allowedModeIds']])))

if __name__=='__main__':main()
