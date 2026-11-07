"""Extract the verified AK-47 Flash/breach sockets without changing the model."""
import argparse
import hashlib
import json
from pathlib import Path

from ltb_metadata import inspect_ltb
from pc_source_cache import PcSourceCache

ROOT = Path(__file__).resolve().parents[1]


def run(cache):
    weapon = json.loads((ROOT/'godot/assets/weapons/ak47/weapon.json').read_text())
    source = PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz', cache)
    raw = source.get(weapon['source'])
    if hashlib.sha256(raw).hexdigest() != weapon['sourceSha256']:
        raise ValueError('Source weapon hash mismatch')
    sockets = {row['name']: row for row in inspect_ltb(raw)['socketDefinitions']}
    if not {'Flash', 'breach'}.issubset(sockets):
        raise ValueError('Original muzzle sockets missing')
    record = dict(sourceSha256=weapon['sourceSha256'], group='AK-47_PV_Muzz',
                  socket=sockets['Flash'], sockets=sockets, particleScaleAdapter=1.0)
    result = dict(schemaVersion=1, bindings={weapon['source']: record},
                  scope='Verified AK-47 original Flash/breach socket positions and source FX group; particle size uses an explicit mobile viewmodel adapter. Other weapon models remain unmapped.')
    (ROOT/'godot/assets/weapons/muzzle-bindings.json').write_text(json.dumps(result, indent=2)+'\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('cache', type=Path)
    run(parser.parse_args().cache)
