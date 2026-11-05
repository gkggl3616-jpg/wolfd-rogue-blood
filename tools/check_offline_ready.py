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
    for filename in ['mobile-validation.json', 'mobile-visual-validation.json','pc-reference-visual-validation.json','equipment-visual-validation.json']:
        path = root/'docs'/filename
        report = json.loads(path.read_text()) if path.is_file() else {}
        if report.get('runtimeCodeSha256') != fingerprint:
            blockers.append('Validation does not match current runtime: '+filename)
        if filename == 'mobile-validation.json' and report.get('passed') is not True:
            blockers.append('Mobile regressions did not pass')
        if filename in ['mobile-visual-validation.json','pc-reference-visual-validation.json','equipment-visual-validation.json'] and (report.get('failures') != 0 or len(report.get('captures', [])) < ({'mobile-visual-validation.json':44,'pc-reference-visual-validation.json':16,'equipment-visual-validation.json':17}[filename])):
            blockers.append('Current offline UI/gameplay captures are missing')
        if filename in ['mobile-visual-validation.json','pc-reference-visual-validation.json','equipment-visual-validation.json']:
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
    radar_path=root/'godot/assets/maps/radar.json'
    radar=json.loads(radar_path.read_text()) if radar_path.is_file() else []
    if {int(row['number']) for row in radar} != set(previews):
        blockers.append('Radar must cover exactly the 19 selected geometries')
    navigation={int(row['number']):row for row in entries}
    for row in radar:
        image=root/'godot'/row['asset'].removeprefix('res://')
        if not image.is_file() or hashlib.sha256(image.read_bytes()).hexdigest()!=row['sha256']:
            blockers.append('Radar image changed: '+str(row['number']))
        if row['navigationSha256']!=navigation.get(int(row['number']),{}).get('sha256'):
            blockers.append('Radar uses different navigation: '+str(row['number']))
    path = root/'docs/offline-match-validation.json'
    matches = json.loads(path.read_text()) if path.is_file() else {}
    if matches.get('passed') is not True or len(matches.get('maps', [])) != 19:
        blockers.append('Offline physics/navigation/match regression did not pass all 19 maps')
    if catalogue.is_file() and matches.get('navigationCatalogSha256') != hashlib.sha256(catalogue.read_bytes()).hexdigest():
        blockers.append('Offline match evidence does not match current navigation')
    def verify_asset(row, label, asset_key='asset', hash_key='sha256'):
        asset = root/'godot'/row.get(asset_key, '__missing_asset__').removeprefix('res://')
        if not asset.is_file() or hashlib.sha256(asset.read_bytes()).hexdigest() != row.get(hash_key):
            blockers.append('Derived/source asset missing or changed: '+label)

    for name, required in [('control-icons', {'fire', 'wolf_fire', 'reload', 'strong', 'jump', 'crouch', 'sprint', 'roll', 'aim', 'roar', 'transform', 'knife_fire', 'grenade_fire'}),
                           ('form-icons', {'human', 'wolf'})]:
        path = root/f'godot/assets/ui/{name}.json'
        icons = json.loads(path.read_text()) if path.is_file() else {}
        if isinstance(icons, list):
            icons = {row['form']: row for row in icons}
        if not required.issubset(icons):
            blockers.append('Required action/form images missing: '+name)
        for key in required.intersection(icons):
            verify_asset(icons[key], name+'/'+key)
    for name in ['bots/catalog', 'maps/arena-navigation']:
        path = root/f'godot/assets/{name}.json'
        derived = json.loads(path.read_text()) if path.is_file() else {}
        verify_asset(derived, name)
        if name == 'bots/catalog':
            verify_asset(derived, 'bot source weapon', 'source', 'sourceSha256')
            verify_asset(derived, 'bot magazine image', 'magazineIcon', 'magazineIconSha256')
    path = root/'docs/bot-validation.json'
    bots = json.loads(path.read_text()) if path.is_file() else {}
    if bots.get('passed') is not True or bots.get('checks', 0) < 62 or bots.get('actualShotDamageByDifficulty') != [8, 8, 8]:
        blockers.append('Equal-damage difficulty, navigation and finite-ammo bot checks did not pass')
    photos=json.loads((root/'godot/assets/maps/photos.json').read_text())
    if {int(row['number']) for row in photos['maps']} != set(previews):blockers.append('All 19 original PC map photographs are required')
    if photos['sourceAttributeSha256']!=json.loads((root/'godot/assets/maps/catalog.json').read_text())['sourceTables']['attributes']['sha256']:blockers.append('Map photo association uses a different PC attribute table')
    for photo in photos['maps']:verify_asset(photo,'map photo '+str(photo['number']))
    expansion=json.loads((root/'docs/pc-reference-expansion-validation.json').read_text())
    if expansion.get('passed') is not True or expansion.get('checks',0)<101:blockers.append('PC reference, reward, PIN, tutorial and hunt regression is incomplete')
    equipment_path=root/'docs/round-equipment-gift-validation.json'
    equipment=json.loads(equipment_path.read_text()) if equipment_path.is_file() else {}
    if equipment.get('passed') is not True or equipment.get('checks',0)<191:blockers.append('Round selection, six source mutation models and gift transactions have not passed')
    mutation_path=root/'godot/assets/mutations/catalog.json'
    mutations=json.loads(mutation_path.read_text()) if mutation_path.is_file() else {}
    if {(row.get('id'),row.get('team')) for row in mutations.get('models',[])} != {(kind,team) for kind in ['power','guardian','ghost'] for team in ['red','blue']}:blockers.append('All six source wolf mutation models are required')
    for row in mutations.get('models',[]):
        verify_asset(row,'mutation '+row['id']+row['team'])
        verify_asset(row,'mutation portrait '+row['id']+row['team'],'portrait','portraitSha256')
    power_path=root/'godot/assets/items/power.json'
    powers=json.loads(power_path.read_text()) if power_path.is_file() else {}
    if {str(row.get('id')) for row in powers.get('items',[])} != {'19001','19002','19501','19502','13006','19602'}:blockers.append('Verified source power item identities missing')
    for item in powers.get('items',[]):
        if not (root/'godot'/item.get('icon','__missing_icon__').removeprefix('res://')).is_file():blockers.append('Power item icon missing: '+str(item.get('id')))
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
