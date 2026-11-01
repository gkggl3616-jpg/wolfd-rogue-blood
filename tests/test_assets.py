import copy
import gzip
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import zlib

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from scan_xfs import recover_entry
from ltb_metadata import inspect_ltb
from audit_characters import check_roster, identity, parse_model_definitions
from check_android_ready import check

class AssetTests(unittest.TestCase):
    def test_multi_block_xfs_and_corruption(self):
        first=b'A'*65536;last=b'last block'
        a=zlib.compress(first);b=zlib.compress(last)
        packed=len(a).to_bytes(3,'little')+b'\0\0'+a+(len(last)|0x800000).to_bytes(3,'little')+len(b).to_bytes(3,'little')+b'\0\0'+b
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'test.xfs';path.write_bytes(packed)
            entry=dict(offset=0,size=len(first)+len(last),packed=len(packed),flag=1)
            self.assertEqual(recover_entry(path,entry),first+last)
            path.write_bytes(packed[:-2])
            with self.assertRaises(ValueError):recover_entry(path,entry)
    def test_ltb_truncation_and_unsupported_format(self):
        with self.assertRaises(ValueError):inspect_ltb(b'\x01\x00')
        with self.assertRaises(ValueError):inspect_ltb(struct.pack('<HH',2,9))
    def test_comments_are_not_model_definitions(self):
        data=b'/* [Model9]\nName="Fake" */\n//[Model8]\n[Model1]\nName="Real"\nModelFile="char.ltb"\n'
        rows=parse_model_definitions(data)
        self.assertEqual([r['id'] for r in rows],['Model1'])
    def test_identity_has_no_fuzzy_matching(self):
        self.assertEqual(identity('AngelaWolf_Nano'),identity('Angela_Nano'))
        self.assertNotEqual(identity('YigitDemir'),identity('Yigit'))
    def valid_roster(self):
        asset=dict(modelSha256='a'*64,skeletonSha256='b'*64,animationSetSha256='c'*64,animationClips=['idle','run'],missingDependencies=[],skeletonCompatible=True)
        return dict(schemaVersion=1,characters=[dict(id='test',human=copy.deepcopy(asset),wolf=copy.deepcopy(asset),engineImported=True,visualValidation='passed',pairConfirmed=True)])
    def test_missing_form_or_animation_cannot_enter_roster(self):
        roster=self.valid_roster();self.assertEqual(check_roster(roster),[])
        del roster['characters'][0]['wolf'];self.assertTrue(check_roster(roster))
        roster=self.valid_roster();roster['characters'][0]['human']['animationClips']=[];self.assertTrue(check_roster(roster))
        roster=self.valid_roster();roster['characters'][0]['wolf']['skeletonCompatible']=False;self.assertTrue(check_roster(roster))
    def test_unconfirmed_or_unrendered_pairs_are_excluded(self):
        for field,value in [('engineImported',False),('visualValidation','pending'),('pairConfirmed',False)]:
            roster=self.valid_roster();roster['characters'][0][field]=value;self.assertTrue(check_roster(roster))
    def test_no_approved_roster_means_no_android_release(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);(root/'assets').mkdir()
            (root/'branding.json').write_text(json.dumps(dict(androidGameProject=None,apkProduced=False)))
            (root/'assets/roster.json').write_text(json.dumps(dict(schemaVersion=1,characters=[])))
            result=check(root);self.assertFalse(result['ready']);self.assertFalse(result['apkProduced'])
    def test_audit_only_includes_the_reviewed_pair(self):
        root=Path(__file__).resolve().parents[1]
        report=json.loads((root/'web/characters.json').read_text(encoding='utf-8'))
        self.assertEqual(report['summary']['parsedModels'],539)
        self.assertEqual({c['id'] for c in report['characters'] if c['included']},{'Model0','Model2'})
        self.assertTrue(check()['ready'])
        raw=json.loads(gzip.decompress((root/'docs/character-audit.json.gz').read_bytes()))
        self.assertEqual(len(raw['models']),539)
        self.assertEqual(sum(len(m['dependencies']) for m in raw['models']),445)

if __name__=='__main__':unittest.main()
