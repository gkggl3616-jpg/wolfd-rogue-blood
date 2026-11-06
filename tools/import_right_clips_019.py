"""Export the real UMFi2 donor tracks separately, preserving all admitted base GLBs."""
import argparse,gzip,hashlib,json,pathlib
import numpy as np
from pc_source_cache import PcSourceCache
from convert_character import load
ROOT=pathlib.Path(__file__).resolve().parents[1]
def run(cache):
    s=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',cache);events=json.loads(gzip.decompress((ROOT/'docs/animation-events-source-017.json.gz').read_bytes()));result={}
    for path,source in events['models'].items():
        if 'UMFi2' not in source['animations']:continue
        raw=s.get(path);assert hashlib.sha256(raw).hexdigest()==source['sourceSha256'];model=load(raw,{'UMFi2'});clip=model['animations']['UMFi2'];tracks=[]
        for bone,track in zip(model['info']['bones'],clip['tracks']):
            p=track['translation'].copy()
            if bone['index']==0:p[:,[0,2]]=p[0,[0,2]]
            assert np.isfinite(p).all() and np.isfinite(track['rotation']).all()
            tracks.append(dict(bone=bone['name'],positions=p.tolist(),rotations=track['rotation'].tolist()))
        result[path]=dict(sourceSha256=source['sourceSha256'],skeletonSha256=model['info']['skeletonSha256'],sourceClip='UMFi2',times=clip['times'],tracks=tracks)
    (ROOT/'godot/assets/gameplay/right-clips.json').write_text(json.dumps(dict(schemaVersion=1,donors=result),separators=(',',':'))+'\n')
    print('SOURCE_RIGHT_CLIPS',len(result),'unchanged base GLBs')
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('cache',type=pathlib.Path);run(p.parse_args().cache)
