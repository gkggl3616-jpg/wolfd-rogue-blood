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
    visual_minimum={'update-019-visual-validation.json':12,'update-018-visual-validation.json':14,'mobile-visual-validation.json':44,'pc-reference-visual-validation.json':16,'equipment-visual-validation.json':17,'human-visual-validation.json':3,'update-015-visual-validation.json':10,'update-016-visual-validation.json':10,'update-017-visual-validation.json':18}
    for filename in ['mobile-validation.json',*visual_minimum]:
        path = root/'docs'/filename
        report = json.loads(path.read_text()) if path.is_file() else {}
        if report.get('runtimeCodeSha256') != fingerprint:
            blockers.append('Validation does not match current runtime: '+filename)
        if filename == 'mobile-validation.json' and report.get('passed') is not True:
            blockers.append('Mobile regressions did not pass')
        if filename in visual_minimum and (report.get('failures') != 0 or len(report.get('captures', [])) < visual_minimum[filename]):
            blockers.append('Current offline UI/gameplay captures are missing')
        if filename in visual_minimum:
            for capture in report.get('captures', []):
                image = root/capture.get('path', '__missing_capture__')
                if not image.is_file() or hashlib.sha256(image.read_bytes()).hexdigest() != capture.get('sha256'):
                    blockers.append('Visual evidence missing or changed: '+capture.get('name', '?'))
    update=json.loads((root/'docs/mobile-019-validation.json').read_text()) if (root/'docs/mobile-019-validation.json').is_file() else {}
    if not update.get('passed') or update.get('checks',0)<30:blockers.append('Current model, gift, header, claw, repeated howl and audio regressions are incomplete')
    catalogue = root/'godot/assets/maps/offline.json'
    entries = json.loads(catalogue.read_text()) if catalogue.is_file() else []
    if len(entries) != 34 or len({int(row['number']) for row in entries}) != 34:
        blockers.append('All 34 independently validated offline maps are required')
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
        blockers.append('Radar must cover exactly the 34 selected geometries')
    navigation={int(row['number']):row for row in entries}
    for row in radar:
        image=root/'godot'/row['asset'].removeprefix('res://')
        if not image.is_file() or hashlib.sha256(image.read_bytes()).hexdigest()!=row['sha256']:
            blockers.append('Radar image changed: '+str(row['number']))
        if row['navigationSha256']!=navigation.get(int(row['number']),{}).get('sha256'):
            blockers.append('Radar uses different navigation: '+str(row['number']))
    path = root/'docs/offline-match-validation.json'
    matches = json.loads(path.read_text()) if path.is_file() else {}
    if matches.get('passed') is not True or len(matches.get('maps', [])) != 34:
        blockers.append('Offline physics/navigation/match regression did not pass all 34 maps')
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
    if {int(row['number']) for row in photos['maps']} != set(previews):blockers.append('All 34 original PC map photographs are required')
    if photos['sourceAttributeSha256']!=json.loads((root/'godot/assets/maps/catalog.json').read_text())['sourceTables']['attributes']['sha256']:blockers.append('Map photo association uses a different PC attribute table')
    for photo in photos['maps']:verify_asset(photo,'map photo '+str(photo['number']))
    expansion=json.loads((root/'docs/pc-reference-expansion-validation.json').read_text())
    if expansion.get('passed') is not True or expansion.get('checks',0)<101:blockers.append('PC reference, reward, PIN, tutorial and hunt regression is incomplete')
    human=json.loads((root/'docs/human-reference-validation.json').read_text())
    if human.get('passed') is not True or human.get('checks',0)<12:blockers.append('Human inventory and kill-feed checks incomplete')
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
    if not {'19001','19002','19501','19502','13006','19602',*[str(x) for x in range(16011,16021)],'16800'}.issubset({str(row.get('id')) for row in powers.get('items',[])}):blockers.append('Verified source power item identities missing')
    for item in powers.get('items',[]):
        if not (root/'godot'/item.get('icon','__missing_icon__').removeprefix('res://')).is_file():blockers.append('Power item icon missing: '+str(item.get('id')))
        if item.get('trail'):verify_asset(item['trail'],'source claw trail '+item['id'])
    for filename,minimum in [('presentation-018-validation.json',297),('shop-controls-017-validation.json',61),('clientfx-gameplay-017-validation.json',817),('mobile-016-validation.json',31),('mobile-015-validation.json',0),('bot-traversal-validation-015.json',100)]:
        path=root/'docs'/filename
        proof=json.loads(path.read_text()) if path.is_file() else {}
        if filename=='mobile-015-validation.json':
            # Localized families remove redundant placeholder triplets. Require
            # 46 fixed checks plus every actual family/variant row.
            groups={}
            tattoos=json.loads((root/'godot/assets/library/visuals.json').read_bytes())['tattoos']
            visible=[row for row in tattoos if row.get('canonicalId',row['id'])==row['id']]
            for tattoo in visible:
                roles=groups.setdefault(tattoo['setKey'],{});roles[tattoo['role']]=roles.get(tattoo['role'],0)+1
            rows=sum(max(roles.values()) for roles in groups.values());minimum=46+rows
            if proof.get('tattooItemsChecked')!=len(tattoos) or proof.get('tattooRowsChecked')!=rows or proof.get('visibleTattooItemsChecked')!=len(visible):blockers.append('Tattoo grid verification does not cover every item and family row')
        if proof.get('passed') is not True or proof.get('checks',0)<minimum:blockers.append('Incomplete update verification: '+filename)
        if filename.startswith('bot-traversal') and proof.get('traversalsSha256')!=hashlib.sha256((root/'godot/assets/maps/traversals.json').read_bytes()).hexdigest():blockers.append('Traversal physics evidence differs from packaged routes')
    admission=json.loads((root/'docs/character-admission-015.json').read_text())
    accepted={r['id']:r for r in admission.get('models',[]) if r.get('passed')}
    if not admission.get('passed') or len(accepted)!=134:blockers.append('All 134 additional source pairs need engine and render acceptance')
    characters=json.loads((root/'godot/assets/library/characters.json').read_text())['characters']
    for character in characters:
        if not character.get('available'):continue
        for form in ['human','wolf']:verify_asset(character[form],character['id']+'/'+form)
        if character.get('pairEvidence'):
            proof=accepted.get(character['id'],{})
            for form in proof.get('forms',[]):
                if character[form['form']]['sha256']!=form['assetSha256']:blockers.append('Character capture uses a different source import: '+character['id'])
                capture=root/form['path']
                if not capture.is_file() or hashlib.sha256(capture.read_bytes()).hexdigest()!=form['captureSha256']:blockers.append('Character capture missing or changed: '+character['id'])
    import gzip
    roar_path=root/'godot/assets/abilities/source-roars.json'
    roar=json.loads(roar_path.read_text())
    if roar.get('failures') or len(roar.get('characters',{}))!=52 or len(roar.get('groups',{}))!=7:
        blockers.append('Source Howling groups and character bindings incomplete')
    if hashlib.sha256(gzip.decompress((root/'docs/pc-clientfx.fxf.gz').read_bytes())).hexdigest()!=roar.get('sourceSha256'):
        blockers.append('Source ClientFX digest mismatch')
    if not set(roar.get('characters',{})).issubset({row['id'] for row in characters if row.get('available')}):
        blockers.append('Roar refers to an unavailable source character')
    for key,texture in roar.get('textures',{}).items():verify_asset(texture,'roar texture '+key)
    for key,group in roar.get('groups',{}).items():
        for node in group.get('nodes',[]):
            if node.get('asset'):verify_asset(node,'roar mesh '+key)
            for frame in node.get('frames',[]):
                if not (root/'godot'/frame.removeprefix('res://')).is_file():blockers.append('Roar sprite frame missing: '+frame)
    fx=json.loads((root/'godot/assets/clientfx/catalog.json').read_bytes())
    if fx.get('sourceGroupCount')!=628 or len(fx.get('projectiles',{}))!=4 or len(fx.get('models',{}))<95:
        blockers.append('Complete source ClientFX/native effect catalogue missing')
    for texture in fx.get('textures',{}).values():verify_asset(texture,'ClientFX texture '+texture['source'])
    for model in fx.get('models',{}).values():verify_asset(model,'ClientFX model '+model['source'])
    for char in fx.get('characters',{}).values():
        for form in char.values():
            for name in form.get('effects',{}).values():
                if name not in fx.get('groups',{}) or not fx['groups'][name].get('available'):blockers.append('Bound character FX incomplete: '+name)
    if hashlib.sha256(gzip.decompress((root/'docs/pc_sources_017/fx.txt.gz').read_bytes())).hexdigest()!=fx.get('nativeButesSha256'):
        blockers.append('Native effect source differs from packaged aliases')
    events=json.loads((root/'godot/assets/gameplay/animation-events.json').read_bytes())
    if events!=json.loads(gzip.decompress((root/'docs/animation-events-source-017.json.gz').read_bytes())) or events.get('failures'):
        blockers.append('Animation event/socket extraction evidence differs from runtime')
    facts=json.loads((root/'godot/assets/gameplay/source.json').read_bytes())
    if facts.get('voiceRows')!=791 or facts.get('missingVoices'):blockers.append('Source voice event mapping incomplete')
    for name,row in facts['sources'].items():
        source=root/'docs/pc_sources_017'/(name+'.dat.gz')
        if hashlib.sha256(gzip.decompress(source.read_bytes())).hexdigest()!=row['sha256']:blockers.append('Gameplay source changed: '+name)
    shop=json.loads((root/'godot/assets/items/shop.json').read_bytes())
    if shop.get('currencyPolicy',{}).get('unlimited')!=['cash','kp']:blockers.append('Requested unlimited Nakit/KP policy is missing')
    shop_source=gzip.decompress((root/'docs/pc_sources_017/shopdata.dat.gz').read_bytes())
    shop_proof=json.loads(gzip.decompress((root/'docs/shop-source-017.json.gz').read_bytes()))
    if shop.get('recordCount')!=4934 or shop.get('recordBytes')!=359 or shop['sourceSha256']!=hashlib.sha256(shop_source).hexdigest() or shop_proof['sourceSha256']!=shop['sourceSha256']:
        blockers.append('Original shop price table provenance mismatch')
    import struct
    for item in shop['items'].values():
        for offer in item['offers']:
            start=offer['sourceOffset']
            if struct.unpack_from('<I',shop_source,start+4)[0]!=item['sourceId'] or struct.unpack_from('<i',shop_source,start+shop['currencyOffsets'][offer['currency']]+offer['sourceOptionIndex']*4)[0]!=offer['price']:
                blockers.append('Shop price differs from literal original table: '+item['id'])
    sets=json.loads((root/'godot/assets/items/sets.json').read_bytes())
    raw_sets=gzip.decompress((root/'docs/pc_sources_018/setitemdata.dat.gz').read_bytes())
    if len(sets['items'])!=206 or sets['sourceSha256']!=hashlib.sha256(raw_sets).hexdigest():blockers.append('Source set catalogue provenance mismatch')
    for package in sets['items']:
        start=package['sourceOffset'];source_id=struct.unpack_from('<I',raw_sets,start)[0]
        members=[struct.unpack_from('<II',raw_sets,start+4+i*8) for i in range(17)]
        members=[pair for pair in members if pair[0]]
        if source_id!=package['sourceId'] or members!=[(r['sourceItemId'],r['sourceTerm']) for r in package['members']]:blockers.append('Incomplete or changed package members: '+package['id'])
        for offer in package['offers']:
            pos=offer['sourceOffset']
            if struct.unpack_from('<I',shop_source,pos+4)[0]!=source_id or struct.unpack_from('<i',shop_source,pos+shop['currencyOffsets'][offer['currency']]+offer['sourceOptionIndex']*4)[0]!=offer['price']:blockers.append('Source package price mismatch: '+package['id'])
    portraits=json.loads((root/'godot/assets/ui/character-portraits.json').read_bytes())['portraits']
    texture_catalog=json.loads((root/'godot/assets/ui/catalog.json').read_bytes())['textures']
    for ident,portrait in portraits.items():
        if portrait['kind']=='source_icon':
            original=texture_catalog.get(portrait['sourceTexture'],{})
            if original.get('asset')!=portrait['asset'] or original.get('sourceSha256')!=portrait['sourceSha256']:blockers.append('Character card source mismatch: '+ident)
    menu=json.loads((root/'docs/menu-animation-source-018.json').read_bytes())
    if hashlib.sha256((root/'godot/assets/presentation/menu-clips.json').read_bytes()).hexdigest()!=menu['assetSha256']:blockers.append('Menu animation extraction differs from verified source')
    performance=gzip.decompress((root/'docs/pc_sources_018/character&tattoo.dat.gz').read_bytes())
    stat_proof=json.loads(gzip.decompress((root/'docs/item-stat-fields-018.json.gz').read_bytes()))
    if hashlib.sha256(performance).hexdigest()!=stat_proof['sourcePerformanceSha256']:blockers.append('Item performance source provenance changed')
    presentation=json.loads((root/'godot/assets/presentation/catalog.json').read_bytes())
    for ident,forms in presentation['characterStats'].items():
        for form,stats in forms.items():
            for pos in stats['sourceOffsets']:
                if struct.unpack_from('<H',performance,pos)[0]!=shop['items'][ident]['sourceId'] or performance[pos+16]!=100 or performance[pos+4]!=(0 if form=='human' else 1) or list(performance[pos+9:pos+16])!=stats['values'] or performance[pos+5]!=stats['gpPercent'] or performance[pos+7]!=stats['goldPercent']:blockers.append('Character stat source mismatch: '+ident+'/'+form)
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
