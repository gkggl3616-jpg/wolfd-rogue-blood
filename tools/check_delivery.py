"""Fail closed on the user's full-game delivery criteria; test APKs are not releases."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SELECTED_MAPS = {58, 59, 65, 72, 1, 2, 26, 31, 44, 46, 50, 110, 57, 100, 97, 92, 82, 83, 84}
MINIMUM_APK_BYTES = 3_000_000_000


def read(path, fallback=None):
    try:
        return json.loads(path.read_text(encoding='utf-8'))
    except (OSError, ValueError):
        return fallback


def project_file(root, asset):
    if not isinstance(asset, str) or not asset.startswith('res://'):
        return None
    project = (root / 'godot').resolve()
    path = (project / asset.removeprefix('res://')).resolve()
    return path if path.is_relative_to(project) and path.is_file() else None


def check(root=ROOT, apk=None):
    blockers = []
    catalog = read(root / 'godot/assets/maps/catalog.json', {})
    maps = catalog.get('maps', [])
    if {int(row['number']) for row in maps} != SELECTED_MAPS:
        blockers.append('İzinli 19 haritanın tam listesi doğrulanmadı.')
    incomplete_maps = [int(row['number']) for row in maps
                       if row.get('status') != 'ready' or row.get('enabled') is not True
                       or not project_file(root, row.get('asset'))]
    if incomplete_maps:
        blockers.append('Gerçek maç sahnesi/kuralları tamamlanmamış haritalar: ' + ', '.join(map(str, incomplete_maps)))
    gobekli = next((row for row in maps if int(row['number']) == 46), {})
    if not gobekli.get('allowedModeIds'):
        blockers.append('46 Göbekli Tepe için kategori+kimlik ile kanıtlanmış mod bağlantısı yok.')
    pending_modes = [row.get('id') for row in catalog.get('modes', [])
                     if row.get('implementationStatus') != 'implemented'
                     or not project_file(root, row.get('implementationScene'))]
    if pending_modes or not catalog.get('modes'):
        blockers.append(f'{len(pending_modes)} kaynak mod/alt mod için doğrulanmış maç uygulaması yok.')
    recovery = read(root / 'docs/recovered-assets.json', {'assets': []})
    pending_assets = [row for row in recovery['assets']
                      if Path(row['path']).suffix.lower() in {'.png', '.glb', '.wav', '.ogg'}
                      and row.get('visualValidation') != 'passed']
    if pending_assets:
        blockers.append(f'APK’den geri çevrilen {len(pending_assets)} görsel/model/ses kaynağı özgün kaynak ve görünüm doğrulamasını bekliyor.')
    # A headless regression pass is deliberately insufficient for these scopes.
    requirements = {
        'source-ui-validation.json': 'Özgün arayüz akışlarının görüntü ve etkileşim doğrulaması',
        'map-content-validation.json': 'Etkileşimli harita nesneleri ve mod hedefleri',
        'lighting-runtime-validation.json': 'UV/yüzey eşleşmeli çalışma zamanı aydınlatması',
        'online-service-validation.json': 'Gerçek hesap/oda/maç ve yetkili envanter hizmetleri',
        'android-install-validation.json': 'Android kurulum, imza devamlılığı ve cihaz performansı',
    }
    for name, description in requirements.items():
        proof = read(root / 'docs' / name, {})
        if proof.get('status') != 'passed' or not proof.get('evidenceFiles'):
            blockers.append(description + ' tamamlanmış ve kanıtlanmış değil.')
            continue
        for evidence in proof['evidenceFiles']:
            path = root / evidence.get('path', '__missing__')
            if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != evidence.get('sha256'):
                blockers.append(description + ': kanıt dosyası eksik veya özeti değişmiş.')
                break
    if apk is not None:
        if not apk.is_file():
            blockers.append('APK dosyası yok.')
        else:
            if apk.stat().st_size < MINIMUM_APK_BYTES:
                blockers.append('APK, kullanıcının 3 GB boyut koşulunu karşılamıyor; dolgu eklenmez.')
            try:
                with zipfile.ZipFile(apk) as package:
                    if package.testzip():
                        blockers.append('APK ZIP bütünlüğü geçersiz.')
                    if any(Path(name).suffix.lower() in {'.exe', '.dll', '.xfs', '.rar', '.sqlite3', '.jks'} for name in package.namelist()):
                        blockers.append('APK içinde Android oyun içeriği olmayan Windows/arşiv/özel kayıt dosyası bulundu.')
            except (OSError, zipfile.BadZipFile):
                blockers.append('Geçerli APK ZIP dosyası değil.')
    return {'fullReleaseReady': not blockers, 'apkProduced': False, 'blockers': blockers}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk', type=Path)
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    result = check(apk=args.apk)
    output = json.dumps(result, ensure_ascii=False, indent=2) + '\n'
    if args.report:
        args.report.write_text(output, encoding='utf-8')
    print(output)
    raise SystemExit(0 if result['fullReleaseReady'] else 2)


if __name__ == '__main__':
    main()
