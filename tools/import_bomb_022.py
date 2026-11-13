"""Import the original time-bomb hands/device and world mesh, with source hashes."""
import argparse,gzip,hashlib,json,pathlib,re
from pc_source_cache import PcSourceCache
from convert_character import load,glb,texture_png
ROOT=pathlib.Path(__file__).resolve().parents[1]
def sha(raw):return hashlib.sha256(raw).hexdigest()
def run(folder):
 cache=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',folder)
 output=ROOT/'godot/assets/weapons/timebomb';output.mkdir(parents=True,exist_ok=True)
 source='root/wt_guns/models_pv/wt_pv_timebomb.ltb';raw=cache.get(source)
 clips={'idle':'idle0','select':'Select','plant':'Fire','walk':'Walk'}
 asset=load(raw,set(clips.values()));asset['info']['sha256']=sha(raw)
 if asset['children']:raise ValueError('Unresolved bomb animation donor')
 skins={};proof=[]
 # weapondata.dat's HumanHands token resolves to the existing default FP hand.
 names=['wt_pv_hand','wt_pv_timebomb','wt_pv_timebomb_1','wt_pv_timebomb_2']
 for slot,name in enumerate(names):
  path='root/wt_guns/skins_pv/'+name+'.dtx';data=cache.get(path)
  skins[slot]=(path,texture_png(data));proof.append({'slot':slot,'path':path,'sha256':sha(data)})
 converted=glb(asset,asset,skins,clips,output/'viewmodel.glb',root_scale=1,freeze_root=False,alpha_mask=False)
 events=next(row['keyEvents'] for row in asset['info']['animations'] if row['name']=='Fire')
 install=next(row['timeMs']/1000 for row in events if 'INSTALL_TIMEBOMB' in row['key'])
 select=float(asset['animations']['Select']['times'][-1]-asset['animations']['Select']['times'][0])
 world_source='root/wt_props/models/groundtimebomb.ltb';world_raw=cache.get(world_source);world=load(world_raw,set());world['info']['sha256']=sha(world_raw)
 skin_source='root/wt_guns/skins_hh/wt_hh_timebomb.dtx';skin_raw=cache.get(skin_source)
 world_result=glb(world,world,{slot:(skin_source,texture_png(skin_raw)) for slot in {m['material'] for m in world['meshes']}},{},output/'world.glb',root_scale=1/62.5,alpha_mask=False)
 table=gzip.decompress((ROOT/'docs/pc_sources_017/weapondata.dat.gz').read_bytes())
 source_offset=table.lower().find('wt_pv_timebomb.ltb'.encode('utf-16le'));assert source_offset>=0
 result={'schemaVersion':1,'asset':'res://assets/weapons/timebomb/viewmodel.glb','sha256':converted['sha256'],'source':source,'sourceSha256':sha(raw),'sourceWeaponTableSha256':sha(table),'sourceModelNameOffset':source_offset,'textureSlots':proof,'handsResolution':'HumanHands -> existing default WT_PV_HAND; per-character hand replacement remains local equipment presentation.','clips':clips,'sourcePlantEvents':events,'selectSeconds':select,'installEventSeconds':install,'plantSeconds':select+install,'world':{'asset':'res://assets/weapons/timebomb/world.glb','sha256':world_result['sha256'],'source':world_source,'sourceSha256':sha(world_raw),'texture':skin_source,'textureSha256':sha(skin_raw)},'soundKeys':{'10':'root/wt_snd/specialweapon/timebomb/bomb_combine.wav','11':'root/wt_snd/specialweapon/timebomb/bomb_button.wav','12':'root/wt_snd/specialweapon/timebomb/bomb_activate.wav'},'scope':'Original device, hands, textures and Select/Fire/INSTALL_TIMEBOMB events. Camera placement and defuse display are mobile adaptation; no original defuse hand clip has been established.'}
 (output/'device.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
 (ROOT/'docs/bomb-source-022.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
 print(json.dumps({'assetBytes':(output/'viewmodel.glb').stat().st_size,'plantSeconds':result['plantSeconds'],'eventSeconds':install,'worldVertices':world_result.get('vertices')}),flush=True)
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--cache',type=pathlib.Path,required=True);run(parser.parse_args().cache)
