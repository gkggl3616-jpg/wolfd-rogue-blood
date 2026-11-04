"""Bind character cards to source icons by exact normalized model/name identity.

Run this first, then render only unresolved icons with Godot 4.7.2:
  godot --path godot --script ../tools/render_character_portraits.gd
The fallback previews are derivatives of the actual model, never other characters.
"""
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def normalized(value):
    return re.sub('[^a-z0-9]', '', value.lower())


def build():
    catalog = json.loads((ROOT/'godot/assets/ui/catalog.json').read_text())
    characters = json.loads((ROOT/'godot/assets/library/characters.json').read_text())['characters']
    icons = {}
    for key, texture in catalog['textures'].items():
        if key.startswith('wt_interface/item/character/') and '/large/' not in key:
            name = Path(key).stem.removesuffix('_n')
            icons.setdefault(normalized(name), []).append((key, texture))
    rows = {}
    for character in characters:
        if not character.get('available'):
            continue
        model = Path(character['human']['source'].replace('\\', '/')).stem.lower().removeprefix('wt_').removesuffix('_ch')
        matches = icons.get(normalized(character['name']), icons.get(normalized(model), []))
        native = matches[0] if len(matches) == 1 else None
        rows[character['id']] = {
            'asset': native[1]['asset'] if native else f"res://assets/ui/character_portraits/{character['id']}.png",
            'kind': 'source_icon' if native else 'rendered_model_preview',
            'model': character['human']['asset'], 'modelSha256': character['human']['sha256'],
        }
        if native:
            rows[character['id']].update(sourceTexture=native[0], sourceSha256=native[1]['sourceSha256'])
    return {'portraits': rows, 'note': 'Exact normalized model/name matches use original 2D icons; remaining previews are rendered from the actual imported human model. No inferred rarity, ownership or stats.'}


if __name__ == '__main__':
    data = build()
    (ROOT/'godot/assets/ui/character-portraits.json').write_text(json.dumps(data, indent=2)+'\n')
    print({kind: sum(row['kind'] == kind for row in data['portraits'].values()) for kind in ['source_icon', 'rendered_model_preview']})
