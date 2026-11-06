"""Attach exact donor/clip provenance to imports without changing mesh or animation samples."""
import hashlib,json,pathlib,struct
from add_source_action import unpack
ROOT=pathlib.Path(__file__).resolve().parents[1]
CLIPS={'human':dict(idle='LSt',run='LRF',jump='LJJ',attack='URi1Fi',reload='URi1Re',crouch='LC',crouch_run='LCWF'),'wolf':dict(idle='LSt',run='LRF',jump='LJJ',attack='UMFi1',roar='T_CRY',crouch='LC',crouch_run='LCWF',wolf_run='T_WallDash',body_attack='T_Bodyatk',special_attack='T_Specialatk',wall_hold='T_WallHold_L',airborne_attack='T_WallDashAtk')}
p=ROOT/'godot/assets/library/characters.json';data=json.loads(p.read_bytes());count=0
for entry in data['characters']:
 if not entry.get('pairEvidence'):continue
 for form in ['human','wolf']:
  row=entry[form];target=ROOT/'godot'/row['asset'].removeprefix('res://');raw=target.read_bytes();assert hashlib.sha256(raw).hexdigest()==row['sha256']
  doc,binary=unpack(raw)
  for animation in doc['animations']:
   source=CLIPS[form][animation['name']];animation['extras']={'sourceClip':source,'sourceSha256':row['donorSha256'],'rootMotion':'XZ frozen; movement uses collision controller'}
   row.setdefault('sourceActions',{})[animation['name']]={'clip':source,'donor':row['donor'],'donorSha256':row['donorSha256']}
  text=json.dumps(doc,separators=(',',':')).encode();text+=b' '*((-len(text))%4)
  updated=struct.pack('<III',0x46546c67,2,28+len(text)+len(binary))+struct.pack('<II',len(text),0x4e4f534a)+text+struct.pack('<II',len(binary),0x004e4942)+binary
  if raw!=updated:target.write_bytes(updated)
  row['sha256']=hashlib.sha256(updated).hexdigest()
 entry['available']=False;entry['visualValidation']='source_import_pending_render';count+=1
p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n');print('Annotated source pairs',count)
