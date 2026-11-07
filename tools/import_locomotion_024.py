"""Export verified original directional, airborne and landing wolf tracks."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path

import numpy as np

from convert_character import load
from pc_source_cache import PcSourceCache

ROOT = Path(__file__).resolve().parents[1]
ALIASES = {
    'run_left': 'LRL', 'run_right': 'LRR',
    'run_forward_left': 'LRFL', 'run_forward_right': 'LRFR',
    'run_back': 'LWB', 'run_back_left': 'LWBL', 'run_back_right': 'LWBR',
    'crouch_left': 'LCWL', 'crouch_right': 'LCWR', 'crouch_back': 'LCWB',
    'crouch_forward_left': 'LCWFL', 'crouch_forward_right': 'LCWFR',
    'crouch_back_left': 'LCWBL', 'crouch_back_right': 'LCWBR',
    'jump_air': 'LJT', 'jump_land': 'LJL',
}


def run(cache):
    source = PcSourceCache(ROOT / 'docs/pc-archive-inventory.json.gz', cache)
    admitted = json.loads((ROOT / 'godot/assets/gameplay/right-clips.json').read_text())['donors']
    out = ROOT / 'godot/assets/gameplay/locomotion'
    out.mkdir(exist_ok=True)
    donors = {}
    for path, provenance in admitted.items():
        raw = source.get(path)
        assert hashlib.sha256(raw).hexdigest() == provenance['sourceSha256']
        model = load(raw, set(ALIASES.values()))
        assert model['info']['skeletonSha256'] == provenance['skeletonSha256']
        clips = {}
        for alias, name in ALIASES.items():
            if name not in model['animations']:
                continue
            clip = model['animations'][name]
            tracks = []
            for bone, track in zip(model['info']['bones'], clip['tracks']):
                positions = track['translation'].copy()
                if bone['index'] == 0:
                    positions[:, [0, 2]] = positions[0, [0, 2]]
                assert np.isfinite(positions).all() and np.isfinite(track['rotation']).all()
                tracks.append(dict(bone=bone['name'], positions=positions.tolist(), rotations=track['rotation'].tolist()))
            clips[alias] = dict(sourceClip=name, times=clip['times'], tracks=tracks)
        data = json.dumps(dict(sourceSha256=provenance['sourceSha256'], skeletonSha256=provenance['skeletonSha256'], clips=clips), separators=(',', ':')).encode()
        target = out / (hashlib.sha256(path.encode()).hexdigest()[:20] + '.json.gz')
        target.write_bytes(gzip.compress(data, mtime=0))
        donors[path] = dict(asset='res://' + str(target.relative_to(ROOT / 'godot')), sha256=hashlib.sha256(target.read_bytes()).hexdigest(), sourceSha256=provenance['sourceSha256'], skeletonSha256=provenance['skeletonSha256'], clips=list(clips))
        print('LOCOMOTION', path, len(clips), len(data), flush=True)
    (out / 'index.json').write_text(json.dumps(dict(schemaVersion=1, aliases=ALIASES, donors=donors, rootXZFrozen=True), indent=2) + '\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('cache', type=Path)
    run(parser.parse_args().cache)
