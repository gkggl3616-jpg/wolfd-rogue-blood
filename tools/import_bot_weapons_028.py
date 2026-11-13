"""Import exact native third-person representatives for offline weapon-rule modes."""
import argparse,hashlib,json
from pathlib import Path
from convert_character import load,glb,texture_png
from pc_source_cache import PcSourceCache
ROOT=Path(__file__).resolve().parents[1]
NAMES={'knife':'Temel Bıçak','pistol':'EM-92 FS','sniper':'I-115 GL','grenade':'MK-5 G','heavy':'EM-134Minigun'}
def run(cache):
 source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',cache);library=json.loads((ROOT/'godot/assets/library/weapons.json').read_text());banks=json.loads((ROOT/'godot/assets/weapons/audio.json').read_text())['items'];rules=json.loads((ROOT/'godot/assets/weapons/native-rules.json').read_text())['items'];media=json.loads((ROOT/'godot/assets/shared_media/catalog.json').read_text())['sounds'];profiles={}
 out=ROOT/'godot/assets/bots/weapons';out.mkdir(exist_ok=True)
 for category,name in NAMES.items():
  item=next(r for r in library['items'] if r['name']==name);bank=banks[item['id']];path='root/'+bank['hhModel'].replace('\\','/').lower();skin='root/'+bank['hhSkin'].replace('\\','/').lower();raw=source.get(path);image=source.get(skin);model=load(raw,set());skins={slot:(skin,texture_png(image)) for slot in {m['material'] for m in model['meshes']}};p=out/(category+'.glb');glb(model,model,skins,{},p,root_scale=.016,freeze_root=False,alpha_mask=False,external_texture_dir=out)
  native=rules[item['id']];profiles[category]={'asset':'res://'+str(p.relative_to(ROOT/'godot')),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'source':path,'sourceSha256':hashlib.sha256(raw).hexdigest(),'skinSource':skin,'skinSourceSha256':hashlib.sha256(image).hexdigest(),'itemId':item['id'],'name':name,'category':category,'capacity':native['capacity'],'fireInterval':native['fireIntervalMs']/1000,'reloadSeconds':float(item['gameplayTuning']['reloadSeconds']),'fireSound':media.get(bank['keys'].get('10',''),{}).get('asset',''),'reloadSound':media.get(bank['keys'].get('1',''),{}).get('asset',''),'native':native}
  print('SOURCE_BOT_WEAPON',category,name,flush=True)
 result={'schemaVersion':1,'profiles':profiles,'scope':'Exact supplied third-person models/skins and native capacity/cadence. Local bot damage/difficulty remains unchanged; weapon-specific third-person animation banks are not fully recreated.'};(ROOT/'godot/assets/bots/weapons.json').write_text(json.dumps(result,indent=2)+'\n');(ROOT/'docs/bot-weapons-source-028.json').write_text(json.dumps(result,indent=2)+'\n')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('cache',type=Path);run(p.parse_args().cache)
