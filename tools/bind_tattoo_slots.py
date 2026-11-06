"""Bind only explicitly named PC arm tattoos to the matching source UV meshes."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
from import_game_rules import read_item_text

ROOT = Path(__file__).resolve().parents[1]

def bind(source):
    raw=source.read_bytes()
    expected='04a124ed80f3045a5f1a0a593171909d1e703c50536b212be1f9724c12e36554'
    if hashlib.sha256(raw).hexdigest()!=expected:
        raise ValueError('Expected the verified PC archive exitemtext.dat, not another client revision')
    items=read_item_text(raw);lookup={row['id']:row for row in items}
    characters=json.loads((ROOT/'godot/assets/library/characters.json').read_text())['characters']
    models=[]
    for entry in characters:
        if not entry.get('available'):continue
        model=ROOT/'godot'/entry['wolf']['asset'].removeprefix('res://')
        with model.open('rb') as stream:
            header=stream.read(20);size=struct.unpack_from('<I',header,12)[0];document=json.loads(stream.read(size))
        names=[mesh.get('name','') for mesh in document['meshes']]
        if not {'tattoo_body','tattoo_arm_l','tattoo_arm_r'}.issubset({name.lower() for name in names}):
            raise ValueError('Source UV surface names changed: '+entry['id'])
        models.append({'character':entry['id'],'asset':entry['wolf']['asset'],'sourceSha256':entry['wolf']['sourceSha256'],
                       'meshes':[name for name in names if name.lower().startswith('tattoo')]})
    path=ROOT/'godot/assets/library/visuals.json';catalog=json.loads(path.read_text());bound=[]
    for entry in catalog['tattoos']:
        match=re.search(r'\((Sol|Sağ)\)',entry['name'])
        if not match:continue
        original=lookup.get(entry['sourceId'],{})
        if original.get('name')!=entry['name']:raise ValueError('Source item id/name mismatch')
        role='left' if match[1]=='Sol' else 'right'
        if entry['role'] not in ['unknown',role]:raise ValueError('Conflicting prior UV assignment')
        entry['role']=role
        entry['roleEvidence']={'basis':'explicit_pc_item_slot_label_and_matching_source_mesh','textSourceOffset':original['sourceOffset'],
                               'sourceId':entry['sourceId'],'mesh':'Tattoo_Arm_L' if role=='left' else 'Tattoo_Arm_R'}
        bound.append({'id':entry['id'],'sourceId':entry['sourceId'],'name':entry['name'],'role':role,
                      'texture':entry['texture'],'textSourceOffset':original['sourceOffset']})
    path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
    proof={'source':'wolfteam kurtları/Root/wt_attributes/exitemtext.dat','sourceSha256':expected,'sourceRecords':len(items),
           'binding':'Exact source id + UTF-16 name explicitly declares (Sol)/(Sağ); source wolf meshes preserve Tattoo_Arm_L/R UV surfaces.',
           'bound':bound,'models':models,'pcStatBonusesImplemented':False,'unknownRolesRemainUnsupported':True}
    (ROOT/'docs/tattoo-slot-source.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n')
    print('TATTOO_SOURCE_SLOTS',len(bound),'items;',len(models),'source UV models')

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('source',type=Path);args=parser.parse_args();bind(args.source)
