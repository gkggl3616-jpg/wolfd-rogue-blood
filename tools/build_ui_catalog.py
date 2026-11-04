"""Compile original GUI records into explicit, auditable runtime bindings."""
from collections import Counter
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
UI_TEXT = 'wt_interface/stringtable/stringtable.txt'
UI_FALLBACK = 'wt_interface/attributes/stringtable/stringtable.txt'
DIALOG_TYPES = {'exmessagebox','bighitmessagebox','messagebox','passwordmessagebox','shoutingmessagebox',
                'prideintromessagebox','camppointdetailmessagebox','campdonationmessagebox','campselectmessagebox',
                'upgrademessagebox','promotiondialog','giftreceverinputbox','giftreceverconfirmbox'}


def field(record, name, default=None):
    return record.get('fields', {}).get(name, [default])[0]


def texture_key(value):
    path=str(value).strip().strip('"').replace('\\','/').lower()
    while '//' in path:path=path.replace('//','/')
    if '/game/wt_interface/' in path:path='wt_interface/'+path.split('/game/wt_interface/',1)[1]
    return path.removeprefix('root/')


def family(kind):
    kind = kind.casefold()
    if kind == 'staticsprite' or kind == 'hudweaponforceicon': return 'image'
    if kind in {'statictext', 'prideladderranknotice', 'toprankermemo'}: return 'text'
    if kind == 'number': return 'digits'
    if kind in {'buttongropbox', 'buttongroupboxex'}: return 'group'
    if 'combobox' in kind: return 'choice'
    if kind in {'editbox', 'rankingeditbox'}: return 'input'
    if kind == 'slider': return 'slider'
    if kind == 'palette': return 'color'
    if kind == 'line': return 'line'
    if kind in {'textscrollbox', 'memobox', 'webpage', 'webpageex', 'chatsystemmessage'}: return 'text_area'
    if 'button' in kind or kind in {'itemperformance', 'giftiteminfo', 'previewfielduser'}: return 'button'
    if any(token in kind for token in ['listbox', 'listdlg']): return 'list'
    if kind in DIALOG_TYPES:return 'dialog'
    raise ValueError(f'Unmapped source widget type: {kind}')


def compile_catalog(root=ROOT):
    raw = json.loads((root/'godot/assets/pc_ui/catalog.json').read_text(encoding='utf-8'))
    expanded = json.loads((root/'godot/assets/full_ui/catalog.json').read_text(encoding='utf-8'))
    result = copy.deepcopy(raw)
    result['textures'].update(expanded['textures'])
    parents, unresolved, captions, unknown = [], [], Counter(), []
    missing_textures=[];invalid_regions=[];font_faces=Counter()
    for layout_id, layout in result['layouts'].items():
        records = layout['widgets']
        for i, record in enumerate(records):
            record['adapter'] = family(record['type'])
            font_faces[str(field(record,'fontfaceindex',0))]+=1
            paths=record.get('fields',{}).get('texture',[])
            for value in paths:
                path=texture_key(value)
                if path.endswith('.dtx') and path not in result['textures']:missing_textures.append({'layout':layout_id,'widget':record['name'],'source':value})
            texture=result['textures'].get(texture_key(paths[0]),{}) if paths else {}
            for key,values in record.get('fields',{}).items():
                if key=='spriterect' or key.startswith('button') and key.endswith('rect'):
                    for region in values:
                        if texture and isinstance(region,list) and len(region)==4 and region!=[0,0,0,0] and (min(region)<0 or region[2]>texture['width'] or region[3]>texture['height'] or region[2]<=region[0] or region[3]<=region[1]):
                            invalid_regions.append({'layout':layout_id,'widget':record['name'],'field':key,'region':region,'texture':paths[0],'textureSize':[texture['width'],texture['height']]})
            name = str(field(record, 'parent', ''))
            identity = field(record, 'identity', -1)
            explicit_id = field(record, 'parentidentity')
            matches = [j for j, candidate in enumerate(records) if i != j and candidate['name'].casefold() == name.casefold()
                       and (explicit_id is None or field(candidate, 'identity', -1) == explicit_id)] if name else []
            evidence = 'explicit_parent_name_and_identity' if explicit_id is not None else 'unique_parent_name'
            # Repeated red/blue HUD records explicitly carry the same team identity.
            if len(matches) > 1 and layout_id == 'interface/hudscore':
                matches = [j for j in matches if field(records[j], 'identity', -1) == identity]
                evidence = 'source_team_identity_shared_by_child_and_parent'
            # These two declared groups have disjoint source control-ID ranges.
            # Require both the ID range AND the intervening group declaration.
            if len(matches) > 1 and layout_id == 'interface/myitempropertysheet' and name == 'characterEQGroupBox':
                candidates = [j for j in matches if j < i and 1 <= identity - field(records[j], 'identity', -1) <= 4]
                preceding = [j for j in matches if j < i]
                matches = candidates if len(candidates) == 1 and candidates[0] == max(preceding, default=-1) else []
                evidence = 'matching_declared_id_range_and_contiguous_source_group'
            record['parentIndex'] = matches[0] if len(matches) == 1 else None
            if name:
                entry = {'layout': layout_id, 'widget': record['name'], 'sourceLine': record['sourceLine'],
                         'parent': name, 'identity': identity, 'parentIndex': record['parentIndex'],
                         'sourceSha256': layout['sourceSha256'], 'evidence': evidence}
                (parents if len(matches) == 1 else unresolved).append(entry)
            caption = str(field(record, 'caption', ''))
            table = None
            index = field(record, 'captionindex', -1)
            if not caption and isinstance(index, (int, float)) and index >= 0:
                index = str(int(index))
                for context in [UI_TEXT, UI_FALLBACK]:
                    if index in result['strings'].get(context, {}):
                        caption = result['strings'][context][index]
                        table = context
                        break
                if not caption: unknown.append({'layout': layout_id, 'widget': record['name'], 'index': index})
            record['resolvedCaption'] = caption
            record['captionTable'] = table
            if caption: captions[table or 'literal'] += 1
    result['schemaVersion'] = 2
    result['parentBindingScope'] = 'Source name/identity only; unresolved cross-screen parents remain unresolved.'
    report = {'layouts': len(result['layouts']), 'widgets': sum(len(x['widgets']) for x in result['layouts'].values()),
              'widgetTypes': len(result['widgetTypes']), 'families': dict(Counter(family(x) for x in result['widgetTypes'])),
              'resolvedParents': len(parents), 'parentBindings': parents, 'unresolvedParents': unresolved,
              'captionContexts': dict(captions), 'unresolvedCaptions': unknown,
              'missingTextureReferences':missing_textures,'invalidAtlasRegions':invalid_regions,'fontFaceReferences':dict(font_faces),
              'completeOriginalUiFlow': False,
              'sourceCatalogSha256': hashlib.sha256((root/'godot/assets/pc_ui/catalog.json').read_bytes()).hexdigest()}
    (root/'godot/assets/ui/catalog.json').write_text(json.dumps(result, ensure_ascii=False, separators=(',', ':'))+'\n', encoding='utf-8')
    (root/'docs/ui-source-audit.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({key: value for key, value in report.items() if key not in {'parentBindings', 'unresolvedCaptions','missingTextureReferences','invalidAtlasRegions'}}, ensure_ascii=False, indent=2))
    print('Missing texture references:',len(missing_textures),'Invalid source atlas regions:',len(invalid_regions))
    return result, report


def compile_fonts(path,root=ROOT):
    payload=path.read_bytes()
    text=payload.decode('utf-16') if payload.startswith((b'\xff\xfe',b'\xfe\xff')) else payload.decode('latin-1')
    section=re.search(r'(?ms)^\[Fonts\]\s*(.*?)(?=^\[|\Z)',text)
    if not section:raise ValueError('The original engine Fonts section is required')
    media=json.loads((root/'godot/assets/shared_media/catalog.json').read_text(encoding='utf-8'))
    entries={texture_key(name):record for name,record in media['fonts'].items()}
    fonts={}
    for number,source in re.findall(r'(?m)^FontFile(\d+)\s*=\s*"([^"]+)"',section[1]):
        record=entries.get(texture_key(source))
        if record is None:raise ValueError('Original font file is unavailable: '+source)
        fonts[number]={'source':source,'asset':record['asset']}
    audit=json.loads((root/'docs/ui-source-audit.json').read_text(encoding='utf-8'))
    result={'source':'Root/attributes/layout.txt','sha256':hashlib.sha256(payload).hexdigest(),'fonts':fonts,
            'unresolvedFaceIndices':[int(n) for n in audit['fontFaceReferences'] if n not in fonts]}
    (root/'godot/assets/ui/engine-fonts.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')


def verify_source_bytes(scan_path,root=ROOT):
    from build_transfer_ledger import canonical
    catalog=json.loads((root/'godot/assets/ui/catalog.json').read_text(encoding='utf-8'))
    records=[{'kind':'layout','source':r['source'],'expectedSha256':r['sourceSha256']} for r in catalog['layouts'].values()]
    records.extend({'kind':'texture','source':name,'expectedSha256':r.get('sourceSha256')} for name,r in catalog['textures'].items())
    fonts=json.loads((root/'godot/assets/ui/engine-fonts.json').read_text(encoding='utf-8'))
    records.extend({'kind':'font','source':r['source'],'expectedSha256':hashlib.sha256((root/'godot'/r['asset'].removeprefix('res://')).read_bytes()).hexdigest()} for r in fonts['fonts'].values())
    wanted={canonical(r['source']) for r in records};hashes={}
    with gzip.open(scan_path,'rt',encoding='utf-8') as stream:
        for line in stream:
            record=json.loads(line);key=canonical(record['source'])
            if key in wanted and record.get('contentRead') is True:hashes.setdefault(key,set()).add(record['sha256'])
    passed=Counter();issues=[]
    for record in records:
        actual=hashes.get(canonical(record['source']),set())
        if record['expectedSha256'] and actual=={record['expectedSha256']}:passed[record['kind']]+=1
        else:issues.append(dict(record,archiveSha256=sorted(actual)))
    result={'schemaVersion':1,'contentScanSha256':hashlib.sha256(scan_path.read_bytes()).hexdigest(),
            'recordsChecked':len(records),'matchingOriginalSourceBytes':dict(passed),'issues':issues,
            'originalPixelEquivalenceVerified':False,'completeOriginalUiFlow':False,
            'scope':'Original source-byte identity for layout/texture/font catalogue claims. Decoded pixels, render styles and original C++ screen composition still require independent validation.'}
    (root/'docs/ui-source-byte-validation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('Source byte matches:',dict(passed),'Unresolved or differing source claims:',len(issues))


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--font-layout',type=Path,help='Original, unmodified Root/attributes/layout.txt extracted from the supplied archive')
    parser.add_argument('--content-scan',type=Path,help='Completed original RAR member-byte scan to validate catalogue source SHA-256 claims')
    args=parser.parse_args();compile_catalog()
    if args.font_layout:compile_fonts(args.font_layout)
    if args.content_scan:verify_source_bytes(args.content_scan)
