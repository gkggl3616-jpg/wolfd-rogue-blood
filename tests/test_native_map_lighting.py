import gzip
import hashlib
import json
from pathlib import Path
import struct
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
from import_map_lighting_030 import decode_lightmap, glb_triangles


class NativeLightingTests(unittest.TestCase):
    def test_native_repeat_and_span_packets(self):
        # Three identical RGB pixels followed by two literal RGB pixels.
        raw = bytes([0x82, 7, 8, 9, 1, 10, 11, 12, 13, 14, 15])
        self.assertEqual(decode_lightmap(raw, 5, 1), bytes([7, 8, 9])*3 + bytes(range(10, 16)))
        for bad, width, height in [(raw[:-1], 5, 1), (raw, 4, 1), (raw, 6, 1), (b'\x80', 1, 1), (b'', 0, 1), (b'', 4096, 1)]:
            with self.assertRaises(ValueError):
                decode_lightmap(bad, width, height)

    def test_all_packaged_streams_keep_source_geometry_and_dependencies(self):
        index = json.loads((ROOT/'godot/assets/maps/lighting/index.json').read_bytes())
        previews = {str(int(r['number'])): r for r in json.loads((ROOT/'godot/assets/maps/previews.json').read_bytes())}
        self.assertEqual(set(index['maps']), set(previews))
        for number, record in index['maps'].items():
            path = ROOT/'godot'/record['asset'].removeprefix('res://')
            packed = path.read_bytes()
            self.assertEqual(hashlib.sha256(packed).hexdigest(), record['sha256'])
            data = gzip.decompress(packed)
            size = struct.unpack_from('<I', data)[0]
            header = json.loads(data[4:4+size])
            self.assertEqual(header['sourceGeometrySha256'], glb_triangles(ROOT/'godot'/previews[number]['previewAsset'].removeprefix('res://'))[0])
            self.assertEqual(sum(s['count'] for s in header['surfaces']), record['vertices'])
            self.assertEqual(len(header['atlases']), record['atlasPages'])
            for surface in header['surfaces']:
                self.assertGreater(surface['count'], 0)
                self.assertEqual(surface['count'] % 3, 0)
                self.assertGreaterEqual(surface['offset'], 0)
                self.assertLessEqual(surface['offset'] + surface['count']*44, len(data)-4-size)
                self.assertTrue(-1 <= surface['page'] < len(header['atlases']))
                if surface['texture']:
                    self.assertTrue((ROOT/'godot'/surface['texture'].removeprefix('res://')).is_file())
            for atlas in header['atlases']:
                image = ROOT/'godot'/atlas.removeprefix('res://')
                self.assertEqual(hashlib.sha256(image.read_bytes()).hexdigest(), index['textures'][atlas]['sha256'])


if __name__ == '__main__':
    unittest.main()
