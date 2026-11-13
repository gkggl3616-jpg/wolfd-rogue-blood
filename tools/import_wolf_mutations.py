"""Import the six source PC wolf mutation bodies and their explicit animation donors."""
import argparse,sys,pathlib,json,gzip,hashlib,posixpath

from audit_characters import normalize,parse_model_definitions
from pc_archive import extract_entry
from convert_character import load,glb,texture_png
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--cache',type=pathlib.Path,required=True);parser.add_argument('--definitions',type=pathlib.Path);args=parser.parse_args()
ROOT=pathlib.Path(__file__).resolve().parents[1];cache=args.cache;cache.mkdir(parents=True,exist_ok=True)
index=ROOT/'docs/pc-archive-inventory.json.gz';files=json.loads(gzip.decompress(index.read_bytes()))['files'];lookup={normalize(row['name']):row['name'] for row in files}

def get(path):
 key=normalize('wolfteam kurtları/Root/'+path.removeprefix('Root/'));name=lookup[key];target=cache/(hashlib.sha256(key.encode()).hexdigest()[:20]+pathlib.Path(path).suffix)
 if not target.exists():extract_entry(index,name,target)
 return target.read_bytes(),name
rawdef=args.definitions.read_bytes() if args.definitions else get('attributes/modelbutes.txt')[0];defs={row['id']:row for row in parse_model_definitions(rawdef)}
clips=dict(idle='LSt',run='LRF',jump='LJJ',attack='UMFi1',roar='T_CRY',crouch='LC',crouch_run='LCWF',wolf_run='T_WallDash',body_attack='T_Bodyatk',airborne_attack='T_WallDashAtk',special_attack='T_Specialatk',wall_hold='T_WallHold_L')
rows=[];out=ROOT/'godot/assets/mutations';out.mkdir(exist_ok=True)
for typ,ident,team in [('power','Model4','red'),('power','Model5','blue'),('guardian','Model6','red'),('guardian','Model7','blue'),('ghost','Model8','red'),('ghost','Model9','blue')]:
 definition=defs[ident];raw,source=get(definition['model']);asset=load(raw,set());asset['info']['sha256']=hashlib.sha256(raw).hexdigest();print('MUTATION',typ,team,'children',asset['children'],flush=True)
 if len(asset['children'])!=1:raise ValueError('Expected one explicit animation donor')
 donorpath=posixpath.normpath(posixpath.join(posixpath.dirname(definition['model'].replace('\\','/')),asset['children'][0].replace('\\','/')));donor_raw,donor_source=get(donorpath);donor=load(donor_raw,set(clips.values()))
 selected={k:v for k,v in clips.items() if v in donor['animations']}
 assert all(key in selected for key in ['idle','run','jump','attack','roar']),('Required source clip absent',selected)
 skins={};proof=[]
 for slot in sorted({m['material'] for m in asset['meshes'] if not m['name'].lower().startswith('tattoo')}):
  skin=definition['values'].get('Skin'+str(slot));assert skin,('Source skin missing',slot)
  data,path=get(skin);skins[slot]=(skin,texture_png(data));proof.append({'slot':slot,'source':path,'sha256':hashlib.sha256(data).hexdigest()})
 target=out/(typ+'-'+team+'.glb');result=glb(asset,donor,skins,selected,target,alpha_mask=False)
 rows.append({'id':typ,'team':team,'asset':'res://assets/mutations/'+target.name,'sha256':result['sha256'],'definition':ident,'source':source,'sourceSha256':hashlib.sha256(raw).hexdigest(),'donor':donor_source,'donorSha256':hashlib.sha256(donor_raw).hexdigest(),'skeletonSha256':result['skeletonSha256'],'bindPoseExact':asset['info']['bindPoseSha256']==donor['info']['bindPoseSha256'],'clips':list(selected),'triangles':result['triangles'],'skins':proof})
 print('CONVERTED',target.name,result['triangles'],flush=True)
(ROOT/'godot/assets/mutations/catalog.json').write_text(json.dumps({'schemaVersion':1,'modelDefinitionsSha256':hashlib.sha256(rawdef).hexdigest(),'models':rows,'sourcePcNumericStatsVerified':False,'materialPolicy':'Opaque base surfaces; PC special shaders are not reproduced by alpha masking','animationPolicy':'Exact source bone-name/parent skeleton; mesh bind matrices retained, explicit source child animation donors'},ensure_ascii=False,indent=2)+'\n')
