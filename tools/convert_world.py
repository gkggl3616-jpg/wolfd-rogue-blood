"""Bounded LithTech DAT v85 render/object reader and Godot preview exporter.

Format references: lokea2/DAT2LTA85 and URAMetroid/Lith_Dat_Get.
This reader does not execute or load the legacy engine. Render triangle collision
is a preview approximation, not a reconstruction of the original physics BSP.
"""
import argparse,collections,hashlib,json,math,re,struct
from pathlib import Path
import numpy as np
from scan_xfs import unpack_index,recover_entry
from convert_character import texture_png

ROOT=Path(__file__).resolve().parents[1]
SCALE=.016

class Reader:
    def __init__(self,data,pos=0):self.data=data;self.pos=pos
    def take(self,size):
        if size<0 or self.pos+size>len(self.data):raise ValueError('Truncated world at '+str(self.pos))
        result=self.data[self.pos:self.pos+size];self.pos+=size;return result
    def unpack(self,fmt):return struct.unpack('<'+fmt,self.take(struct.calcsize('<'+fmt)))
    def count(self,maximum=1000000):
        value=self.unpack('I')[0]
        if value>maximum:raise ValueError('World count exceeds bound at '+str(self.pos-4))
        return value
    def string(self):
        size=self.unpack('H')[0]
        if size>4096:raise ValueError('Invalid world string')
        return self.take(size).decode('cp1254').rstrip('\0')

def read_objects(data):
    version,offset,end=struct.unpack_from('<3I',data)
    if version!=85 or not 60<=offset<=end<=len(data):raise ValueError('Unsupported world object section')
    r=Reader(data,offset);rows=[]
    for _ in range(r.count(100000)):
        start=r.pos;size=r.unpack('H')[0];kind=r.string();props={}
        for _ in range(r.count(4096)):
            name=r.string();typ,flags,length=r.unpack('BIH');raw=r.take(length)
            value=None
            if typ==0:
                s=Reader(raw);value=s.string()
                if s.pos!=len(raw):raise ValueError('String property has trailing bytes')
            elif typ in (1,2) and len(raw)==12:value=list(struct.unpack('<3f',raw))
            elif typ in (3,6) and len(raw)==4:value=struct.unpack('<f',raw)[0]
            elif typ==5 and len(raw)==1:value=bool(raw[0])
            elif typ==7 and len(raw) in (12,16):value=list(struct.unpack('<'+'f'*(len(raw)//4),raw))
            if value is not None:props[name]=value
        if r.pos>end:raise ValueError('Objects overlap next section')
        rows.append(dict(type=kind,properties=props,sourceOffset=start,declaredBytes=size))
    return rows

def read_render(data,stride,keep_aux=False):
    if len(data)<60 or struct.unpack_from('<I',data)[0]!=85:raise ValueError('Expected DAT v85')
    offset=struct.unpack_from('<I',data,24)[0]
    if not 60<=offset<len(data):raise ValueError('Invalid render offset')
    r=Reader(data,offset);blocks=[];repaired_uv=0;repaired_normals=0
    def node(model=''):
        nonlocal repaired_uv,repaired_normals
        center=r.unpack('6f')
        if not all(math.isfinite(x) and abs(x)<1e8 for x in center):raise ValueError('Invalid world bounds')
        sections=[]
        for _ in range(r.count(65536)):
            texture=r.string();texture1=r.string();shader=r.unpack('B')[0];triangles=r.count();effect=r.string();w,h,size=r.unpack('3I');lightmap=r.take(size)
            section=dict(texture=texture,texture1=texture1,shader=shader,triangles=triangles,effect=effect)
            if keep_aux:section.update(lightmap=lightmap,lightWidth=w,lightHeight=h)
            sections.append(section)
        count=r.count(2000000);raw=r.take(count*stride)
        vertices=np.ndarray((count,11),dtype='<f4',buffer=raw,strides=(stride,4)).copy()
        if count and (not np.isfinite(vertices[:,:3]).all() or np.abs(vertices[:,:3]).max()>1e8):
            bad=np.argwhere(~np.isfinite(vertices[:,:7]))[:4].tolist()
            raise ValueError('Invalid world vertex at '+str(r.pos-count*stride)+' nonfinite='+str(bad)+' maxPosition='+str(np.abs(vertices[:,:3]).max()))
        bad_uv=~np.isfinite(vertices[:,3:7])
        if bad_uv.any():
            repaired_uv+=int(bad_uv.any(axis=1).sum());vertices[:,3:7][bad_uv]=0
        colors=np.ndarray((count,4),dtype='u1',buffer=raw,offset=28,strides=(stride,1)).copy() if count else np.zeros((0,4),dtype='u1')
        triangles=r.count(4000000);faces=np.frombuffer(r.take(triangles*16),dtype='<u4').reshape((-1,4))[:,:3].copy()
        if sum(s['triangles'] for s in sections)!=triangles or (faces.size and faces.max()>=count):raise ValueError('World section/index mismatch')
        bad_normals=~np.isfinite(vertices[:,8:11]).all(axis=1) | (np.linalg.norm(vertices[:,8:11],axis=1)<1e-8)
        if bad_normals.any():
            generated=np.zeros((count,3),dtype=np.float32);points=vertices[faces,:3]
            face_normals=np.cross(points[:,1]-points[:,0],points[:,2]-points[:,0])
            for corner in range(3):np.add.at(generated,faces[:,corner],face_normals)
            generated/=np.maximum(np.linalg.norm(generated,axis=1,keepdims=True),1e-8)
            generated[np.linalg.norm(generated,axis=1)<1e-8]=[0,1,0]
            vertices[bad_normals,8:11]=generated[bad_normals];repaired_normals+=int(bad_normals.sum())
        # Sky portals, occluders, light groups, spatial children.
        for _ in range(r.count(100000)):r.take(r.unpack('B')[0]*12+16)
        for _ in range(r.count(100000)):r.take(r.unpack('B')[0]*12+20)
        for _ in range(r.count(10000)):
            r.string();r.take(12);r.take(r.count(128*1024*1024))
            for _ in range(r.count(100000)):
                for _ in range(r.count(100000)):
                    r.take(16);r.take(r.count(128*1024*1024))
        r.take(9)
        blocks.append(dict(model=model,sections=sections,vertices=vertices,faces=faces,colors=colors))
    main_count=r.count(100000)
    for _ in range(main_count):node()
    models=r.count(100000)
    for _ in range(models):
        name=r.string()
        for _ in range(r.count(100000)):node(name)
        r.take(4)
    # Validate final light group volume payload and full consumption.
    for _ in range(r.count(100000)):
        r.string();r.take(24);dims=r.unpack('3I');r.take(math.prod(dims))
    if r.pos!=len(data):raise ValueError('Unparsed world render bytes: '+str(len(data)-r.pos))
    return blocks,dict(stride=stride,renderNodes=main_count,worldModels=models,renderEnd=r.pos,invalidUvVerticesReplaced=repaired_uv,invalidNormalsRebuilt=repaired_normals)

def parse_world(data,keep_aux=False):
    errors=[]
    for stride in (44,68):
        try:blocks,info=read_render(data,stride,keep_aux);return blocks,read_objects(data),info
        except (ValueError,struct.error,UnicodeError) as exc:errors.append(str(stride)+': '+str(exc))
    raise ValueError('; '.join(errors))

def write_glb(blocks,objects,lookup,archive,path,texture_dir):
    buffer=bytearray();doc=dict(asset=dict(version='2.0',generator='Wolf Rogue DAT v85 preview converter'),scene=0,scenes=[dict(nodes=[])],nodes=[],meshes=[],bufferViews=[],accessors=[],materials=[],images=[],textures=[],samplers=[dict(magFilter=9729,minFilter=9987,wrapS=10497,wrapT=10497)])
    missing=set();textures={};unsupported=set();skipped_models=set();sprite_frames=[];tri_count=0
    def view(raw,target=None):
        while len(buffer)%4:buffer.append(0)
        result=dict(buffer=0,byteOffset=len(buffer),byteLength=len(raw));buffer.extend(raw)
        if target:result['target']=target
        doc['bufferViews'].append(result);return len(doc['bufferViews'])-1
    def accessor(data,kind,dtype='<f4',bounds=False):
        array=np.asarray(data,dtype=dtype);component=5125 if dtype=='<u4' else 5126
        entry=dict(bufferView=view(array.tobytes()),componentType=component,count=len(array),type=kind)
        if bounds:entry.update(min=array.min(axis=0).tolist(),max=array.max(axis=0).tolist())
        doc['accessors'].append(entry);return len(doc['accessors'])-1
    def material(name):
        key=name.replace('\\','/').casefold()
        if key in textures:return textures[key]
        source=lookup.get('root/'+key);mat=dict(name=name,doubleSided=True,pbrMetallicRoughness=dict(metallicFactor=0,roughnessFactor=1))
        if source:
            digest=hashlib.sha256(key.encode()).hexdigest()[:20];png=texture_dir/(digest+'.png')
            try:
                if key.endswith('.spr'):
                    sprite=Reader(recover_entry(archive,source));frames=sprite.count(4096);sprite.take(16);names=[sprite.string().replace('\\','/').casefold() for _ in range(frames)]
                    if not names or sprite.pos!=len(sprite.data):raise ValueError('Invalid sprite texture list')
                    source=lookup['root/'+names[0]];sprite_frames.append(dict(sprite=key,frames=names,previewFrame=0))
                dtx=recover_entry(archive,source)
                if not png.exists():png.write_bytes(texture_png(dtx))
                doc['images'].append(dict(uri='../textures/'+png.name));doc['textures'].append(dict(source=len(doc['images'])-1,sampler=0));mat['pbrMetallicRoughness']['baseColorTexture']=dict(index=len(doc['textures'])-1)
                # World textures only use alpha testing when AlphaRef requests it.
                command=dtx[36:164].split(b'\0',1)[0].decode('ascii',errors='replace')
                alpha=re.search(r'\bAlphaRef\s+(\d+)\b',command,re.I)
                mat['alphaMode']='OPAQUE'
                if alpha and int(alpha[1])>0:mat.update(alphaMode='MASK',alphaCutoff=min(255,int(alpha[1]))/255)
                if key.endswith('.spr'):mat.update(alphaMode='BLEND')
            except (ValueError,OSError,KeyError) as exc:missing.add(key+': '+str(exc));mat['pbrMetallicRoughness']['baseColorFactor']=[1,.15,.4,1]
        else:
            missing.add(key);mat['pbrMetallicRoughness']['baseColorFactor']=[1,.15,.4,1]
        doc['materials'].append(mat);textures[key]=len(doc['materials'])-1;return textures[key]
    # World models need object transforms; preserve and quarantine unmatched models.
    transforms={str(o['properties'].get('Name','')).casefold():o['properties'] for o in objects}
    for b in blocks:
        if b['model']:
            skipped_models.add(b['model']);continue
        cursor=0;primitives=[];v=b['vertices']
        for section in b['sections']:
            faces=b['faces'][cursor:cursor+section['triangles']];cursor+=section['triangles']
            if not faces.size or not section['texture'] or section['texture'].casefold().startswith('lightanim') or section['shader'] in (0,2,5,6,7,10):continue
            key=section['texture'].replace('\\','/').casefold()
            if '/sky/' in key and 'root/'+key not in lookup:
                missing.add(key);continue
            if section['texture1'] or section['effect']:unsupported.add(section['texture']+' (dual texture/effect)')
            unique,inv=np.unique(faces.reshape(-1),return_inverse=True);verts=v[unique]
            pos=verts[:,:3].copy()*SCALE;pos[:,2]*=-1
            normals=verts[:,8:11].copy();normals[:,2]*=-1
            indices=inv.reshape((-1,3)).copy()
            # Orient glTF triangles to their source vertex normals after reflection.
            p=pos[indices];dot=np.einsum('ij,ij->i',np.cross(p[:,1]-p[:,0],p[:,2]-p[:,0]),normals[indices].mean(axis=1));indices[dot<0]=indices[dot<0][:,[0,2,1]]
            attrs=dict(POSITION=accessor(pos,'VEC3',bounds=True),NORMAL=accessor(normals,'VEC3'),TEXCOORD_0=accessor(verts[:,3:5],'VEC2'))
            primitives.append(dict(attributes=attrs,indices=accessor(indices.reshape(-1),'SCALAR','<u4'),material=material(section['texture']),mode=4));tri_count+=len(indices)
        if primitives:
            doc['meshes'].append(dict(primitives=primitives));doc['nodes'].append(dict(name='WorldBlock'+str(len(doc['nodes'])),mesh=len(doc['meshes'])-1));doc['scenes'][0]['nodes'].append(len(doc['nodes'])-1)
    if not doc['meshes']:raise ValueError('No supported map geometry')
    doc['buffers']=[dict(byteLength=len(buffer))];text=json.dumps(doc,separators=(',',':')).encode();text+=b' '*((-len(text))%4);buffer+=b'\0'*((-len(buffer))%4)
    path.write_bytes(struct.pack('<III',0x46546c67,2,28+len(text)+len(buffer))+struct.pack('<II',len(text),0x4e4f534a)+text+struct.pack('<II',len(buffer),0x004e4942)+buffer)
    spawns=[dict(type=o['type'],properties=o['properties']) for o in objects if re.search('start|spawn|bomb|flag|team|capture',o['type'],re.I)]
    return dict(triangles=tri_count,materials=len(textures),missingTextures=sorted(missing),spriteFirstFrames=sprite_frames,unsupportedMaterialEffects=sorted(unsupported),pendingWorldModels=sorted(skipped_models),anchors=spawns,sha256=hashlib.sha256(path.read_bytes()).hexdigest())

def main():
    parser=argparse.ArgumentParser();parser.add_argument('folder',type=Path);parser.add_argument('--numbers',type=int,nargs='*');args=parser.parse_args()
    archive=args.folder/'wolf.xfs';lookup={e['path'].replace('\\','/').casefold():e for e in unpack_index(archive)};catalog=json.loads((ROOT/'godot/assets/maps/catalog.json').read_text(encoding='utf-8'))
    base=ROOT/'godot/assets/maps';geometry=base/'geometry';texture_dir=base/'textures';geometry.mkdir(exist_ok=True);texture_dir.mkdir(exist_ok=True)
    existing=ROOT/'docs/map-conversion.json'
    report=json.loads(existing.read_text(encoding='utf-8')) if args.numbers and existing.exists() else []
    report=[r for r in report if r['number'] not in (args.numbers or [])]
    for entry in catalog['maps']:
        if args.numbers and entry['number'] not in args.numbers:continue
        try:
            key='root/worlds/retailmultiplayer/'+entry['path'].lower();raw=recover_entry(archive,lookup[key]);blocks,objects,info=parse_world(raw)
            name=str(entry['number'])+'.glb';result=write_glb(blocks,objects,lookup,archive,geometry/name,texture_dir)
            result.update(number=entry['number'],source=key,sourceSha256=hashlib.sha256(raw).hexdigest(),parse=info,objects=len(objects),previewAsset='res://assets/maps/geometry/'+name,fullPort=False)
            (base/(str(entry['number'])+'-objects.json')).write_text(json.dumps(objects,ensure_ascii=False,indent=2,allow_nan=False),encoding='utf-8')
            print(entry['number'],entry['path'],result['triangles'],'triangles',len(result['missingTextures']),'missing textures',flush=True)
        except (ValueError,KeyError,struct.error) as exc:
            result=dict(number=entry['number'],error=str(exc),fullPort=False);print(entry['number'],'FAILED',str(exc),flush=True)
        report.append(result)
    report.sort(key=lambda row:row['number'])
    (ROOT/'docs/map-conversion.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')

if __name__=='__main__':main()
