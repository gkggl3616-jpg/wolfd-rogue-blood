import json
from pathlib import Path
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from check_delivery import check, project_file


class DeliveryTests(unittest.TestCase):
    def test_current_previews_cannot_be_promoted_by_a_completion_flag(self):
        result = check()
        self.assertFalse(result['fullReleaseReady'])
        self.assertTrue(any('maç' in reason for reason in result['blockers']))
        self.assertTrue(any('46 Göbekli' in reason for reason in result['blockers']))

    def test_external_scene_path_is_not_a_delivery_evidence(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'godot').mkdir()
            (root / 'outside.tscn').write_text('[gd_scene format=3]\n')
            self.assertIsNone(project_file(root, 'res://../outside.tscn'))

    def test_small_zip_with_windows_binary_is_not_an_android_full_game(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'assets').mkdir()
            (root / 'assets/delivery-status.json').write_text(json.dumps({'fullReleaseReady': True}))
            apk = root / 'fake.apk'
            with zipfile.ZipFile(apk, 'w') as archive:
                archive.writestr('assets/WolfRogue.dat.exe', b'Windows executable is not an Android port')
            result = check(root, apk)
            self.assertFalse(result['fullReleaseReady'])
            self.assertTrue(any('3 GB' in reason for reason in result['blockers']))
            self.assertTrue(any('Windows' in reason for reason in result['blockers']))


if __name__ == '__main__':
    unittest.main()
