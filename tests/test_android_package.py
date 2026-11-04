from pathlib import Path
import sys
import tempfile
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from verify_android_apk import InvalidApk, inspect_zip


class AndroidArchiveTests(unittest.TestCase):
    def test_truncated_export_is_rejected_even_when_the_exporter_reported_success(self):
        with tempfile.TemporaryDirectory() as folder:
            apk = Path(folder)/'truncated.apk'
            with zipfile.ZipFile(apk, 'w') as output: output.writestr('AndroidManifest.xml', b'header')
            apk.write_bytes(apk.read_bytes()[:-25])
            with self.assertRaisesRegex(InvalidApk, 'truncated or corrupt'): inspect_zip(apk, [])

    def test_catalogue_texture_cannot_pass_with_a_dangling_android_import(self):
        with tempfile.TemporaryDirectory() as folder:
            apk = Path(folder)/'missing-texture.apk'
            with zipfile.ZipFile(apk, 'w') as output:
                for name in ['AndroidManifest.xml', 'classes.dex', 'assets/project.binary']: output.writestr(name, b'header')
                output.writestr('assets/catalog.json', '{"asset":"res://texture.png"}')
                output.writestr('assets/texture.png.import', '[remap]\npath.etc2="res://.godot/imported/missing.etc2.ctex"\n')
            with self.assertRaisesRegex(InvalidApk, 'resources missing'): inspect_zip(apk, ['catalog.json'])

    def test_archive_cannot_resolve_a_resource_by_escaping_the_project_root(self):
        with tempfile.TemporaryDirectory() as folder:
            apk = Path(folder)/'escaping-path.apk'
            with zipfile.ZipFile(apk, 'w') as output:
                for name in ['AndroidManifest.xml', 'classes.dex', 'assets/project.binary']: output.writestr(name, b'header')
                output.writestr('assets/catalog.json', '{"asset":"res://../outside.png"}')
                output.writestr('assets/../outside.png', b'not a valid in-project asset')
            with self.assertRaisesRegex(InvalidApk, 'resources missing'): inspect_zip(apk, ['catalog.json'])


if __name__ == '__main__': unittest.main()
