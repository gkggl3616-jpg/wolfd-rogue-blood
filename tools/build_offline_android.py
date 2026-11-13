"""Build and verify one signed offline APK, without weakening the full-port gate.

Godot's Android SDK/JDK paths must be configured in its editor settings. Use a
portable editor if its export temporary directory belongs on another volume.
The signing temporary directory needs room for one APK, as does --output.
Godot's Android exporter also writes an intermediate APK into its OS temporary
directory (on Linux /tmp); TMPDIR alone does not redirect that engine path.
Give that directory sufficient capacity too, for example in a dedicated build
container with /tmp on the chosen temporary volume.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile

from check_offline_ready import check
from verify_android_apk import inspect

ROOT = Path(__file__).resolve().parents[1]


def build(args):
    readiness = check()
    if not readiness['offlineBuildReady']:
        raise RuntimeError(json.dumps(readiness, indent=2))
    if args.output.exists():
        raise RuntimeError('Output already exists; choose a new path to preserve it')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    unsigned = args.output.with_suffix('.unsigned.apk')
    if unsigned.exists(): raise RuntimeError('Unsigned output already exists')
    with tempfile.TemporaryDirectory(prefix='wolf-offline-project-', dir=args.temp) as project_folder:
        project = Path(project_folder)
        for name in ['assets', 'scripts', 'ui']:
            (project/name).symlink_to((ROOT/'godot'/name).resolve(), target_is_directory=True)
        if args.cache_overlay:
            # Existing imports are read through links; platform-specific new
            # files and export scratch stay in the chosen temporary volume.
            cache=project/'.godot';cache.mkdir()
            for source in (ROOT/'godot/.godot').iterdir():
                target=cache/source.name
                if source.name=='imported':
                    target.mkdir()
                    for imported in source.iterdir():
                        (target/imported.name).symlink_to(imported.resolve(),target_is_directory=imported.is_dir())
                elif source.name=='exported':target.mkdir()
                elif source.name=='editor':shutil.copytree(source,target)
                elif source.is_file():shutil.copyfile(source,target)
                else:target.symlink_to(source.resolve(),target_is_directory=True)
        else:
            (project/'.godot').symlink_to((ROOT/'godot/.godot').resolve(), target_is_directory=True)
        for name in ['project.godot', 'main.tscn', 'icon.svg', 'icon.svg.import']:
            shutil.copyfile(ROOT/'godot'/name, project/name)
        preset = (ROOT/'godot/export_presets.cfg').read_text().replace('package/signed=true', 'package/signed=false')
        expected_package='com.wolfrogue.blood.offline'
        if args.parallel_test:
            expected_package+='.'+'test'
            preset=preset.replace('package/name="Wolf Rogue Blood Offline"','package/name="Wolf Rogue Blood Test"')
            preset=preset.replace('package/unique_name="com.wolfrogue.blood.offline"','package/unique_name="'+expected_package+'"')
            config=(project/'project.godot').read_text().replace('config/name="Wolf Rogue Blood"','config/name="Wolf Rogue Blood Test"')
            (project/'project.godot').write_text(config)
        (project/'export_presets.cfg').write_text(preset)
        subprocess.run([str(args.godot), '--headless', '--path', str(project), '--export-release', 'Android Offline', str(unsigned)], check=True)
    # Some engine export errors return zero. Require an actual complete ZIP.
    with zipfile.ZipFile(unsigned) as package:
        if 'AndroidManifest.xml' not in package.namelist(): raise RuntimeError('Export has no Android manifest')
    with tempfile.TemporaryDirectory(prefix='wolf-offline-sign-', dir=args.temp) as signing_folder:
        signed = Path(signing_folder)/args.output.name
        signer = args.sdk/'build-tools/36.0.0/lib/apksigner.jar'
        subprocess.run([shutil.which('java') or 'java', '-jar', str(signer), 'sign', '--ks', str(args.keystore),
                        '--ks-key-alias', args.alias, '--ks-pass', 'file:'+str(args.password_file),
                        '--out', str(signed), str(unsigned)], check=True)
        report = inspect(signed, args.sdk, expected_package)
        report.update({'runtimeCodeSha256':readiness['runtimeCodeSha256'], 'scope':readiness['scope'],
                       'buildType':'signed-offline-release', 'apkProduced':True, 'artifact':args.output.name})
        report['parallelTestInstall']=args.parallel_test
        report['existingProductionInstallPreserved']=args.parallel_test
        # Reuse the unsigned file's allocation on small workspaces. The verified
        # signed temporary copy survives until the destination hash is checked.
        shutil.copyfile(signed, unsigned)
        import hashlib
        with unsigned.open('rb') as stream:
            if hashlib.file_digest(stream, 'sha256').hexdigest() != report['sha256']:
                raise RuntimeError('Signed APK copy failed its checksum')
        os.replace(unsigned, args.output)
    report_path = args.output.with_suffix('.validation.json')
    report_path.write_text(json.dumps(report, indent=2)+'\n')
    print('VERIFIED_OFFLINE_APK '+str(args.output), flush=True)
    print(json.dumps(report, indent=2), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ['godot', 'sdk', 'keystore', 'password-file', 'output']:
        parser.add_argument('--'+name, type=Path, required=True)
    parser.add_argument('--alias', default='androiddebugkey')
    parser.add_argument('--temp', type=Path)
    parser.add_argument('--parallel-test', action='store_true', help='Separate test application identity; preserves an existing install signed with another key')
    parser.add_argument('--cache-overlay', action='store_true', help='Keep new export/import scratch in --temp while reusing current imported assets')
    args = parser.parse_args()
    for name in ['godot', 'sdk', 'keystore', 'password_file', 'output']:
        setattr(args, name, getattr(args, name).resolve())
    try: build(args)
    except (OSError, RuntimeError, ValueError, zipfile.BadZipFile, subprocess.CalledProcessError) as exc:
        parser.exit(2, str(exc)+'\n')
