"""Verify imported 0.29 NPC assets and their native combat associations."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def check(root=ROOT):
    data=json.loads((root/'godot/assets/bots/arsenal.json').read_bytes())
    rules=json.loads((root/'godot/assets/weapons/native-rules.json').read_bytes())['items']
    blockers=[]
    if len(data['profiles'])!=59:blockers.append('Expected 59 admitted native NPC equipment records')
    for kind in ['profiles','textures']:
        for key,row in data[kind].items():
            path=root/'godot'/row['asset'].removeprefix('res://')
            if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest()!=row['sha256']:blockers.append('NPC asset missing/changed: '+key)
            if kind=='profiles':
                if row['native']!=rules[key] or row['capacity']!=rules[key]['capacity'] or row['fireInterval']!=rules[key]['fireIntervalMs']/1000:blockers.append('NPC native weapon association changed: '+key)
                if not row['source'].startswith('root/wt_guns/models_hh/') or len(row['sourceSha256'])!=64 or len(row['skinSourceSha256'])!=64:blockers.append('NPC source provenance missing: '+key)
                if row['reloadSeconds']<=0:blockers.append('NPC reload duration invalid: '+key)
    return {'passed':not blockers,'blockers':blockers,'profiles':len(data['profiles']),'textures':len(data['textures']),'apkProduced':False}
if __name__=='__main__':
    result=check();print(json.dumps(result,indent=2));raise SystemExit(0 if result['passed'] else 1)
