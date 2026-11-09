"""Bounded metadata reader for PC LTB mesh format 9, model versions 23–25.

Reads hierarchy, child-model references and every animation track extent.
Mesh payloads are skipped using their declared byte length, not converted.
Schema reference: Five-Damned-Dollarz/io_scene_lithtech, reader_ltb_pc.py.
No third-party code is imported or executed.
"""
import hashlib
import json
import math
import struct

class Reader:
    def __init__(self,data): self.data=data; self.pos=0
    def read(self,size):
        if size<0 or self.pos+size>len(self.data): raise ValueError('Truncated LTB data')
        result=self.data[self.pos:self.pos+size]; self.pos+=size; return result
    def skip(self,size): self.read(size)
    def values(self,fmt): return struct.unpack('<'+fmt,self.read(struct.calcsize('<'+fmt)))
    def integer(self): return self.values('I')[0]
    def count(self,maximum=1000000):
        n=self.integer()
        if n>maximum: raise ValueError('LTB count exceeds limit')
        return n
    def string(self):
        length=self.values('H')[0]
        if length>4096: raise ValueError('LTB string too long')
        return self.read(length).decode('ascii')

def digest(value):
    return hashlib.sha256(json.dumps(value,separators=(',',':'),ensure_ascii=True).encode()).hexdigest()

def inspect_ltb(data):
    r=Reader(data)
    kind,format_version=r.values('HH')
    if (kind,format_version)!=(1,9): raise ValueError(f'Unsupported LTB type/format {kind}/{format_version}')
    r.skip(16)
    header=r.values('16I')
    version,keyframes,anims,nodes,pieces,children,faces,vertices,weights,lods,sockets,weightsets,strings,stringbytes,vertexanimbytes,animbytes=header
    if version not in (23,24,25): raise ValueError(f'Unsupported LTB model version {version}')
    if nodes>2048 or pieces>4096 or anims>10000: raise ValueError('LTB header exceeds limits')
    command=r.string(); radius=r.values('f')[0]
    obbs=r.count(2048); r.skip(obbs*(68 if version>23 else 64))
    piece_count=r.count(4096)
    if piece_count!=pieces: raise ValueError('LTB piece count mismatch')
    mesh_summary=[]
    for _ in range(piece_count):
        name=r.string(); count=r.count(32); r.skip(count*4+8)
        for lod in range(count):
            r.skip(25); mesh_type=r.integer(); size=r.count(len(data))
            if mesh_type==7:
                if size!=0: raise ValueError('Unexpected null mesh payload')
            elif mesh_type in (4,5,6):
                if size<16: raise ValueError('Invalid mesh payload size')
                start=r.pos
                verts,tris,maxface,maxvert=r.values('4I')
                if maxface>4 or maxvert>4: raise ValueError('Unsupported mesh bone palette')
                r.skip(size-16)
                mesh_summary.append(dict(piece=name,lod=lod,vertices=verts,triangles=tris,type=mesh_type))
            else: raise ValueError(f'Unsupported mesh type {mesh_type}')
            used=r.values('B')[0]
            indices=r.read(used)
            if any(n>=nodes for n in indices): raise ValueError('Mesh references invalid bone')
    bones=[]; matrices=[]; stack=[]
    for index in range(nodes):
        while stack and stack[-1][1]==0: stack.pop()
        parent=stack[-1][0] if stack else None
        if index and parent is None: raise ValueError('LTB hierarchy has multiple roots')
        if stack: stack[-1][1]-=1
        name=r.string(); bone_index,flags=r.values('HB'); matrix=r.values('16f'); child_count=r.count(nodes)
        if bone_index!=index or not all(math.isfinite(v) for v in matrix): raise ValueError('Invalid bone index or transform')
        bones.append(dict(name=name,parent=parent,index=bone_index))
        matrices.append(matrix)
        if child_count:stack.append([index,child_count])
    if any(remaining for _,remaining in stack): raise ValueError('LTB incomplete hierarchy')
    weight_count=r.count(4096)
    weight_sets={}
    for _ in range(weight_count):
        name=r.string(); count=r.count(nodes); values=r.values(f"{count}f")
        if not all(math.isfinite(v) for v in values):raise ValueError("Invalid source animation weight set")
        weight_sets[name]=list(values)
    child_count=r.count(4096)
    if child_count<1: raise ValueError('LTB missing self model')
    child_models=[r.string() for _ in range(child_count-1)]
    animation_count=r.count(10000)
    animations=[]
    for _ in range(animation_count):
        extents=r.values('3f'); name=r.string(); compression=r.integer(); interpolation=r.integer(); frames=r.count(1000000)
        if compression not in (0,1,2,3) or not frames: raise ValueError('Invalid animation compression or frame count')
        times=[];events=[]
        for _ in range(frames):
            time=r.integer();event=r.string();times.append(time)
            if event:events.append(dict(timeMs=time,key=event))
        if times!=sorted(times): raise ValueError('Animation keyframe times are not ordered')
        start=r.pos
        for _ in range(nodes):
            if compression==0:
                vertex_animation=r.values('B')[0]
                if vertex_animation:
                    for _ in range(frames): count=r.count(10000000);r.skip(count*12)
                else:r.skip(frames*28)
            else:
                positions=r.count(frames);r.skip(positions*(6 if compression==2 else 12))
                rotations=r.count(frames);r.skip(rotations*(16 if compression==1 else 8))
        animations.append(dict(name=name,frames=frames,durationMs=times[-1],compression=compression,keyEvents=events,trackSha256=hashlib.sha256(data[start:r.pos]).hexdigest()))
    socket_count=r.count(4096);socket_defs=[]
    for _ in range(socket_count):
        bone=r.integer();name=r.string();rotation=r.values('4f');position=r.values('3f');scale=r.values('3f')
        if bone>=nodes:raise ValueError('Socket references invalid bone')
        socket_defs.append(dict(name=name,bone=bone,boneName=bones[bone]['name'],rotation=rotation,position=position,scale=scale))
        if bone>=nodes:raise ValueError('Socket references invalid bone')
    bindings=0
    for _ in range(child_count):
        count=r.count(100000)
        for _ in range(count):r.string();r.skip(24);bindings+=1
    if r.pos!=len(data):raise ValueError(f'Unconsumed LTB data: {len(data)-r.pos} bytes')
    return dict(weightSets=weight_sets,version=version,nodeCount=nodes,bones=bones,skeletonSha256=digest(bones),bindPoseSha256=digest(matrices),childModels=child_models,animations=animations,mesh=mesh_summary,command=command,headerAnimationCount=anims,animationCount=animation_count,sockets=socket_count,socketDefinitions=socket_defs,bindingCount=bindings,bytesParsed=r.pos)
