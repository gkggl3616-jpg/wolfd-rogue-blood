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
    decoded={}
    scan=ROOT/'docs/pc-content-scan.jsonl.gz'
    if scan.exists():
        with gzip.open(scan,'rt',encoding='utf-8') as stream:
            for line in stream:
                row=json.loads(line)
                decoded[(row['source'],row['archiveOffset'])]={key:row[key] for key in ['bytes','sha256','contentRead','byteIdenticalTo','archiveServiceMetadata'] if key in row}
    claims = defaultdict(list)
    output_hashes = {}
    for catalog in (ROOT / 'godot/assets').rglob('*.json'):
        data = json.loads(catalog.read_text(encoding='utf-8'))
        # The media catalogue also preserves conflicting historical container
        # variants in sources/conflictingSourcePaths. Runtime lookup uses only
        # the selected sounds/fonts maps, so do not mislabel history as a live
        # claim that the older container bytes equal the supplied RAR.
        if catalog==ROOT/'godot/assets/shared_media/catalog.json':data={key:data.get(key,{}) for key in ['sounds','fonts']}
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
        verified=decoded.get((entry['name'],entry['offset']),{})
        source_hash=verified.get('sha256') if verified.get('contentRead') is True and verified.get('bytes')==entry['size'] else None
        outputs=[dict(row,sourceHashMatchesClaim=source_hash==row['claimedSourceSha256'] if source_hash and row['claimedSourceSha256'] else None) for row in claims.get(canonical(entry['name']),[])]
        service=verified.get('archiveServiceMetadata') is True
        rows.append({'source': entry['name'], 'archiveBytes': entry['size'], 'packedBytes': entry['packed'],
                     'sourceSha256': source_hash, 'sourceSha256Status': 'decoded_member_bytes_hashed' if source_hash else 'not_read',
                     'byteIdenticalTo':verified.get('byteIdenticalTo'),
                     'cataloguedOutputs': outputs,
                     'dependencies': 'not_fully_verified',
                     'stages': {'found': True, 'dependenciesResolved': False, 'converted': False,
                                'usedByGame': False, 'behaviorWorks': False, 'visualInteractionVerified': False},
                     'status': 'archive_service_metadata' if service else 'excluded_windows_binary' if excluded else 'directory_metadata' if directory else 'pending_source_verified_transfer',
                     'reason': 'Windows executable/debug/shortcut data is not Android game content' if excluded else
                               'A matching catalogue path does not establish byte identity, complete behavior or visual equivalence'})
    result = {'schemaVersion': 2, 'archive': archive['driveFileId'], 'archiveBytes': archive['archiveBytes'],
              'scope': 'RAR header inventory with available decoded member SHA-256 evidence, including repeated trees and archive service metadata. Not a count of unique playable items.',
              'sourceFiles': rows}
    with gzip.open(ROOT / 'docs/transfer-coverage.json.gz', 'wt', encoding='utf-8') as stream:
        json.dump(result, stream, ensure_ascii=False, separators=(',', ':'))
    summary = {'schemaVersion': 2, 'archiveEntries': len(rows), 'declaredUnpackedBytesIncludingRepeatedTrees': sum(r['archiveBytes'] for r in rows),
               'topLevelTrees': dict(Counter(r['source'].split('/')[0] for r in rows)),
               'catalogueLinkedSourceEntries': sum(bool(r['cataloguedOutputs']) for r in rows),
               'fullGameReady': False, 'fileStageMeaning': 'Stages require proof for the whole file; item-specific work is in mobile validation reports.',
               'sourceSha256Entries':sum(row['sourceSha256'] is not None for row in rows),
               'sourceSha256InventoryComplete':all(row['sourceSha256'] is not None for row in rows),
               'catalogueClaimMatchingEntries':sum(any(claim['sourceHashMatchesClaim'] is True for claim in row['cataloguedOutputs']) for row in rows),
               'catalogueClaimDifferingEntries':sum(any(claim['sourceHashMatchesClaim'] is False for claim in row['cataloguedOutputs']) for row in rows),
               'originalUnpublishedWindowsChangesAvailable': False}
    (ROOT / 'docs/transfer-coverage-summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    build()
