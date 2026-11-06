"""Append the actual donor's airborne attack to audited character GLBs.

Existing meshes/materials and animations remain intact. Each donor hash,
character hash and complete bone hierarchy must match before any write.
Source clip timing/poses are retained; collision movement remains port tuning.
"""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import struct
import numpy as np
from convert_character import load

ROOT = Path(__file__).resolve().parents[1]
CLIP = 'T_WallDashAtk'
EXPORT = 'airborne_attack'


def unpack(raw):
    magic,version,total=struct.unpack_from('<III',raw)
    if magic!=0x46546c67 or version!=2 or total!=len(raw):raise ValueError('Invalid GLB header')
    length,kind=struct.unpack_from('<II',raw,12)
    if kind!=0x4e4f534a:raise ValueError('Missing GLB JSON chunk')
    doc=json.loads(raw[20:20+length]);offset=20+length
    size,kind=struct.unpack_from('<II',raw,offset)
    if kind!=0x004e4942 or offset+8+size!=len(raw):raise ValueError('Invalid GLB binary chunk')
    return doc,bytearray(raw[offset+8:offset+8+size])


def append(raw, donor, donor_sha):
    doc,data=unpack(raw)
    existing=next((a for a in doc.get('animations',[]) if a.get('name')==EXPORT),None)
    if existing:
        if existing.get('extras',{}).get('sourceSha256')!=donor_sha:raise ValueError('Existing action has different provenance')
        return raw
    clip=donor['animations'].get(CLIP)
    if not clip:raise ValueError('Actual character donor lacks requested attack')
    bones=donor['info']['bones'];joints=doc['skins'][0]['joints']
    if len(joints)!=len(bones):raise ValueError('Bone count differs')
    parents={child:parent for parent,node in enumerate(doc['nodes']) for child in node.get('children',[])}
    for bone,node_index in zip(bones,joints):
        if doc['nodes'][node_index]['name']!=bone['name']:raise ValueError('Bone order/name differs')
        if bone['parent'] is not None and parents.get(node_index)!=joints[bone['parent']]:raise ValueError('Bone hierarchy differs')
    data=data[:doc['buffers'][0]['byteLength']]
    def accessor(values,kind):
        values=np.asarray(values,dtype='<f4')
        if not np.isfinite(values).all():raise ValueError('Non-finite animation track')
        while len(data)%4:data.append(0)
        view=len(doc['bufferViews']);payload=values.tobytes();doc['bufferViews'].append(dict(buffer=0,byteOffset=len(data),byteLength=len(payload)));data.extend(payload)
        record=dict(bufferView=view,componentType=5126,count=len(values),type=kind)
        if kind=='SCALAR':record.update(min=[float(values.min())],max=[float(values.max())])
        doc['accessors'].append(record);return len(doc['accessors'])-1
    times=np.array(clip['times'],dtype=np.float32);times-=times[0]
    if len(times)<2 or times[-1]<=0 or np.any(np.diff(times)<0):raise ValueError('Invalid animation time range')
    animation=dict(name=EXPORT,samplers=[],channels=[],extras=dict(sourceClip=CLIP,sourceSha256=donor_sha,rootMotion='XZ frozen; movement uses collision controller'))
    time_index=accessor(times,'SCALAR')
    for index,track in enumerate(clip['tracks']):
        for key,kind in [('translation','VEC3'),('rotation','VEC4')]:
            values=track[key].copy()
            if index==0 and key=='translation':values[:,[0,2]]=values[0,[0,2]]
            output=accessor(values,kind);animation['samplers'].append(dict(input=time_index,output=output,interpolation='LINEAR'))
            animation['channels'].append(dict(sampler=len(animation['samplers'])-1,target=dict(node=joints[index],path=key)))
    doc['animations'].append(animation);doc['buffers'][0]['byteLength']=len(data)
    text=json.dumps(doc,separators=(',',':')).encode();text+=b' '*((-len(text))%4);data+=b'\0'*((-len(data))%4)
    total=28+len(text)+len(data)
    return struct.pack('<III',0x46546c67,2,total)+struct.pack('<II',len(text),0x4e4f534a)+text+struct.pack('<II',len(data),0x004e4942)+data


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--donors',type=Path,required=True);args=parser.parse_args()
    catalog_path=ROOT/'godot/assets/library/characters.json';catalog=json.loads(catalog_path.read_text())
    audit=json.load(gzip.open(ROOT/'docs/character-audit.json.gz','rt'))
    verified={x['path'].lower().removeprefix('root/'):x for x in audit['models']}
    donors={};staged=[];evidence=[]
    for character in catalog['characters']:
        if not character.get('available'):continue
        form=character['wolf'];name=form['donor'];source=verified[name]
        if name not in donors:
            raw=(args.donors/Path(name).name).read_bytes();digest=hashlib.sha256(raw).hexdigest()
            if digest!=source['sha256']:raise ValueError('Donor content differs from PC source audit')
            donors[name]=(load(raw,{CLIP}),digest)
        donor,digest=donors[name]
        if donor['info']['skeletonSha256']!=form['skeletonSha256']:raise ValueError('Character and donor skeleton identities differ')
        path=ROOT/'godot'/form['asset'].removeprefix('res://');raw=path.read_bytes()
        if hashlib.sha256(raw).hexdigest()!=form['sha256']:raise ValueError('Character GLB changed since its recorded import')
        result=append(raw,donor,digest);staged.append((path,result))
        form['sha256']=hashlib.sha256(result).hexdigest()
        if EXPORT not in form['clips']:form['clips'].append(EXPORT)
        form.setdefault('sourceActions',{})[EXPORT]=dict(clip=CLIP,donor=name,donorSha256=digest)
        evidence.append(dict(character=character['id'],asset=form['asset'],assetSha256=form['sha256'],sourceDonor=name,sourceSha256=digest,skeletonSha256=form['skeletonSha256'],sourceClip=CLIP,durationSeconds=float(donor['animations'][CLIP]['times'][-1]-donor['animations'][CLIP]['times'][0])))
    # Validate every character first, so a mismatched late donor cannot leave a partial roster.
    for path,raw in staged:path.write_bytes(raw)
    catalog_path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
    (ROOT/'docs/airborne-attack-source.json').write_text(json.dumps(dict(sourceCondition='Item 19601: run, jump, strong attack',sourceClipMapping='T_WallDashAtk, actual donor per character',mappingScope='Source clip identity verified; action interpretation is a port mapping, not reverse-engineered PC code.',characters=evidence,sourceNumericTuningVerified=False),indent=2)+'\n')
    print(f'Added source action to {len(staged)} characters from {len(donors)} verified donors.')


if __name__=='__main__':main()
