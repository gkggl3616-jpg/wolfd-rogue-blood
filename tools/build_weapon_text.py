"""Decode the PC weapon text table; bind only unique exact item-id/name pairs.

The five strings are display metadata. Magazine/weight text does not silently
replace gameplay tuning or certify damage, fire rate, recoil or purchases.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct

ROOT=Path(__file__).resolve().parents[1]


def read_weapon_text(raw):
    rows=[];pos=0
    while pos<len(raw):
        start=pos
        if pos+2>len(raw):raise ValueError('Truncated item identity')
        ident=struct.unpack_from('<H',raw,pos)[0];pos+=2;strings=[]
        for _ in range(5):
            if pos+2>len(raw):raise ValueError('Truncated string length')
            count=struct.unpack_from('<H',raw,pos)[0];pos+=2
            if count>16000 or pos+count*2>len(raw):raise ValueError('Truncated weapon text')
            strings.append(raw[pos:pos+count*2].decode('utf-16le').rstrip('\0'));pos+=count*2
        rows.append(dict(id=ident,sourceOffset=start,name=strings[0],description=strings[1],weightText=strings[2],magazineText=strings[3],modeText=strings[4]))
    return rows


def bind(raw,weapons):
    rows=read_weapon_text(raw);lookup={}
    for row in rows:lookup.setdefault((row['id'],row['name']),[]).append(row)
    bindings={}
    for item in weapons:
        matches=lookup.get((item.get('sourceId'),item.get('name')),[])
        if len(matches)==1:bindings[item['id']]=matches[0]
    return dict(source=dict(path='Root/wt_attributes/weapontext.dat',sha256=hashlib.sha256(raw).hexdigest(),records=len(rows)),items=bindings,unmatchedItems=len(weapons)-len(bindings),numericGameplayStatsVerified=False)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('source',type=Path);args=parser.parse_args()
    weapons=json.loads((ROOT/'godot/assets/library/weapons.json').read_text())['items']
    data=bind(args.source.read_bytes(),weapons)
    (ROOT/'godot/assets/ui/weapon-text.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
    print({'sourceRecords':data['source']['records'],'boundItems':len(data['items']),'unmatchedItems':data['unmatchedItems']})
