import json,struct,sys,unittest,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from import_game_rules import read_item_text
from convert_world import parse_world

class PortTests(unittest.TestCase):
    def test_source_item_text_is_length_bounded(self):
        values=['Özel Kurt Yeteneği','Güç slotunda kullanılır.','Envanter']
        raw=struct.pack('<H',19601)+b''.join(struct.pack('<H',len(s))+s.encode('utf-16le') for s in values)
        self.assertEqual(read_item_text(raw)[0]['name'],values[0])
        with self.assertRaises(ValueError):read_item_text(raw[:-1])

    def test_equipment_trigger_has_source_evidence_and_marks_port_tuning(self):
        rules=json.loads((ROOT/'godot/assets/items/rules.json').read_text(encoding='utf-8'))
        item=rules['items'][0]
        self.assertEqual(item['id'],19601)
        self.assertEqual(item['slot'],'power')
        self.assertIn('W tuşuna iki kez basın',item['description'])
        self.assertFalse(rules['mobileAdaptation']['sourceNumericTuningVerified'])

    def test_world_truncation_and_unknown_version_are_rejected(self):
        for data in [b'',bytes(60),struct.pack('<I',84)+bytes(100)]:
            with self.assertRaises(ValueError):parse_world(data)

    def test_preview_assets_match_their_verified_source_manifest(self):
        rows=json.loads((ROOT/'godot/assets/maps/previews.json').read_text(encoding='utf-8'))
        self.assertEqual(len(rows),19)
        self.assertTrue(all(r['previewValidated'] and r['startPoints'] and not r['fullPort'] for r in rows))
        for row in rows:
            asset=ROOT/'godot'/row['previewAsset'].removeprefix('res://')
            self.assertEqual(hashlib.sha256(asset.read_bytes()).hexdigest(),row['sha256'])
            self.assertEqual(row['collision'],'render_triangle_approximation')

    def test_viewmodel_has_required_clips_and_exact_import_hash(self):
        row=json.loads((ROOT/'godot/assets/weapons/ak47/weapon.json').read_text(encoding='utf-8'))
        self.assertTrue({'idle','walk','fire','reload'}.issubset(row['animationClips']))
        self.assertEqual(row['shotsPerClip'],30)
        self.assertEqual(hashlib.sha256((ROOT/'godot/assets/weapons/ak47/viewmodel.glb').read_bytes()).hexdigest(),row['sha256'])
        self.assertFalse(row['fullWeaponSystem'])

if __name__=='__main__':unittest.main()
