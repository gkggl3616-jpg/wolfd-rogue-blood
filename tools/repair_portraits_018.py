"""Resolve exact native card identities across character/exitem and large atlases."""
import hashlib,json,pathlib,re,collections
ROOT=pathlib.Path(__file__).resolve().parents[1]
def norm(s):return re.sub('[^a-z0-9]','',s.lower())
ALIASES={'adrianase':['adriana_special_edition'],'angelase':['angela_special_edition'],'pedrose':['pedro_special_edition'],'christopherse':['christopher_special_edition'],'mariense':['marien_arnault_special_edition'],'reinhardse':['reinhard_schneider_special_edition'],'linse':['linmeiling_special_edition','lin_meiling_special_edition'],'moshinse':['moshin_special_edition'],'tomitase':['tomita_yasuko_se'],'sarah':['sarah_linda'],'kate':['kate_blume'],'moshin':['hamadah_bin_shabah','moshin'],'linesc':['linmeiling_soccer'],'moshinesc':['moshin_soccer'],'mattbakerse':['matt_se'],'kateblumese':['kate_se'],'sarahlandse':['sarah_se'],'sarahlindase':['sarah_se'],'alexsandrodelriccardose':['riccardo_se'],'geremisuit':['geremi song_suit']}
def build():
 textures=json.loads((ROOT/'godot/assets/ui/catalog.json').read_bytes())['textures'];chars=json.loads((ROOT/'godot/assets/library/characters.json').read_bytes())['characters'];old=json.loads((ROOT/'godot/assets/ui/character-portraits.json').read_bytes())['portraits'];index=collections.defaultdict(list)
 for key,entry in textures.items():
  if not key.startswith(('wt_interface/item/character/','wt_interface/item/exitem/')):continue
  index[norm(pathlib.PurePosixPath(key).stem.removesuffix('_n'))].append((key,entry))
 result={};derived=[]
 for char in chars:
  if not char.get('available'):continue
  model=pathlib.PurePosixPath(char['human']['source'].replace('\\','/')).stem.removeprefix('WT_').removeprefix('wt_').removesuffix('_ch');keys=[norm(char['name']),norm(model)]+[norm(s) for s in ALIASES.get(norm(char['name']),[])]
  candidates=[]
  for name in keys:
   if index.get(name):candidates=index[name];break
  if candidates:
   candidates.sort(key=lambda pair:('/character/' not in pair[0],'/large/' not in pair[0],pair[0]));key,entry=candidates[0];scale=2 if '/large/' in key else 1
   region=[0,0,min(210*scale,int(entry['width'])),min(75*scale,int(entry['height']))]
   result[char['id']]={'asset':entry['asset'],'region':region,'kind':'source_icon','sourceTexture':key,'sourceSha256':entry['sourceSha256'],'model':char['human']['asset'],'modelSha256':char['human']['sha256'],'identityBasis':'Exact normalized source model/name or explicit same-character variant alias; large and normal atlas duplicates ranked, not rejected.'}
  else:
   result[char['id']]={**old[char['id']],'kind':'rendered_character_card','region':[0,0,420,150],'team':char['sourceTeam'],'originalArt':False};derived.append(char['id'])
 return {'portraits':result,'note':'Original source cards where exact identities resolve. Remaining cards are real model renders over team-colour backgrounds, never another character.'}
def run():
 data=build();result=data['portraits'];derived=[k for k,v in result.items() if v['kind']!='source_icon']
 (ROOT/'godot/assets/ui/character-portraits.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 (ROOT/'docs/portrait-bindings-018.json').write_text(json.dumps({'sourceCards':len(result)-len(derived),'derivedCards':derived,'allAdmittedCharacters':len(result),'bindings':result},ensure_ascii=False,indent=2)+'\n')
 print('PORTRAITS',len(result)-len(derived),'original',len(derived),'derived')
if __name__=='__main__':run()
