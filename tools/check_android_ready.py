"""Check actual Android game prerequisites. Does not create a panel-only APK."""
import argparse
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
    if not project or not (root/project).is_dir():blockers.append('Android hedefli düzenlenebilir oyun motoru projesi yok.')
    return dict(ready=not blockers,apkProduced=False,blockers=blockers)

if __name__=='__main__':
    result=check();print(json.dumps(result,ensure_ascii=True,indent=2))
    raise SystemExit(0 if result['ready'] else 2)
