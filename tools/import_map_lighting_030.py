"""Read bounded native RGB RLE lightmaps and match both native render passes.

The lightmap pass has its own vertices/UV0, distinct from the texture pass.
Match exact source triangle positions; never guess UV2 from texture vertices.
Geometry is kept byte-for-byte equivalent to the existing converter's triangles.
"""
import argparse,collections,gzip,hashlib,io,json,math,struct
from pathlib import Path
import numpy as np
from PIL import Image
from convert_world import parse_world,SCALE
from pc_source_cache import PcSourceCache
ROOT=Path(__file__).resolve().parents[1]
def decode_lightmap(data,width,height):
    if not 0<width<=2048 or not 0<height<=2048:raise ValueError('Invalid native lightmap dimensions')
    expected=width*height*3;out=bytearray();offset=0
    while offset<len(data):
        tag=data[offset];offset+=1;count=(tag&127)+1;size=3 if tag&128 else count*3
        if offset+size>len(data) or len(out)+count*3>expected:raise ValueError('Truncated/overflowing native lightmap run')
        piece=data[offset:offset+size];offset+=size;out.extend(piece*count if tag&128 else piece)
    if len(out)!=expected:raise ValueError('Incomplete native lightmap pixels')
    return bytes(out)
def glb_triangles(path):
    data=path.read_bytes();length=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+length]);start=28+length
    def array(index):
        a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']];dtype='<u4' if a['componentType']==5125 else '<f4';width={'VEC3':3,'SCALAR':1}[a['type']]
        return np.frombuffer(data,dtype,offset=start+v.get('byteOffset',0)+a.get('byteOffset',0),count=a['count']*width).reshape(-1,width)
    result=[]
    for mesh in doc['meshes']:
        for p in mesh['primitives']:
            pos=array(p['attributes']['POSITION']);indices=array(p['indices']).reshape(-1,3);result.append(pos[indices].astype('<f4').tobytes())
    return hashlib.sha256(b''.join(result)).hexdigest(),doc['materials']
def run(cache,numbers=None):
    source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',cache);out=ROOT/'godot/assets/maps/lighting';out.mkdir(exist_ok=True)
    converted=json.loads((ROOT/'docs/map-conversion.json').read_bytes());offline=json.loads((ROOT/'godot/assets/maps/offline.json').read_bytes());records={};textures={}
    old=out/'index.json'
    if old.exists():
        prior=json.loads(old.read_bytes());records=prior['maps'];textures=prior['textures']
    for entry in offline:
        n=int(entry['number'])
        if numbers and n not in numbers:continue
        row=next(r for r in converted if int(r['number'])==n);raw=source.get(row['source']);assert hashlib.sha256(raw).hexdigest()==row['sourceSha256']
        blocks,objects,info=parse_world(raw,True);pages=[];shelves=[];placements={};decoded=0;pixel_bytes=0
        lightmaps=[]
        for bi,b in enumerate(blocks):
            if b['model']:continue
            for si,s in enumerate(b['sections']):
                if s['lightmap']:
                    rgb=decode_lightmap(s['lightmap'],s['lightWidth'],s['lightHeight']);decoded+=1;pixel_bytes+=len(rgb);lightmaps.append((bi,si,s,rgb))
        # One-pixel edge copies prevent linear filtering from reading another tile.
        for bi,si,s,rgb in sorted(lightmaps,key=lambda x:-x[2]['lightHeight']):
            w=s['lightWidth'];h=s['lightHeight'];page=None
            for pi,state in enumerate(shelves):
                x,y,high=state
                if x+w+2>2048:x=0;y+=high;high=0
                if y+h+2<=2048:page=pi;break
            if page is None:page=len(pages);pages.append(Image.new('RGB',(2048,2048),(255,255,255)));shelves.append([0,0,0]);x=y=high=0
            im=Image.frombytes('RGB',(w,h),rgb);p=pages[page];p.paste(im,(x+1,y+1));p.paste(im.crop((0,0,w,1)),(x+1,y));p.paste(im.crop((0,h-1,w,h)),(x+1,y+h+1));p.paste(im.crop((0,0,1,h)),(x,y+1));p.paste(im.crop((w-1,0,w,h)),(x+w+1,y+1))
            placements[(bi,si)]=(page,x+1,y+1,w,h);shelves[page]=[x+w+2,y,max(high,h+2)]
        atlas=[]
        for i,p in enumerate(pages):
            path=out/f'{n}-{i}.png';p.save(path,optimize=True);record={'asset':'res://'+str(path.relative_to(ROOT/'godot')),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()};atlas.append(record['asset']);textures[record['asset']]=record
        blob=bytearray();surfaces=[];native_geometry=[];matched=missing=ambiguous=0
        original,materials=glb_triangles(ROOT/'godot'/row['previewAsset'].removeprefix('res://'));material_info={m['name'].replace('\\','/').casefold():m for m in materials}
        def key(points):return tuple(sorted(p.tobytes() for p in points.astype('<f4')))
        for bi,b in enumerate(blocks):
            if b['model']:continue
            cursor=0;mapping={}
            for si,s in enumerate(b['sections']):
                faces=b['faces'][cursor:cursor+s['triangles']];cursor+=s['triangles']
                if not s['lightmap']:continue
                for f in faces:
                    points=b['vertices'][f,:3];k=key(points);value=(si,{p.tobytes():b['vertices'][int(j),3:5] for p,j in zip(points,f)})
                    if k in mapping and (mapping[k] is None or mapping[k][0]!=si):mapping[k]=None
                    else:mapping[k]=value
            cursor=0
            for si,s in enumerate(b['sections']):
                faces=b['faces'][cursor:cursor+s['triangles']];cursor+=s['triangles'];material=material_info.get(s['texture'].replace('\\','/').casefold())
                if not len(faces) or not material or s['shader'] in [0,2,5,6,7,10]:continue
                v=b['vertices'];points=v[faces,:3].copy()*SCALE;points[:,:,2]*=-1;normals=v[faces,8:11].copy();normals[:,:,2]*=-1
                flip=np.einsum('ij,ij->i',np.cross(points[:,1]-points[:,0],points[:,2]-points[:,0]),normals.mean(1))<0
                ordered=faces.copy();ordered[flip]=ordered[flip][:,[0,2,1]];points=v[ordered,:3].copy()*SCALE;points[:,:,2]*=-1;native_geometry.append(points.astype('<f4').tobytes())
                groups=collections.defaultdict(list)
                for f in ordered:
                    coords=v[f,:3];binding=mapping.get(key(coords));page=-1;uv=np.zeros((3,2),dtype=np.float32);color=b['colors'][f][:,[2,1,0,3]].copy();color[:,3]=255
                    if s['shader'] in [4,9] and binding is not None:
                        lm,by_position=binding;page,x,y,w,h=placements[(bi,lm)];uv=np.array([by_position[p.tobytes()] for p in coords]);uv=(uv*np.array([w,h])+np.array([x,y]))/2048;matched+=1;color[:]=255
                    elif s['shader'] in [4,9]:missing+=1
                    positions=coords.copy()*SCALE;positions[:,2]*=-1;normal=v[f,8:11].copy();normal[:,2]*=-1
                    groups[page].append((positions,normal,v[f,3:5],uv,color))
                texture_key=s['texture'].replace('\\','/').casefold();texture=ROOT/'godot/assets/maps/textures'/(hashlib.sha256(texture_key.encode()).hexdigest()[:20]+'.png')
                for page,triangles in groups.items():
                    count=len(triangles)*3;offset=len(blob)
                    # float32 position/normal/UV0/atlasUV followed by raw RGBA8.
                    for field in range(4):blob.extend(np.concatenate([t[field] for t in triangles]).astype('<f4').tobytes())
                    blob.extend(np.concatenate([t[4] for t in triangles]).astype('u1').tobytes())
                    surfaces.append({'count':count,'offset':offset,'page':page,'texture':'res://'+str(texture.relative_to(ROOT/'godot')) if texture.exists() else '', 'cutoff':material.get('alphaCutoff',0) if material.get('alphaMode')=='MASK' else 0,'blend':material.get('alphaMode')=='BLEND','shader':s['shader']})
        actual=hashlib.sha256(b''.join(native_geometry)).hexdigest();assert actual==original,('Source render geometry drift',n,actual,original)
        header=json.dumps({'surfaces':surfaces,'atlases':atlas,'sourceGeometrySha256':actual},separators=(',',':')).encode();path=out/f'{n}.bin.gz';path.write_bytes(gzip.compress(struct.pack('<I',len(header))+header+blob,mtime=0))
        records[str(n)]={'asset':'res://'+str(path.relative_to(ROOT/'godot')),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'source':row['source'],'sourceSha256':row['sourceSha256'],'existingGeometrySha256':row['sha256'],'trianglesSha256':actual,'decodedLightmaps':decoded,'decodedPixelBytes':pixel_bytes,'matchedLightmapTriangles':matched,'unmatchedLightmapTriangles':missing,'atlasPages':len(atlas),'surfaces':len(surfaces),'vertices':sum(s['count'] for s in surfaces)}
        print('NATIVE_MAP_LIGHTING',n,decoded,'lightmaps',matched,'matched',missing,'unmatched',len(atlas),'pages',flush=True)
        (out/'index.json').write_text(json.dumps({'maps':records,'textures':textures,'codec':'native RGB24 RLE, bounded run/span count','geometryChanged':False,'nativeRendererRecreated':False},indent=2)+'\n')
    (ROOT/'docs/map-lighting-source-030.json').write_text(json.dumps({'maps':records,'nativeLightmapCodec':'runtime/shared/src/lightmap_compress.cpp','engineReference':'https://github.com/jsj2008/lithtech','lightmapUvSource':'Lightmap pass UV0, exact source triangle position matching; texture pass UV1 is not assumed to be lightmap UV','geometryChanged':False,'nativeRendererRecreated':False},indent=2)+'\n')
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('cache',type=Path);p.add_argument('--numbers',nargs='*',type=int);a=p.parse_args();run(a.cache,a.numbers)
