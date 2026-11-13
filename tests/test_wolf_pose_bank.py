import gzip,hashlib,json,struct,unittest
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
class NativeWolfPoseBank(unittest.TestCase):
 def test_source_masks_tracks_bounds_and_native_attack_times(self):
  index=json.loads((ROOT/'godot/assets/gameplay/wolf-poses/index.json').read_bytes())['donors'];admitted=json.loads((ROOT/'godot/assets/gameplay/right-clips.json').read_bytes())['donors'];events=json.loads((ROOT/'godot/assets/gameplay/animation-events.json').read_bytes())['models'];self.assertEqual(set(index),set(admitted))
  for donor,entry in index.items():
   b=(ROOT/'godot'/entry['asset'].removeprefix('res://')).read_bytes();self.assertEqual(hashlib.sha256(b).hexdigest(),entry['sha256']);raw=gzip.decompress(b);size=struct.unpack_from('<I',raw)[0];header=json.loads(raw[4:4+size]);data=raw[4+size:];weights=header['upperWeights'];self.assertEqual(header['sourceSha256'],admitted[donor]['sourceSha256']);self.assertEqual(header['skeletonSha256'],admitted[donor]['skeletonSha256']);self.assertTrue(0<sum(weights)<len(weights));self.assertEqual(len(weights),len(header['bones']))
   for alias,clip in header['clips'].items():
    self.assertEqual(clip['times'],sorted(clip['times']));self.assertEqual(len(clip['tracks']),len(weights))
    if alias.startswith('attack'):
     self.assertAlmostEqual(clip['times'][-1]*1000,events[donor]['animations'][clip['sourceUpper']]['durationMs'],places=3)
    for i,row in enumerate(clip['tracks']):
     n=row['count'];self.assertEqual(n,len(clip['times']));po=row['positionOffset'];qo=row['rotationOffset'];self.assertTrue(0<=po and po+n*12<=len(data));self.assertTrue(0<=qo and qo+n*16<=len(data));p=np.frombuffer(data,'<f4',n*3,po).reshape(-1,3);q=np.frombuffer(data,'<f4',n*4,qo).reshape(-1,4);self.assertTrue(np.isfinite(p).all() and np.isfinite(q).all());self.assertTrue(np.allclose(np.linalg.norm(q,axis=1),1,atol=1e-6))
     if alias.startswith('attack') and weights[i]==0:self.assertTrue(np.allclose(p,p[0]) and np.allclose(q,q[0]))
