"""Check actual Android game prerequisites. Does not create a panel-only APK."""
import argparse
import hashlib
import json
from pathlib import Path
from audit_characters import check_roster

ROOT=Path(__file__).resolve().parents[1]

def check(root=ROOT):
    branding=json.loads((root/'branding.json').read_text(encoding='utf-8'))
    roster=json.loads((root/'assets/roster.json').read_text(encoding='utf-8'))
    blockers=check_roster(roster)
    if not roster.get('characters'):blockers.append('Onaylı insan/kurt karakter çifti yok.')
    project=branding.get('androidGameProject')
    if not project or not (root/project/'project.godot').is_file():blockers.append('Android hedefli düzenlenebilir oyun motoru projesi yok.')
    for character in roster.get('characters',[]):
        for form in ('human','wolf'):
            asset=character.get(form,{})
            path=root/asset.get('projectAsset','__missing_asset__')
            if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest()!=asset.get('modelSha256'):
                blockers.append(f'{character.get("id")}: {form} converted model missing or hash changed')
    if project and (root/project/'project.godot').is_file():
        game=root/project
        required=['assets/maps/previews.json','assets/items/rules.json','assets/weapons/ak47/weapon.json']
        for name in required:
            if not (game/name).is_file():blockers.append('Eksik oyun verisi: '+name)
        if (game/required[0]).is_file():
            previews=json.loads((game/required[0]).read_text(encoding='utf-8'))
            for record in previews:
                asset=game/record['previewAsset'].removeprefix('res://')
                if not asset.is_file() or hashlib.sha256(asset.read_bytes()).hexdigest()!=record['sha256'] or not record['previewValidated']:
                    blockers.append('Harita önizlemesi doğrulanmadı: '+str(record['number']))
        if (game/required[2]).is_file():
            weapon=json.loads((game/required[2]).read_text(encoding='utf-8'))
            asset=game/'assets/weapons/ak47/viewmodel.glb'
            if not asset.is_file() or hashlib.sha256(asset.read_bytes()).hexdigest()!=weapon['sha256']:
                blockers.append('Birinci şahıs silah varlığı doğrulanmadı.')
    return dict(ready=not blockers,apkProduced=branding.get('apkProduced',False),buildType=branding.get('androidBuildType'),physicalAndroidDeviceTested=branding.get('physicalAndroidDeviceTested',False),blockers=blockers)

if __name__=='__main__':
    result=check();print(json.dumps(result,ensure_ascii=True,indent=2))
    raise SystemExit(0 if result['ready'] else 2)
