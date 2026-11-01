"""Convert a selected, audited LTB human/wolf pair into self-contained glTF assets.

Requires numpy and Pillow. Does not convert or run the Windows executable.
Only standard rigid/skinned PC mesh streams and bone transform clips are supported.
"""
import argparse,hashlib,io,json,math,posixpath,struct
from pathlib import Path
import numpy as np
from PIL import Image
from audit_characters import normalize,parse_model_definitions
from ltb_metadata import Reader,inspect_ltb
from scan_xfs import unpack_index,recover_entry

def load(data,selected):
    info=inspect_ltb(data);r=Reader(data);r.skip(20);header=r.values('16I');version=header[0];nodes=header[3]
    r.string();r.skip(4);r.skip(r.count(2048)*(68 if version>23 else 64));pieces=r.count(4096)
    meshes=[]
    for _ in range(pieces):
        name=r.string();lods=r.count(32);r.skip(lods*4+8)
        for lod in range(lods):
            texture_count,*textures=r.values('5I');r.skip(5);kind=r.integer();size=r.integer();end=r.pos+size
            if kind==7:pass
            elif lod or kind not in (4,5):r.skip(size)
            else:
                count,triangles,maxface,maxvert=r.values('4I')
                if kind==5:
                    reindex=r.values('B')[0];masks=r.values('4I');palette=r.values('B')[0]
                    if reindex or palette:raise ValueError('Unsupported reindexed/matrix-palette mesh')
                else:masks=r.values('4I');bone=r.integer()
                pos=np.zeros((count,3),dtype=np.float32);normal=np.zeros_like(pos);uv=np.zeros((count,2),dtype=np.float32)
                weights=np.zeros((count,4),dtype=np.float32);joints=np.zeros((count,4),dtype=np.uint16)
                for mask in masks:
                    if mask&~0x1f7:raise ValueError('Unsupported vertex stream flag')
                    for vertex in range(count):
                        if mask&1:
                            pos[vertex]=r.values('3f')
                            if kind==5:
                                blends=list(r.values(f'{maxface-1}f')) if maxface>1 else []
                                weights[vertex,:maxface]=blends+[1-sum(blends)]
                            else:joints[vertex,0]=bone;weights[vertex,0]=1
                        if mask&2:normal[vertex]=r.values('3f')
                        if mask&4:r.skip(4)
                        for flag,index in [(0x10,0),(0x20,1),(0x40,2),(0x80,3)]:
                            if mask&flag:
                                value=r.values('2f')
                                if index==0:uv[vertex]=value
                        if mask&0x100:r.skip(24)
                indices=np.frombuffer(r.read(triangles*6),dtype='<u2').copy()
                if kind==5:
                    sets=r.count(100000)
                    for _ in range(sets):
                        start,n=r.values('2H');bones=r.values('4B');r.skip(4)
                        if start+n>count:raise ValueError('Bone set exceeds vertex count')
                        for slot,b in enumerate(bones):
                            if b==255:weights[start:start+n,slot]=0
                            else:joints[start:start+n,slot]=b
                if r.pos!=end:raise ValueError('Mesh payload size mismatch')
                if indices.max(initial=0)>=count or joints.max(initial=0)>=nodes:raise ValueError('Invalid geometry index')
                sums=weights.sum(axis=1)
                if np.any(sums<=.001) or np.any(weights<-.01):raise ValueError('Invalid skin weights')
                weights=np.maximum(weights,0);weights/=weights.sum(axis=1,keepdims=True)
                if not all(np.isfinite(a).all() for a in (pos,normal,uv,weights)):raise ValueError('Non-finite mesh values')
                meshes.append(dict(name=name,material=textures[0],positions=pos,normals=normal,uvs=uv,joints=joints,weights=weights,indices=indices))
            used=r.values('B')[0];r.skip(used)
    matrices=[]
    for _ in range(nodes):r.string();r.skip(3);matrices.append(np.array(r.values('16f'),dtype=float).reshape(4,4));r.skip(4)
    for _ in range(r.count(4096)):r.string();r.skip(r.count(nodes)*4)
    childcount=r.count(4096)
    children=[r.string() for _ in range(childcount-1)]
    animations={}
    for _ in range(r.count(10000)):
        r.skip(12);name=r.string();compression=r.integer();r.skip(4);frames=r.count(1000000)
        times=[]
        for _ in range(frames):times.append(r.integer()/1000);r.string()
        tracks=[]
        for _ in range(nodes):
            if compression==0:
                if r.values('B')[0]:raise ValueError('Vertex animation is not supported by this converter')
                p=np.frombuffer(r.read(frames*12),dtype='<f4').copy().reshape(-1,3)
                q=np.frombuffer(r.read(frames*16),dtype='<f4').copy().reshape(-1,4)
            else:
                n=r.count(frames);p=np.array(r.values(f'{n*3}{"h" if compression==2 else "f"}'),dtype=float).reshape(-1,3)
                if compression==2:p/=16
                n=r.count(frames);q=np.array(r.values(f'{n*4}{"f" if compression==1 else "h"}'),dtype=float).reshape(-1,4)
                if compression!=1:q/=32767
                if len(p)==0:p=np.zeros((1,3))
                if len(q)==0:q=np.array([[0,0,0,1]])
                p=p[np.minimum(np.arange(frames),len(p)-1)];q=q[np.minimum(np.arange(frames),len(q)-1)]
            if name in selected:
                norms=np.linalg.norm(q,axis=1,keepdims=True)
                if np.any(norms<.001):raise ValueError('Zero animation quaternion')
                q=q/norms
                for i in range(1,len(q)):
                    if np.dot(q[i-1],q[i])<0:q[i]*=-1
                tracks.append(dict(translation=p,rotation=q))
        if name in selected:animations[name]=dict(times=times,tracks=tracks)
    return dict(info=info,meshes=meshes,matrices=matrices,children=children,animations=animations)

def texture_png(data):
    resource,version,width,height=struct.unpack_from('<IiHH',data)
    bpp=data[26];payload=data[164:]
    if resource!=0 or not (0<width<=4096 and 0<height<=4096):raise ValueError('Unsupported DTX header')
    if bpp in (4,5,6):
        fourcc={4:b'DXT1',5:b'DXT3',6:b'DXT5'}[bpp]
        size=max(1,(width+3)//4)*max(1,(height+3)//4)*(8 if bpp==4 else 16)
        header=[124,0x81007,height,width,size,0,1]+[0]*11+[32,4,int.from_bytes(fourcc,'little'),0,0,0,0,0]+[0x1000,0,0,0,0]
        image=Image.open(io.BytesIO(b'DDS '+struct.pack('<31I',*header)+payload[:size])).convert('RGBA')
    elif bpp==3:image=Image.frombytes('RGBA',(width,height),payload[:width*height*4],'raw','BGRA')
    else:raise ValueError(f'Unsupported DTX pixel format {bpp}')
    image.thumbnail((1024,1024));out=io.BytesIO();image.save(out,format='PNG');return out.getvalue()

def quaternion(matrix):
    m=matrix[:3,:3];trace=np.trace(m)
    if trace>0:
        s=math.sqrt(trace+1)*2;q=np.array([(m[2,1]-m[1,2])/s,(m[0,2]-m[2,0])/s,(m[1,0]-m[0,1])/s,.25*s])
    else:
        i=int(np.argmax(np.diag(m)));j=(i+1)%3;k=(i+2)%3;s=math.sqrt(1+m[i,i]-m[j,j]-m[k,k])*2
        q=np.zeros(4);q[i]=.25*s;q[j]=(m[j,i]+m[i,j])/s;q[k]=(m[k,i]+m[i,k])/s;q[3]=(m[k,j]-m[j,k])/s
    return (q/np.linalg.norm(q)).tolist()

def glb(asset,donor,skins,clips,path,root_scale=.01,freeze_root=True,alpha_mask=True):
    if asset['info']['skeletonSha256']!=donor['info']['skeletonSha256']:raise ValueError('Animation skeleton differs from mesh skeleton')
    data=bytearray();doc=dict(asset=dict(version='2.0',generator='Wolf Rogue audited LTB converter'),scene=0,scenes=[dict(nodes=[0])],nodes=[dict(name='WolfRogueCharacter',scale=[root_scale]*3,children=[1])],meshes=[],skins=[],bufferViews=[],accessors=[],materials=[],images=[],textures=[],samplers=[dict(magFilter=9729,minFilter=9987,wrapS=10497,wrapT=10497)],animations=[])
    def buffer(raw,target=None):
        while len(data)%4:data.append(0)
        view=dict(buffer=0,byteOffset=len(data),byteLength=len(raw));data.extend(raw)
        if target:view['target']=target
        doc['bufferViews'].append(view);return len(doc['bufferViews'])-1
    def accessor(array,kind,component=5126,target=None,bounds=False):
        array=np.asarray(array,dtype={5126:'<f4',5123:'<u2'}[component]);view=buffer(array.tobytes(),target)
        item=dict(bufferView=view,componentType=component,count=len(array),type=kind)
        if bounds:item.update(min=np.atleast_1d(array.min(axis=0)).tolist(),max=np.atleast_1d(array.max(axis=0)).tolist())
        doc['accessors'].append(item);return len(doc['accessors'])-1
    material_map={}
    for slot,(name,png) in skins.items():
        view=buffer(png);doc['images'].append(dict(name=name,bufferView=view,mimeType='image/png'));index=len(doc['images'])-1
        doc['textures'].append(dict(source=index,sampler=0));doc['materials'].append(dict(name=name,pbrMetallicRoughness=dict(baseColorTexture=dict(index=index),metallicFactor=0,roughnessFactor=.85),doubleSided=True,alphaMode='MASK',alphaCutoff=.25))
        if not alpha_mask:doc['materials'][-1].update(alphaMode='OPAQUE')
        material_map[slot]=len(doc['materials'])-1
    bones=asset['info']['bones'];matrices=asset['matrices']
    for bone,global_matrix in zip(bones,matrices):
        local=global_matrix if bone['parent'] is None else np.linalg.inv(matrices[bone['parent']])@global_matrix
        scale=np.linalg.norm(local[:3,:3],axis=0);rot=local.copy();rot[:3,:3]/=scale
        node=dict(name=bone['name'],translation=local[:3,3].tolist(),rotation=quaternion(rot),scale=scale.tolist())
        doc['nodes'].append(node)
        if bone['parent'] is not None:doc['nodes'][bone['parent']+1].setdefault('children',[]).append(bone['index']+1)
    inverse=np.array([np.linalg.inv(m).T.reshape(16) for m in matrices],dtype=np.float32)
    doc['skins'].append(dict(name='AuditedSkeleton',joints=list(range(1,len(bones)+1)),inverseBindMatrices=accessor(inverse,'MAT4'),skeleton=1))
    for mesh in asset['meshes']:
        if mesh['material'] not in material_map and mesh['name'].casefold().startswith('tattoo'):continue
        attrs=dict(POSITION=accessor(mesh['positions'],'VEC3',target=34962,bounds=True),NORMAL=accessor(mesh['normals'],'VEC3',target=34962),TEXCOORD_0=accessor(mesh['uvs'],'VEC2',target=34962),JOINTS_0=accessor(mesh['joints'],'VEC4',5123,34962),WEIGHTS_0=accessor(mesh['weights'],'VEC4',target=34962))
        primitive=dict(attributes=attrs,indices=accessor(mesh['indices'],'SCALAR',5123,34963),mode=4)
        if mesh['material'] not in material_map:raise ValueError('Mesh skin slot has no texture')
        primitive['material']=material_map[mesh['material']];doc['meshes'].append(dict(name=mesh['name'],primitives=[primitive]))
        doc['nodes'][0]['children'].append(len(doc['nodes']));doc['nodes'].append(dict(name=mesh['name'],mesh=len(doc['meshes'])-1,skin=0))
    for exported,source in clips.items():
        clip=donor['animations'].get(source)
        if not clip:raise ValueError(f'Required clip is absent: {source}')
        times=np.array(clip['times'],dtype=np.float32);times-=times[0]
        static_posture=len(times)==1 and exported=='crouch'
        if static_posture:times=np.array([0,.5],dtype=np.float32)
        elif len(times)<2 or times[-1]<=0:raise ValueError('Static clip cannot satisfy motion requirement')
        animation=dict(name=exported,samplers=[],channels=[]);input_index=accessor(times,'SCALAR',bounds=True)
        for bone,track in enumerate(clip['tracks']):
            for key,kind in [('translation','VEC3'),('rotation','VEC4')]:
                values=track[key].copy()
                if static_posture:values=np.repeat(values,2,axis=0)
                if freeze_root and bone==0 and key=='translation':values[:,[0,2]]=values[0,[0,2]]
                output=accessor(values,kind);animation['samplers'].append(dict(input=input_index,output=output,interpolation='LINEAR'));animation['channels'].append(dict(sampler=len(animation['samplers'])-1,target=dict(node=bone+1,path=key)))
        doc['animations'].append(animation)
    doc['buffers']=[dict(byteLength=len(data))]
    text=json.dumps(doc,separators=(',',':')).encode()
    while len(text)%4:text+=b' '
    while len(data)%4:data.append(0)
    total=12+8+len(text)+8+len(data)
    path.write_bytes(struct.pack('<III',0x46546c67,2,total)+struct.pack('<II',len(text),0x4e4f534a)+text+struct.pack('<II',len(data),0x004e4942)+data)
    included=[m for m in asset['meshes'] if m['material'] in material_map]
    return dict(file=path.name,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),modelSha256=asset['info'].get('sha256'),skeletonSha256=asset['info']['skeletonSha256'],animationClips=list(clips),sourceClips=clips,vertices=sum(len(m['positions']) for m in included),triangles=sum(len(m['indices'])//3 for m in included),omittedOptionalMeshes=[m['name'] for m in asset['meshes'] if m['material'] not in material_map])

def main():
    p=argparse.ArgumentParser();p.add_argument('folder',type=Path);p.add_argument('--output',type=Path,required=True);args=p.parse_args();args.output.mkdir(parents=True,exist_ok=True)
    archive=args.folder/'wolf.xfs';entries=unpack_index(archive);lookup={normalize(e['path']):e for e in entries}
    definitions=parse_model_definitions(recover_entry(archive,lookup['root/attributes/modelbutes.txt']))
    result={}
    for form,ident,clips in [('human','Model0',dict(idle='LSt',run='LRF',jump='LJJ',attack='URi1Fi',reload='URi1Re',crouch='LC',crouch_run='LCWF')),('wolf','Model2',dict(idle='LSt',run='LRF',jump='LJJ',attack='UMFi1',roar='T_CRY',crouch='LC',crouch_run='LCWF',wolf_run='T_WallDash',body_attack='T_Bodyatk',special_attack='T_Specialatk',wall_hold='T_WallHold_L'))]:
        definition=next(d for d in definitions if d['id']==ident);entry=lookup[normalize('Root/'+definition['model'])];raw=recover_entry(archive,entry);asset=load(raw,set());asset['info']['sha256']=hashlib.sha256(raw).hexdigest()
        if len(asset['children'])!=1:raise ValueError('Expected one explicit animation donor')
        donorpath=normalize(posixpath.join(posixpath.dirname(entry['path']),asset['children'][0].replace('\\','/')))
        donor=load(recover_entry(archive,lookup[donorpath]),set(clips.values()))
        skins={}
        required={m['material'] for m in asset['meshes'] if not m['name'].casefold().startswith('tattoo')}
        for i in sorted(required):
            name=definition['values'].get(f'Skin{i}')
            if name:skins[i]=(name,texture_png(recover_entry(archive,lookup[normalize('Root/'+name)])))
            else:raise ValueError('Required mesh texture is absent')
        result[form]=glb(asset,donor,skins,clips,args.output/(form+'.glb'));result[form].update(definition=ident,name=definition['name'],source=entry['path'],donor=donorpath,bindPoseExact=asset['info']['bindPoseSha256']==donor['info']['bindPoseSha256'])
    (args.output/'conversion.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result),flush=True)
if __name__=='__main__':main()
