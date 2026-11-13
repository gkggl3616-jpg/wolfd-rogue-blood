"""Compose native Upper/Lower wolf tracks using the source model's weight masks.

Grounded upper/lower cycles are phase aligned locally. Attack keys retain the
upper clip's native times; legs hold the selected source posture. This is not
a claim to reproduce the entire closed-source animation tracker system.
"""
import argparse,gzip,hashlib,json,struct
from pathlib import Path
import numpy as np
from convert_character import load
from pc_source_cache import PcSourceCache
ROOT=Path(__file__).resolve().parents[1]
PAIRS={'idle':('LSt','UMSt'),'run':('LRF','UMRF'),'crouch':('LC','UMC'),'crouch_run':('LCWF','UMCWF'),'run_left':('LRL','UMRL'),'run_right':('LRR','UMRR'),'run_back':('LWB','UMWB'),'run_forward_left':('LRFL','UMRF'),'run_forward_right':('LRFR','UMRF'),'run_back_left':('LWBL','UMWB'),'run_back_right':('LWBR','UMWB'),'crouch_left':('LCWL','UMCWL'),'crouch_right':('LCWR','UMCWR'),'crouch_back':('LCWB','UMCWB'),'crouch_forward_left':('LCWFL','UMCWF'),'crouch_forward_right':('LCWFR','UMCWF'),'crouch_back_left':('LCWBL','UMCWB'),'crouch_back_right':('LCWBR','UMCWB'),'jump':('LJJ','UMJJ'),'jump_air':('LJT','UMJT'),'jump_land':('LJL','UMJL')}
for side,upper in [('attack','UMFi1'),('attack_right','UMFi2')]:
 for pose,lower in [('stand','LSt'),('crouch','LC'),('air','LJT')]:PAIRS[side+'_'+pose]=(lower,upper)
def slerp(a,b,t):
 a=np.asarray(a);b=np.asarray(b);dot=float(a@b)
 if dot<0:b=-b;dot=-dot
 if dot>.9995:q=a+(b-a)*t
 else:
  angle=np.arccos(np.clip(dot,-1,1));q=(np.sin((1-t)*angle)*a+np.sin(t*angle)*b)/np.sin(angle)
 return q/np.linalg.norm(q)
def sample(track,times,t):
 k=min(len(times)-1,max(1,int(np.searchsorted(times,t)))) if len(times)>1 else 0;j=max(0,k-1);f=0 if times[k]==times[j] else np.clip((t-times[j])/(times[k]-times[j]),0,1)
 return track['translation'][j]*(1-f)+track['translation'][k]*f,slerp(track['rotation'][j],track['rotation'][k],f)
def encode_bank(data):
 header={k:v for k,v in data.items() if k!='clips'};header['clips']={};blob=bytearray()
 for alias,clip in data['clips'].items():
  meta={k:v for k,v in clip.items() if k!='tracks'};meta['tracks']=[]
  for track in clip['tracks']:
   po=len(blob);positions=np.asarray(track['positions'],dtype='<f4');rotations=np.asarray(track['rotations'],dtype='<f4');blob.extend(positions.tobytes());qo=len(blob);blob.extend(rotations.tobytes());meta['tracks'].append({'bone':track['bone'],'positionOffset':po,'rotationOffset':qo,'count':len(positions)})
  header['clips'][alias]=meta
 raw=json.dumps(header,separators=(',',':')).encode();return gzip.compress(struct.pack('<I',len(raw))+raw+blob,mtime=0)
def run(cache):
 source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',cache);admitted=json.loads((ROOT/'godot/assets/gameplay/right-clips.json').read_bytes())['donors'];out=ROOT/'godot/assets/gameplay/wolf-poses';out.mkdir(exist_ok=True);records={}
 for path,provenance in admitted.items():
  raw=source.get(path);assert hashlib.sha256(raw).hexdigest()==provenance['sourceSha256'];model=load(raw,{name for pair in PAIRS.values() for name in pair});info=model['info'];assert info['skeletonSha256']==provenance['skeletonSha256']
  weights=info['weightSets'].get('Upper',[]);assert len(weights)==len(info['bones']) and all(0<=w<=1 for w in weights) and 0<sum(weights)<len(weights)
  clips={}
  for alias,(lower,upper) in PAIRS.items():
   if lower not in model['animations'] or upper not in model['animations']:continue
   lo=model['animations'][lower];up=model['animations'][upper];action=alias.startswith('attack');base=up if action else lo;duration=max(base['times'][-1],.001);ud=max(up['times'][-1],.001);ld=max(lo['times'][-1],.001)
   times=base['times'] if action else sorted(set(lo['times']+[round(t/ud*duration,7) for t in up['times']]))
   tracks=[]
   for bone,low,high,w in zip(info['bones'],lo['tracks'],up['tracks'],weights):
    positions=[];rotations=[]
    for t in times:
     lp,lq=sample(low,lo['times'],0 if action else t);hp,hq=sample(high,up['times'],t if action else t/duration*ud);p=lp*(1-w)+hp*w;q=slerp(lq,hq,w);positions.append(p.tolist());rotations.append(q.tolist())
    if bone['index']==0:
     for p in positions:p[0]=positions[0][0];p[2]=positions[0][2]
    tracks.append({'bone':bone['name'],'positions':positions,'rotations':rotations})
   clips[alias]={'times':times,'tracks':tracks,'sourceLower':lower,'sourceUpper':upper,'nativeAttackTimesPreserved':action}
  data={'sourceSha256':provenance['sourceSha256'],'skeletonSha256':provenance['skeletonSha256'],'upperWeights':weights,'bones':info['bones'],'clips':clips};target=out/(hashlib.sha256(path.encode()).hexdigest()[:20]+'.bin.gz');target.write_bytes(encode_bank(data));records[path]={'asset':'res://'+str(target.relative_to(ROOT/'godot')),'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'sourceSha256':provenance['sourceSha256'],'skeletonSha256':provenance['skeletonSha256'],'clips':list(clips),'upperWeightSet':weights}
  (out/'index.json').write_text(json.dumps({'donors':records,'phaseAlignedGroundCycles':True,'nativeAttackTimesPreserved':True},indent=2)+'\n');print('WOLF_NATIVE_POSES',path,len(clips),flush=True)
  for origin in source.folder.glob('*.origin.json'):
   d=json.loads(origin.read_bytes())
   if d.get('sha256')==provenance['sourceSha256']:origin.with_suffix('').with_suffix('').unlink(missing_ok=True)
 (ROOT/'docs/wolf-pose-source-031.json').write_text(json.dumps({'donors':records,'sourceWeightSet':'Upper','groundClock':'Local phase alignment of original Lower and Upper tracks; full native tracker system not claimed','attackClock':'Exact upper UMFi1/UMFi2 times, source LC/LSt/LJT leg posture held; same native fire_key/spline events','fullNativeAnimationSystem':False},indent=2)+'\n')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('cache',type=Path);run(p.parse_args().cache)
