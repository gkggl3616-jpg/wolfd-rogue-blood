"""Check 0.28 runtime/source integrity without creating an APK."""
import gzip,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def check(root=ROOT):
 blockers=[]
 def read(name):return json.loads((root/name).read_bytes())
 def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
 def asset(row,label):
  if digest(root/'godot'/row.get('asset','__missing__').removeprefix('res://'))!=row.get('sha256','invalid'):blockers.append('Native asset missing or changed: '+label)
 library=read('godot/assets/library/weapons.json');rules=read('godot/assets/weapons/native-rules.json');motion=read('godot/assets/weapons/animations/index.json');audio=read('godot/assets/weapons/audio.json');flight=read('godot/assets/gameplay/projectiles.json');bots=read('godot/assets/bots/weapons.json')
 ids={w['id'] for w in library['items']}
 if len(ids)!=903 or set(rules['items'])!=ids or set(audio['items'])!=ids:blockers.append('All903 original weapon rule/audio identities are required')
 source=hashlib.sha256(gzip.decompress((root/'docs/pc_sources_017/weapondata.dat.gz').read_bytes())).hexdigest()
 if rules['sourceSha256']!=source or audio['sourceSha256']!=source:blockers.append('Weapon rule/audio native table provenance mismatch')
 if set(motion['models'])!=set(library['models']):blockers.append('Original motion metadata must cover every available source viewmodel')
 for key,row in motion['models'].items():
  if 'asset' in row:asset(row,'motion '+key)
 if len(flight['projectiles'])!=72 or len(flight['models'])!=66:blockers.append('All72 original projectile definitions and66 source models are required')
 if {r['projectile'] for r in rules['items'].values() if r['projectile']}!=set(flight['projectiles']):blockers.append('A weapon projectile association is missing')
 fx_hash=hashlib.sha256(gzip.decompress((root/'docs/pc_sources_017/fx.txt.gz').read_bytes())).hexdigest()
 if flight['sourceSha256']!=fx_hash:blockers.append('Projectile definition source provenance mismatch')
 for kind in ['models','textures']:
  for key,row in flight[kind].items():asset(row,'projectile '+key)
 if set(bots['profiles'])!={'knife','pistol','sniper','grenade','heavy'}:blockers.append('Native HH weapons for the five newly admitted modes are missing')
 for key,row in bots['profiles'].items():asset(row,'bot '+key)
 from check_bot_arsenal import check as bot_check
 blockers.extend(bot_check(root)['blockers'])
 return {'passed':not blockers,'blockers':blockers,'weaponRecords':len(rules['items']),'projectileModels':len(flight['models']),'apkProduced':False}
if __name__=='__main__':
 result=check();print(json.dumps(result,indent=2));raise SystemExit(0 if result['passed'] else 1)
