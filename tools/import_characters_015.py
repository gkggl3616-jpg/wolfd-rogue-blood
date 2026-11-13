"""Import missing source human/wolf definitions with their own skins and explicit child animation donor."""
import concurrent.futures,gzip,hashlib,json,pathlib,posixpath,sys,struct,collections,subprocess
import numpy as np
from convert_character import quaternion
from pc_source_cache import PcSourceCache
from audit_characters import parse_model_definitions,identity
from convert_character import load,glb,texture_png
ROOT=pathlib.Path(__file__).resolve().parents[1]
source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',sys.argv[1]);defs={r['id']:r for r in parse_model_definitions((ROOT/'../scratch/pc-selected/modelbutes.txt').read_bytes())}
audit=json.loads(gzip.decompress((ROOT/'docs/character-audit.json.gz').read_bytes()));records={r['id']:r for r in audit['definitions']};catalog=json.loads((ROOT/'godot/assets/library/characters.json').read_bytes());baseline=json.loads(subprocess.check_output(['git','show','HEAD:godot/assets/library/characters.json'])) if '--repack-existing' in sys.argv else catalog
existing={r['human']['sourceDefinition'] for r in baseline['characters'] if r.get('engineImported',False)};results=[];failures=[]
HUMAN=dict(idle='LSt',run='LRF',jump='LJJ',attack='URi1Fi',reload='URi1Re',crouch='LC',crouch_run='LCWF')
WOLF=dict(idle='LSt',run='LRF',jump='LJJ',attack='UMFi1',roar='T_CRY',crouch='LC',crouch_run='LCWF',wolf_run='T_WallDash',body_attack='T_Bodyatk',special_attack='T_Specialatk',wall_hold='T_WallHold_L',airborne_attack='T_WallDashAtk')
raw_table=(ROOT/'../scratch/pc-selected/characterdata.dat').read_bytes();assert len(raw_table)%21==0
source_items=collections.defaultdict(list)
for offset in range(0,len(raw_table),21):
 item,_,_=struct.unpack_from('<HHH',raw_table,offset);form=raw_table[offset+6];team=raw_table[offset+8];model=struct.unpack_from('<H',raw_table,offset+9)[0]
 source_items[item].append({'form':form,'team':team,'model':'Model'+str(model),'offset':offset})
candidates=[]
for item,rows in source_items.items():
 if not item:continue
 for human in rows:
  if human['form']!=0 or human['model'] not in defs or human['model'] in existing:continue
  wolves={r['model'] for r in rows if r['form']==1 and r['team']==human['team'] and r['model'] in defs}
  if len(wolves)!=1:failures.append({'id':human['model'],'reason':'ambiguous source characterdata pair'});continue
  candidates.append((human['model'],next(iter(wolves)),item,human))

def retarget(asset,donor):
 if asset['info']['skeletonSha256']==donor['info']['skeletonSha256']:return donor,False
 old={b['name']:b for b in donor['info']['bones']};target=asset['info']['bones'];tracks=[]
 for bone in target:
  d=old.get(bone['name'])
  if d:
   dp=donor['info']['bones'][d['parent']]['name'] if d['parent'] is not None else None
   ap=target[bone['parent']]['name'] if bone['parent'] is not None else None
   if dp!=ap:raise ValueError('Source animation hierarchy differs at '+bone['name'])
 for name in ['Bip01','Bip01 Pelvis','Bip01 Spine','Bip01 Head']:
  if name not in old or not any(b['name']==name for b in target):raise ValueError('Required source humanoid bone missing')
 animations={}
 for name,clip in donor['animations'].items():
  mapped=[];count=len(clip['times'])
  for bone in target:
   if bone['name'] in old:mapped.append(clip['tracks'][old[bone['name']]['index']])
   else:
    m=asset['matrices'][bone['index']];local=m if bone['parent'] is None else np.linalg.inv(asset['matrices'][bone['parent']])@m
    mapped.append({'translation':np.repeat(local[:3,3][None,:],count,axis=0),'rotation':np.repeat(np.array(quaternion(local))[None,:],count,axis=0)})
  animations[name]={'times':clip['times'],'tracks':mapped}
 return {**donor,'info':{**donor['info'],'skeletonSha256':asset['info']['skeletonSha256'],'bones':target},'animations':animations},True

for ident,expected,item_id,source_row in candidates:
 record=records[ident]
 pair={'id':'pair-'+ident.lower(),'name':record['name'],'available':False,'engineImported':True,'pairConfirmed':True,'visualValidation':'source_import_pending_render','sourceTeam':'red' if source_row['team']==1 else 'blue','sourceItemId':item_id,'sourceTeamCode':source_row['team'],'pairEvidence':{'human':ident,'wolf':expected,'sourceTableSha256':hashlib.sha256(raw_table).hexdigest(),'humanOffset':source_row['offset'],'basis':'same exact characterdata item ID/team, form 0 and form 1 model definitions'}}
 try:
  for form,model_id,clips in [('human',ident,HUMAN),('wolf',expected,WOLF)]:
   definition=defs[model_id];path='root/'+definition['model'].replace('\\','/').lower();raw=source.get(path);asset=load(raw,set());asset['info']['sha256']=hashlib.sha256(raw).hexdigest();assert len(asset['children'])==1
   donorpath=posixpath.normpath(posixpath.join(posixpath.dirname(path),asset['children'][0].replace('\\','/').lower()));donorraw=source.get(donorpath);donor=load(donorraw,set(clips.values()));donor["info"]["sha256"]=hashlib.sha256(donorraw).hexdigest();donor_original_skeleton=donor['info']['skeletonSha256'];donor,was_retargeted=retarget(asset,donor)
   selected={k:v for k,v in clips.items() if v in donor['animations']};assert all(k in selected for k in ['idle','run','jump','attack','crouch','crouch_run']+(['reload'] if form=='human' else ['roar']))
   names={mesh['material']:definition['values'].get('Skin'+str(mesh['material']), '') for mesh in asset['meshes']}
   for mesh in asset['meshes']:
    if not names[mesh['material']]:
     if not mesh['name'].lower().startswith('tattoo'):raise ValueError('Missing nonoptional material '+mesh['name'])
     names[mesh['material']]='WT_Chars/SkinsTattoo/Tattoo_Kwang.dtx'
   with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
    contents=list(pool.map(lambda n:source.get('root/'+n.replace('\\','/').lower()),names.values()))
   skins={slot:(name,texture_png(rawtex)) for (slot,name),rawtex in zip(names.items(),contents)}
   target=ROOT/'godot/assets/library/characters'/f"{pair['id']}-{form}.glb";result=glb(asset,donor,skins,selected,target,alpha_mask=False,external_texture_dir=ROOT/'godot/assets/library/character_skins')
   pair[form]={'asset':'res://'+str(target.relative_to(ROOT/'godot')),'sha256':result['sha256'],'source':definition['model'],'sourceDefinition':model_id,'sourceSha256':hashlib.sha256(raw).hexdigest(),'donor':donorpath,'donorSha256':hashlib.sha256(donorraw).hexdigest(),'skeletonSha256':result['skeletonSha256'],'bindPoseExact':asset['info']['bindPoseSha256']==donor['info']['bindPoseSha256'],'clips':list(selected),'triangles':result['triangles'],'sourceDonorSkeletonSha256':donor_original_skeleton,'animationMappedBySourceBoneNames':was_retargeted,'soundTemplate':definition['values'].get('SoundTemplate',''),'sourceClientFx':{k:v for k,v in definition['values'].items() if k.startswith('ClientFX') and v},'tattooMaterials':'source UV meshes retained; placeholder hidden until explicit equipment'}
  catalog['characters']=[r for r in catalog['characters'] if r['id']!=pair['id']];catalog['characters'].append(pair)
  (ROOT/'godot/assets/library/characters.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
  results.append(pair['id']);print('CHARACTER_IMPORTED',pair['id'],pair['name'],flush=True)
 except Exception as e:failures.append({'id':ident,'reason':str(e)});print('CHARACTER_REJECTED',ident,str(e),flush=True)
(ROOT/'godot/assets/library/characters.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
for entry in catalog['characters']:
 for rows in source_items.values():
  human=next((r for r in rows if r['model']==entry['human']['sourceDefinition'] and r['form']==0),None)
  if human:entry['sourceTeam']='red' if human['team']==1 else 'blue';entry['sourceTeamCode']=human['team'];break
(ROOT/'godot/assets/library/characters.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
(ROOT/'docs/character-expansion-015.json').write_text(json.dumps({'added':results,'failures':failures,'validation':'Not available until engine/visual acceptance'},ensure_ascii=False,indent=2)+'\n')
