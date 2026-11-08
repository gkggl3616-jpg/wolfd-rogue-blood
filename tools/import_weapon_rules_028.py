"""Decode independently bounded weapon combat/view prefixes from the supplied table.

The seven variable strings and final flag must end exactly at the already
verified PV model field. Alternate mode prefixes are independently located;
statistics are never copied from a different mode or inferred from item names.
"""
import gzip,hashlib,json,math,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def decode(raw,item):
 def text(pos):
  n=struct.unpack_from('<H',raw,pos)[0]
  if n>2048 or pos+2+n*2>len(raw):raise ValueError('Invalid weapon string bound')
  return raw[pos+2:pos+2+n*2].decode('utf-16le'),pos+2+n*2
 start=int(item['sourceOffset']);model=int(item['sourceModelOffset'])
 state,pos=text(start+15);pos+=4;icon,base=text(pos)
 def prefix(base):
  ammo,q=text(base+126)
  if ammo not in ['','Bullet','Melee','Explode']:raise ValueError('Invalid native damage type')
  normal=struct.unpack_from('<f',raw,q)[0];normal_offset=q;explosion,common=text(q+4)
  if explosion not in ['','Explode']:raise ValueError('Invalid splash damage type')
  pos=common+114;strings=[]
  for _ in range(7):value,pos=text(pos);strings.append(value)
  if pos+1!=model:raise ValueError('Prefix must meet its exact native model boundary')
  scale,*position=struct.unpack_from('<4f',raw,common+74)
  capacity=struct.unpack_from('<H',raw,common+35)[0];interval=struct.unpack_from('<I',raw,base+10)[0]
  splash=struct.unpack_from('<f',raw,common)[0];pellets=raw[common+73]
  if not (1<=capacity<=500 and 1<=interval<=10000 and 1<=pellets<=32 and .01<=scale<=10):raise ValueError('Invalid combat field bounds')
  if not all(math.isfinite(n) for n in [normal,splash,*position]) or min(normal,splash)<0:raise ValueError('Invalid float combat values')
  return dict(sourceId=int(item['sourceId']),sourceKind=struct.unpack_from('<I',raw,start+4)[0],sourceOffset=start,prefixOffset=base,commonOffset=common,normalDamageOffset=normal_offset,modelOffset=model,
   fireIntervalMs=interval,capacity=capacity,baseDamage=normal,splashDamage=splash,pellets=pellets,modelScale=scale,
   godotPosition=[position[0],position[1],-position[2]],sourcePosition=position,projectile=strings[0],ammoName=strings[1],tracerFx=strings[2],underwaterFx=strings[3],impactFx=strings[4],pvSideFx=strings[5],hhSideFx=strings[6],
   damageType=ammo,splashType=explosion,nativeCounter37=struct.unpack_from('<H',raw,common+37)[0],nativeCounter39=struct.unpack_from('<H',raw,common+39)[0],animationType=raw[common+72],
   alternatePrefix=base!=original_base)
 original_base=base
 try:return prefix(base)
 except (ValueError,UnicodeDecodeError,struct.error) as original:
  candidates=[]
  # Some native records contain a second weapon mode without a repeated item
  # header. Its damage-type field and seven strings still have exact bounds.
  for candidate in range(max(start,model-2048),model-240):
   if raw[candidate+126:candidate+140]!=b'\x06\x00'+ 'Bullet'.encode('utf-16le'):continue
   try:candidates.append(prefix(candidate))
   except (ValueError,UnicodeDecodeError,struct.error):pass
  if len(candidates)!=1:raise ValueError('Ambiguous native alternate weapon prefix: '+str(item['id'])) from original
  return candidates[0]
def run():
 raw=gzip.decompress((ROOT/'docs/pc_sources_017/weapondata.dat.gz').read_bytes());library=json.loads((ROOT/'godot/assets/library/weapons.json').read_text());items={}
 from import_weapon_fx_027 import weapon_rows
 verified=weapon_rows(raw,library['items'],library['models'])
 for item in library['items']:
  row=decode(raw,item);row['sourceModel']=verified[item['id']]['sourceModel'];items[item['id']]=row
 assert len(items)==903
 result={'schemaVersion':1,'source':'root/wt_attributes/weapondata.dat','sourceSha256':hashlib.sha256(raw).hexdigest(),'items':items,
  'fieldOffsets':{'fireIntervalMs':'prefix +10 uint32 milliseconds','capacity':'common +35 uint16 rounds','baseDamage':'float32 before the splash damage-type string','splashDamage':'common +0 float32','pellets':'common +73 byte','modelScale':'common +74 float32','sourcePosition':'common +78 three float32','strings':'common +114 seven UTF-16LE strings, then one native flag byte, then the verified PV model field'},
  'scope':'Literal native base combat fields and model position. Armor, distance modifiers, recoil and alternate-mode input behavior are not certified by this data.',
  'unresolved':['nativeCounter37/39 meaning and reserve-ammo policy','Unmapped combat/armor/recoil fields','Other native alternate-mode controls']}
 (ROOT/'godot/assets/weapons/native-rules.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
 proof={k:result[k] for k in ['source','sourceSha256','fieldOffsets','scope','unresolved']};proof.update(records=len(items),alternatePrefixes=[{'id':k,'sourceId':r['sourceId'],'offset':r['prefixOffset'],'modelOffset':r['modelOffset']} for k,r in items.items() if r['alternatePrefix']],capacityRange=[min(r['capacity'] for r in items.values()),max(r['capacity'] for r in items.values())],intervalMsRange=[min(r['fireIntervalMs'] for r in items.values()),max(r['fireIntervalMs'] for r in items.values())],examples=[dict(id=item['id'],name=item['name'],**items[item['id']]) for item in library['items'] if item['name'] in ['DE-50','AKEI-47 CLASSIC','FullMoon','SUPAS PT','I-115 GL','MK-5 G','EM-32','EM-72A5 LAW']])
 (ROOT/'docs/weapon-rules-source-028.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n');print('NATIVE_WEAPON_RULES',len(items),'alternate prefixes',len(proof['alternatePrefixes']))
if __name__=='__main__':run()
