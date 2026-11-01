"""Decode the shipped item descriptions; keep source rules separate from tuning."""
import argparse,hashlib,json,re,struct
from pathlib import Path
from scan_xfs import unpack_index,recover_entry
from convert_character import texture_png

ROOT=Path(__file__).resolve().parents[1]

def read_item_text(data):
    rows=[];pos=0
    while pos<len(data):
        start=pos
        if pos+2>len(data):raise ValueError('Truncated item id')
        ident=struct.unpack_from('<H',data,pos)[0];pos+=2;strings=[]
        for _ in range(3):
            if pos+2>len(data):raise ValueError('Truncated item text length')
            size=struct.unpack_from('<H',data,pos)[0];pos+=2
            if size>16000 or pos+size*2>len(data):raise ValueError('Truncated item text')
            strings.append(data[pos:pos+size*2].decode('utf-16le'));pos+=size*2
        rows.append(dict(id=ident,sourceOffset=start,name=strings[0],description=strings[1],hint=strings[2]))
    return rows

def main():
    parser=argparse.ArgumentParser();parser.add_argument('folder',type=Path);args=parser.parse_args()
    archive=args.folder/'wolf.xfs';lookup={e['path'].replace('\\','/').lower():e for e in unpack_index(archive)}
    name='Root/wt_attributes/exitemtext.dat';raw=recover_entry(archive,lookup[name.lower()]);items=read_item_text(raw)
    matches=[r for r in items if r['id']==19601]
    if len(matches)!=1:raise ValueError('Ambiguous wolf ability item')
    item=matches[0]
    if 'W tuşuna iki kez basın' not in item['description'] or 'Güç slotunda' not in item['description']:raise ValueError('Source equipment rule changed')
    icon='Root/wt_interface/item/exitem/large/wolfdash.dtx'
    out=ROOT/'godot/assets/items';out.mkdir(parents=True,exist_ok=True)
    (out/'wolf-dash.png').write_bytes(texture_png(recover_entry(archive,lookup[icon.lower()])))
    result=dict(schemaVersion=1,source=dict(path=name,sha256=hashlib.sha256(raw).hexdigest(),recordsDecoded=len(items)),items=[dict(**item,slot='power',icon='res://assets/items/wolf-dash.png',sourceIcon=icon,implementedActions=['double_forward_wolf_run','running_body_attack'],pendingActions=['airborne_strong_attack','wall_hold'])],mobileAdaptation=dict(doubleTapSeconds=.30,normalSprintMultiplier=1.3,wolfRunMultiplier=1.65,sourceNumericTuningVerified=False,note='Activation and equipment requirements come from item 19601. Tap timing, speed multipliers and attack balance are new port tuning, not decoded original values.'))
    for path in [out/'rules.json',ROOT/'docs/movement-source-rules.json']:
        path.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(dict(item=item['id'],records=len(items),sourceOffset=item['sourceOffset'])))

if __name__=='__main__':main()
