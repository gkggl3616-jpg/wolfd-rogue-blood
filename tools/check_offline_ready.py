"""Check the explicitly scoped offline edition; never certify the full PC port."""
import argparse
import hashlib
import json
from pathlib import Path

from check_android_ready import check as asset_check
from validate_mobile import code_fingerprint

ROOT = Path(__file__).resolve().parents[1]


def check(root=ROOT):
    blockers = asset_check(root)['blockers']
    fingerprint = code_fingerprint()
    for filename in ['mobile-validation.json', 'mobile-visual-validation.json']:
        path = root/'docs'/filename
        report = json.loads(path.read_text()) if path.is_file() else {}
        if report.get('runtimeCodeSha256') != fingerprint:
            blockers.append('Validation does not match current runtime: '+filename)
        if filename == 'mobile-validation.json' and report.get('passed') is not True:
            blockers.append('Mobile regressions did not pass')
        if filename == 'mobile-visual-validation.json' and (report.get('failures') != 0 or len(report.get('captures', [])) < 40):
            blockers.append('Current offline UI/gameplay captures are missing')
        if filename == 'mobile-visual-validation.json':
            for capture in report.get('captures', []):
                image = root/capture.get('path', '__missing_capture__')
                if not image.is_file() or hashlib.sha256(image.read_bytes()).hexdigest() != capture.get('sha256'):
                    blockers.append('Visual evidence missing or changed: '+capture.get('name', '?'))
    catalogue = root/'godot/assets/maps/offline.json'
    entries = json.loads(catalogue.read_text()) if catalogue.is_file() else []
    if len(entries) != 19 or len({int(row['number']) for row in entries}) != 19:
        blockers.append('All 19 independently validated offline maps are required')
    previews = {int(row['number']): row for row in json.loads((root/'godot/assets/maps/previews.json').read_text())}
    for row in entries:
        path = root/'godot'/row['navigation'].removeprefix('res://')
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != row['sha256']:
            blockers.append('Offline navigation hash mismatch: '+str(row['number']))
        if row['geometrySha256'] != previews[int(row['number'])]['sha256']:
            blockers.append('Navigation was baked for different geometry: '+str(row['number']))
    path = root/'docs/offline-match-validation.json'
    matches = json.loads(path.read_text()) if path.is_file() else {}
    if matches.get('passed') is not True or len(matches.get('maps', [])) != 19:
        blockers.append('Offline physics/navigation/match regression did not pass all 19 maps')
    if catalogue.is_file() and matches.get('navigationCatalogSha256') != hashlib.sha256(catalogue.read_bytes()).hexdigest():
        blockers.append('Offline match evidence does not match current navigation')
    return {'offlineBuildReady':not blockers, 'runtimeCodeSha256':fingerprint, 'blockers':blockers,
            'scope':'Local bot matches, imported collection and PC-source UI; real servers excluded.',
            'fullOriginalGamePort':False, 'physicalAndroidDeviceTested':False}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    result = check()
    if args.report: args.report.write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(result, indent=2))
    raise SystemExit(0 if result['offlineBuildReady'] else 2)
