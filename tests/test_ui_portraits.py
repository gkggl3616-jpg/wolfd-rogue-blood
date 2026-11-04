"""Character card bindings must not silently display a different character or blank render."""
import json
from pathlib import Path
import sys
import unittest
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
from build_character_portraits import build


class PortraitBindingTests(unittest.TestCase):
    def test_committed_bindings_cover_the_actual_available_roster(self):
        stored = json.loads((ROOT/'godot/assets/ui/character-portraits.json').read_text())
        self.assertEqual(stored, build())
        characters = json.loads((ROOT/'godot/assets/library/characters.json').read_text())['characters']
        expected = {row['id']: row for row in characters if row.get('available')}
        self.assertEqual(set(stored['portraits']), set(expected))
        for ident, row in stored['portraits'].items():
            self.assertEqual(row['modelSha256'], expected[ident]['human']['sha256'])
            path = ROOT/'godot'/row['asset'].removeprefix('res://')
            with Image.open(path) as picture:
                self.assertIsNotNone(picture.convert('RGBA').getchannel('A').getbbox(), ident)
                if row['kind'] == 'source_icon':
                    self.assertGreaterEqual(picture.width, 210, ident)
                    self.assertGreaterEqual(picture.height, 75, ident)


if __name__ == '__main__': unittest.main()
