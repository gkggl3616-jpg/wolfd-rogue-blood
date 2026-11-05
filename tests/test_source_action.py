"""Source animation imports must preserve existing geometry and reject incompatible rigs."""
import json
import hashlib
from pathlib import Path
import struct
import sys
import unittest
import numpy as np
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from add_source_action import append,unpack,CLIP


def fixture():
    doc={'asset':{'version':'2.0'},'nodes':[{'name':'Root','children':[1]},{'name':'Bone'}],
         'skins':[{'joints':[1]}],'buffers':[{'byteLength':4}],'bufferViews':[{'buffer':0,'byteOffset':0,'byteLength':4}],
         'accessors':[],'animations':[{'name':'idle','samplers':[],'channels':[]}]}
    text=json.dumps(doc).encode();text+=b' '*((-len(text))%4);binary=b'MESH'
    raw=struct.pack('<III',0x46546c67,2,28+len(text)+4)+struct.pack('<II',len(text),0x4e4f534a)+text+struct.pack('<II',4,0x004e4942)+binary
    donor={'info':{'bones':[{'name':'Bone','parent':None}]},'animations':{CLIP:{'times':np.array([0,1]),'tracks':[{'translation':np.array([[0.,0.,0.],[1.,1.,1.]]),'rotation':np.array([[0.,0.,0.,1.],[0.,0.,0.,1.]])}]}}}
    return raw,donor


class SourceActionTests(unittest.TestCase):
    def test_every_available_character_has_finite_tracks_from_its_own_verified_donor(self):
        root=Path(__file__).resolve().parents[1]
        characters=json.loads((root/'godot/assets/library/characters.json').read_text())['characters']
        for character in characters:
            if not character.get('available'):continue
            form=character['wolf'];raw=(root/'godot'/form['asset'].removeprefix('res://')).read_bytes()
            self.assertEqual(hashlib.sha256(raw).hexdigest(),form['sha256'],character['id'])
            doc,binary=unpack(raw);animation=next(a for a in doc['animations'] if a['name']=='airborne_attack')
            self.assertEqual(animation['extras']['sourceSha256'],form['sourceActions']['airborne_attack']['donorSha256'])
            self.assertEqual(animation['extras']['sourceClip'],CLIP)
            for sampler in animation['samplers']:
                for key in ['input','output']:
                    accessor=doc['accessors'][sampler[key]];view=doc['bufferViews'][accessor['bufferView']]
                    start=view.get('byteOffset',0)+accessor.get('byteOffset',0)
                    values=np.frombuffer(binary,dtype='<f4',offset=start,count=accessor['count']*{'SCALAR':1,'VEC3':3,'VEC4':4}[accessor['type']])
                    self.assertTrue(np.isfinite(values).all(),character['id'])
                    if accessor['type']=='VEC4':self.assertTrue(np.allclose(np.linalg.norm(values.reshape(-1,4),axis=1),1,atol=0.001),character['id'])

    def test_append_keeps_original_mesh_bytes_and_existing_animation(self):
        raw,donor=fixture();new=append(raw,donor,'a'*64);doc,binary=unpack(new)
        self.assertEqual(binary[:4],b'MESH');self.assertEqual([a['name'] for a in doc['animations']],['idle','airborne_attack'])
        self.assertEqual(append(new,donor,'a'*64),new)
        with self.assertRaisesRegex(ValueError,'provenance'):append(new,donor,'b'*64)

    def test_incompatible_bone_name_and_nonfinite_tracks_are_rejected(self):
        raw,donor=fixture();donor['info']['bones'][0]['name']='Other'
        with self.assertRaisesRegex(ValueError,'Bone order'):append(raw,donor,'a'*64)
        donor['info']['bones'][0]['name']='Bone';donor['animations'][CLIP]['tracks'][0]['rotation'][1,0]=np.nan
        with self.assertRaisesRegex(ValueError,'Non-finite'):append(raw,donor,'a'*64)


if __name__=='__main__':unittest.main()
