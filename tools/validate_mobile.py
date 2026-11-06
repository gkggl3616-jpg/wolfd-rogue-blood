"""Run mobile regressions without producing or publishing an APK."""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def code_fingerprint():
    digest=hashlib.sha256()
    files=sorted((ROOT/'godot').glob('scripts/*.gd'))+sorted((ROOT/'godot').glob('ui/*.gd'))+sorted((ROOT/'godot').glob('ui/*.gdshader'))+[(ROOT/'godot/project.godot')]
    files += [ROOT/'godot/assets'/name for name in ['maps/photos.json','ui/ranks.json','items/boxes.json','library/visuals.json','items/power.json','items/shop.json','mutations/catalog.json','library/characters.json','ui/character-portraits.json','maps/catalog.json','mobile-import-profile.json','maps/traversals.json','abilities/source-roars.json','clientfx/catalog.json','gameplay/source.json','gameplay/animation-events.json','gameplay/strong-clips.json']]
    for path in files:
        digest.update(str(path.relative_to(ROOT)).encode());digest.update(b'\0');digest.update(path.read_bytes());digest.update(b'\0')
    return digest.hexdigest()


def validate(godot, report=None):
    version = subprocess.run([godot, '--version'], capture_output=True, text=True, check=True).stdout.strip()
    if not version.startswith('4.7.2.'):
        raise RuntimeError(f'This restored project requires Godot 4.7.2; found {version}')
    steps = [
        ('data_and_local_admin', [sys.executable, '-m', 'unittest', 'discover', '-s', 'tests', '-v']),
        ('asset_prerequisites', [sys.executable, 'tools/check_android_ready.py']),
        ('godot_import', [godot, '--headless', '--path', 'godot', '--editor', '--import', '--quit']),
    ]
    for script in ['shop_controls_017','clientfx_017', 'mobile_016', 'mobile_015', 'bot_traversals_015', 'persistence', 'local_panel_protocol', 'touch_ownership', 'smoke', 'mobile_lifecycle', 'map_audio', 'wall_hold', 'combat_continuation', 'offline_matches', 'gameplay_reference', 'bot_behaviour', 'pc_reference_expansion', 'round_equipment_gifts', 'ui_templates', 'ui_flows']:
        steps.append((script, [godot, '--headless', '--path', 'godot', '--fixed-fps', '60', '--script', f'res://tests/{script}.gd']))
    results = []
    for name, command in steps:
        print(f'Checking {name}...', flush=True)
        result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=600)
        # Godot can return 0 for certain resource/parse errors; those still fail QA.
        errors = re.findall(r'(?m)^(?:SCRIPT ERROR:|ERROR:|WARNING:.*(?:leaked|orphan)).*$', result.stdout)
        item = {'name': name, 'passed': result.returncode == 0 and not errors, 'exitCode': result.returncode, 'errors': errors}
        results.append(item)
        if not item['passed']:
            print(result.stdout, flush=True)
            break
        print('\n'.join(result.stdout.splitlines()[-4:]), flush=True)
    data = {'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'godotVersion': version,
            'runtimeCodeSha256':code_fingerprint(),
            'passed': len(results) == len(steps) and all(x['passed'] for x in results),
            'steps': results, 'apkProduced': False, 'fullOriginalGamePort': False,
            'rendering': 'headless_dummy', 'physicalAndroidDeviceTested': False}
    if report:
        Path(report).write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')
    return data


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default='godot')
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    try:
        data = validate(args.godot, args.report)
    except (OSError, RuntimeError, subprocess.SubprocessError) as exc:
        parser.exit(2, str(exc) + '\n')
    raise SystemExit(0 if data['passed'] else 1)


if __name__ == '__main__':
    main()
