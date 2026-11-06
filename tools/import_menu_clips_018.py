"""Preserve the original human UI_Default_Idle and weapon-preview clips separately."""
import hashlib,json,pathlib,sys
from pc_source_cache import PcSourceCache
from convert_character import load
from ltb_metadata import inspect_ltb
ROOT=pathlib.Path(__file__).resolve().parents[1]
def run(folder):
 cache=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',folder);characters=json.loads((ROOT/'godot/assets/library/characters.json').read_bytes())['characters'];donors={}
 for path in sorted({r['human']['donor'].lower().removeprefix('root/') for r in characters if r.get('available')}):
  raw=cache.get('root/'+path);names={a['name'].lower():a['name'] for a in inspect_ltb(raw)['animations']};selected={names[k] for k in ['ui_default_idle','ui_mainweapon_idle'] if k in names};asset=load(raw,selected);clips={}
  for key,wanted in [('unarmed','ui_default_idle'),('primary','ui_mainweapon_idle')]:
   name=names.get(wanted,wanted)
   if name not in asset['animations']:raise ValueError('Required original menu animation missing: '+path+name)
   animation=asset['animations'][name]
   clips[key]={'sourceClip':name,'times':animation['times'],'bones':[{'name':bone['name'],'translation':track['translation'].tolist(),'rotation':track['rotation'].tolist()} for bone,track in zip(asset['info']['bones'],animation['tracks'])]}
  donors[path]={'sourceSha256':hashlib.sha256(raw).hexdigest(),'clips':clips};print('MENU_SOURCE',path,list(clips),flush=True)
 result={'schemaVersion':1,'donors':donors,'scope':'Original neutral UI clip for the character menu. Gameplay GLBs and combat idle clips remain unchanged.'}
 out=ROOT/'godot/assets/presentation';out.mkdir(exist_ok=True);(out/'menu-clips.json').write_text(json.dumps(result,separators=(',',':'))+'\n')
 proof={'donors':{p:{'sourceSha256':r['sourceSha256'],'clips':{k:{'sourceClip':v['sourceClip'],'frames':len(v['times'])} for k,v in r['clips'].items()}} for p,r in donors.items()},'assetSha256':hashlib.sha256((out/'menu-clips.json').read_bytes()).hexdigest()}
 (ROOT/'docs/menu-animation-source-018.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n')
if __name__=='__main__':run(pathlib.Path(sys.argv[1]))
