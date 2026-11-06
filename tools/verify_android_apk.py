"""Verify an actual exported APK; packaging checks do not certify a complete game port."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import struct
import subprocess
import zipfile

CATALOGUES = [
    'assets/presentation/catalog.json','assets/presentation/menu-clips.json','assets/items/sets.json',
    'assets/library/weapons.json', 'assets/library/characters.json', 'assets/library/visuals.json',
    'assets/maps/catalog.json', 'assets/maps/previews.json', 'assets/maps/offline.json', 'assets/maps/radar.json', 'assets/shared_media/catalog.json',
    'assets/pc_ui/catalog.json', 'assets/full_ui/catalog.json', 'assets/ui/catalog.json',
    'assets/ui/engine-fonts.json', 'assets/ui/character-portraits.json', 'assets/ui/weapon-text.json', 'assets/ui/form-icons.json', 'assets/ui/control-icons.json', 'assets/items/rules.json',
    'assets/bots/catalog.json', 'assets/maps/arena-navigation.json',
    'assets/clientfx/catalog.json', 'assets/gameplay/source.json', 'assets/gameplay/animation-events.json', 'assets/gameplay/strong-clips.json', 'assets/gameplay/right-clips.json', 'assets/gameplay/howl.json', 'assets/abilities/source-roars.json', 'assets/maps/traversals.json', 'assets/mobile-import-profile.json', 'assets/items/power.json','assets/items/shop.json', 'assets/mutations/catalog.json', 'assets/items/boxes.json', 'assets/maps/photos.json', 'assets/ui/ranks.json',
]


class InvalidApk(ValueError):
    pass


def references(value):
    if isinstance(value, dict):
        for child in value.values(): yield from references(child)
    elif isinstance(value, list):
        for child in value: yield from references(child)
    elif isinstance(value, str) and value.startswith('res://') and PurePosixPath(value).suffix:
        yield value


def inspect_zip(path, catalogues=CATALOGUES):
    try:
        with zipfile.ZipFile(path) as apk:
            names = apk.namelist(); present = set(names)
            if len(present) != len(names): raise InvalidApk('Duplicate APK entries make resource lookup ambiguous')
            bad = apk.testzip()
            if bad: raise InvalidApk('APK CRC failure: ' + bad)
            for required in ['AndroidManifest.xml', 'classes.dex', 'assets/project.binary']:
                if required not in present: raise InvalidApk('Missing APK entry: ' + required)
            resolved = {}

            def resource_exists(resource, visiting=None):
                if resource in resolved: return resolved[resource]
                relative = resource.removeprefix('res://')
                if relative.startswith('/') or '..' in PurePosixPath(relative).parts: return False
                entry = 'assets/' + relative
                if entry in present: resolved[resource] = True;return True
                visiting = set() if visiting is None else visiting
                if resource in visiting: return False
                visiting.add(resource)
                for extension in ['.import', '.remap']:
                    if entry + extension not in present: continue
                    text = apk.read(entry + extension).decode('utf-8')
                    remap = text.split('[remap]', 1)[-1].split('\n[', 1)[0] if extension == '.import' else text
                    paths = dict(re.findall(r'(?m)^\s*(path(?:\.[\w]+)?)\s*=\s*"(res://[^"]+)"', remap))
                    selected = paths.get('path.etc2') or paths.get('path.astc') or paths.get('path')
                    if selected and resource_exists(selected, visiting): resolved[resource] = True;return True
                resolved[resource] = False;return False

            wanted = set()
            for catalogue in catalogues:
                entry = 'assets/' + catalogue
                if entry not in present: raise InvalidApk('Missing runtime catalogue: ' + catalogue)
                wanted.update(references(json.loads(apk.read(entry))))
            missing = sorted(resource for resource in wanted if not resource_exists(resource))
            if missing: raise InvalidApk('Runtime resources missing from APK: ' + ', '.join(missing[:12]))
            for resource in ['res://main.tscn', 'res://scripts/game.gd']:
                if not resource_exists(resource): raise InvalidApk('Missing startup resource: ' + resource)
            libraries = []
            for name in names:
                if not name.startswith('lib/') or not name.endswith('/libgodot_android.so'): continue
                abi = name.split('/')[1]
                with apk.open(name) as stream:
                    header = stream.read(64)
                    if header[:4] != b'\x7fELF' or header[5] != 1: raise InvalidApk('Invalid native ELF library: ' + name)
                    wide = header[4] == 2
                    machine = struct.unpack_from('<H', header, 18)[0]
                    expected = {'armeabi-v7a':40, 'arm64-v8a':183, 'x86_64':62, 'x86':3}.get(abi)
                    if machine != expected: raise InvalidApk('Native architecture mismatch: ' + name)
                    offset = struct.unpack_from('<Q' if wide else '<I', header, 32 if wide else 28)[0]
                    stride, count = struct.unpack_from('<HH', header, 54 if wide else 42)
                    if count > 256 or stride < (56 if wide else 32): raise InvalidApk('Invalid ELF segment table')
                    stream.seek(offset); segments = stream.read(stride * count); alignments=[]
                    for i in range(count):
                        if struct.unpack_from('<I', segments, i * stride)[0] == 1:
                            alignments.append(struct.unpack_from('<Q' if wide else '<I', segments, i * stride + (48 if wide else 28))[0])
                    libraries.append({'abi':abi, 'elfMachine':machine, 'loadSegmentAlignments':alignments,
                                      'supports16KiBPages':bool(alignments) and min(alignments) >= 16384})
            if not libraries: raise InvalidApk('Godot native libraries are missing')
            return {'zipIntegrityVerified':True, 'entries':len(names), 'runtimeReferencesResolved':len(wanted),
                    'cataloguesVerified':len(catalogues), 'nativeLibraries':libraries}
    except (zipfile.BadZipFile, EOFError, struct.error) as error:
        raise InvalidApk('APK archive is truncated or corrupt: ' + str(error)) from error


def inspect(path, sdk, expected_package):
    result = inspect_zip(path)
    tools = sdk / 'build-tools' / '36.0.0'
    suffix = '.exe' if os.name == 'nt' else ''
    badging = subprocess.run([str(tools/('aapt'+suffix)), 'dump', 'badging', str(path)], text=True, capture_output=True, check=True).stdout
    package = re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", badging)
    if not package or package[1] != expected_package: raise InvalidApk('Unexpected Android application identity')
    java = shutil.which('java')
    if not java: raise InvalidApk('Java is required to verify Android signatures')
    signature = subprocess.run([java, '-jar', str(tools/'lib/apksigner.jar'), 'verify', '--verbose', '--print-certs', str(path)], text=True, capture_output=True, check=True).stdout
    certificate = re.search(r'Signer #1 certificate SHA-256 digest: ([0-9a-f]+)', signature)
    if not certificate or 'Verified using v2 scheme (APK Signature Scheme v2): true' not in signature: raise InvalidApk('Verified APK v2 signature required')
    aligner = tools/('zipalign'+suffix)
    subprocess.run([str(aligner), '-c', '-P', '16', '4', str(path)], check=True, capture_output=True)
    with path.open('rb') as stream: digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    minimum = re.search(r"sdkVersion:'(\d+)'", badging)
    target = re.search(r"targetSdkVersion:'(\d+)'", badging)
    permissions = re.findall(r"uses-permission(?:-sdk-23)?: name='([^']+)'", badging)
    if expected_package.endswith('.offline') and 'android.permission.INTERNET' in permissions:
        raise InvalidApk('Offline build must not request INTERNET permission')
    result.update({'package':package[1], 'versionCode':int(package[2]), 'versionName':package[3],
                   'bytes':path.stat().st_size, 'sha256':digest, 'signerCertificateSha256':certificate[1],
                   'minimumAndroidSdk':int(minimum[1]) if minimum else None,
                   'targetAndroidSdk':int(target[1]) if target else None,
                   'permissions':permissions, 'internetPermissionRequested':'android.permission.INTERNET' in permissions,
                   'signatureVerified':True, 'signatureV2':True,
                   'signatureV3':'Verified using v3 scheme (APK Signature Scheme v3): true' in signature,
                   'zip16KiBAlignmentVerified':True, 'fullOriginalGamePort':False,
                   'physicalAndroidDeviceTested':False, 'androidEmulatorTested':False})
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('--sdk', type=Path, default=os.environ.get('ANDROID_HOME'))
    parser.add_argument('--package', default='com.wolfrogue.blood')
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    if args.sdk is None: parser.error('--sdk or ANDROID_HOME is required')
    try: data = inspect(args.apk, args.sdk, args.package)
    except (InvalidApk, OSError, subprocess.CalledProcessError, UnicodeError) as error: parser.exit(2, str(error)+'\n')
    if args.report: args.report.write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(data, ensure_ascii=False, indent=2))
