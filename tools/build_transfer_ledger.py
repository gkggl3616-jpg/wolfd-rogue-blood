"""Record all source entries without treating catalogued or recovered assets as finished gameplay."""
from collections import Counter, defaultdict
import gzip
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def canonical(path):
    path = path.replace('\\', '/').casefold()
    if '/root/' in path: path = path.split('/root/', 1)[1]
    return path.removeprefix('root/')


def objects(value):
    if isinstance(value, dict):
        yield value
        for key, child in value.items():
            if isinstance(child, dict) and isinstance(key, str) and Path(key).suffix.casefold() in {'.dtx', '.ltb', '.wav', '.ogg', '.ttf', '.otf', '.ttc', '.spr'} and 'source' not in child:
                yield dict(child, source=key)
            yield from objects(child)
    elif isinstance(value, list):
        for child in value: yield from objects(child)


def build():
    with gzip.open(ROOT / 'docs/pc-archive-inventory.json.gz', 'rt', encoding='utf-8') as stream:
        archive = json.load(stream)
    claims = defaultdict(list)
    output_hashes = {}
    for catalog in (ROOT / 'godot/assets').rglob('*.json'):
        data = json.loads(catalog.read_text(encoding='utf-8'))
        for record in objects(data):
            source = record.get('source', record.get('sourceTexture'))
            asset = record.get('asset', record.get('previewAsset', record.get('texture')))
            if not isinstance(source, str) or not isinstance(asset, str) or not asset.startswith('res://'):
                continue
            path = ROOT / 'godot' / asset.removeprefix('res://')
            if path.is_file() and path not in output_hashes:
                output_hashes[path] = hashlib.sha256(path.read_bytes()).hexdigest()
            claims[canonical(source)].append({'catalog': str(catalog.relative_to(ROOT)), 'output': str(path.relative_to(ROOT)),
                                            'outputPresent': path.is_file(), 'outputSha256': output_hashes.get(path), 'claimedSourceSha256': record.get('sourceSha256', record.get('sourceTextureSha256')),
                                            'provenance': 'historical_catalogue_not_source_byte_verification'})
    rows = []
    for entry in archive['files']:
        suffix = Path(entry['name']).suffix.casefold()
        excluded = suffix in {'.exe', '.dll', '.pdb', '.lnk'}
        directory = entry['name'].endswith('/')
        rows.append({'source': entry['name'], 'archiveBytes': entry['size'], 'packedBytes': entry['packed'],
                     'sourceSha256': None, 'sourceSha256Status': 'not_extracted',
                     'cataloguedOutputs': claims.get(canonical(entry['name']), []),
                     'dependencies': 'not_fully_verified',
                     'stages': {'found': True, 'dependenciesResolved': False, 'converted': False,
                                'usedByGame': False, 'behaviorWorks': False, 'visualInteractionVerified': False},
                     'status': 'excluded_windows_binary' if excluded else 'directory_metadata' if directory else 'pending_source_verified_transfer',
                     'reason': 'Windows executable/debug/shortcut data is not Android game content' if excluded else
                               'A matching catalogue path does not establish byte identity, complete behavior or visual equivalence'})
    result = {'schemaVersion': 1, 'archive': archive['driveFileId'], 'archiveBytes': archive['archiveBytes'],
              'scope': 'Header inventory of supplied RAR, including repeated trees. Not a count of unique playable items.',
              'sourceFiles': rows}
    with gzip.open(ROOT / 'docs/transfer-coverage.json.gz', 'wt', encoding='utf-8') as stream:
        json.dump(result, stream, ensure_ascii=False, separators=(',', ':'))
    summary = {'schemaVersion': 1, 'archiveEntries': len(rows), 'declaredUnpackedBytesIncludingRepeatedTrees': sum(r['archiveBytes'] for r in rows),
               'topLevelTrees': dict(Counter(r['source'].split('/')[0] for r in rows)),
               'catalogueLinkedSourceEntries': sum(bool(r['cataloguedOutputs']) for r in rows),
               'fullGameReady': False, 'fileStageMeaning': 'Stages require proof for the whole file; item-specific work is in mobile validation reports.',
               'sourceSha256InventoryComplete': False, 'originalUnpublishedWindowsChangesAvailable': False}
    (ROOT / 'docs/transfer-coverage-summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    build()
