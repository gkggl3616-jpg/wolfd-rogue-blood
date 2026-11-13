"""User-facing names and verified tattoo fields, preserving original identities."""
import json,pathlib,re,hashlib,gzip,struct,collections
from presentation_names_018 import tattoo_alias
ROOT=pathlib.Path(__file__).resolve().parents[1]
FULL={'pedro':'Pedro Gomes','christopher':'Christopher Smith','adriana':'Adriana Tenorio','angela':'Angela Mao','marien':'Marien Arnault','reinhard':'Reinhard Schneider','lin':'Lin Meiling','linmeiling':'Lin Meiling','moshin':'Hamadah bin Shabah','hamadah':'Hamadah bin Shabah','geremi':'Geremi Song','yigit':'Yiğit Demir','yigitdemir':'Yiğit Demir','sarah':'Sarah Linda','tomita':'Tomita Yasuko','matt':'Matt Baker','kate':'Kate Blume','riccardo':'Alexsandro Del Riccardo'}
SUFFIX={'se':'Özel Versiyon','special edition':'Özel Versiyon','adult':'Yetişkin Versiyon','tsc':'Diriliş','hero':'Kahraman','suit':'Takım Elbise','summer':'Yaz','jungle':'Orman','reboot':'Diriliş','re':'Diriliş','legend':'Efsane','legendary':'Efsane','christmas':'Yılbaşı','winter':'Kış','soccer':'Futbol','military':'Askerî','halloween':'Cadılar Bayramı','desert':'Çöl','spring':'Bahar','udt':'UDT','thanksgiving':'Şükran Günü','casual':'Günlük','sfmovie':'Bilim Kurgu','worldwar':'Dünya Savaşı','valentine':'Sevgililer Günü','swimsuit':'Mayo','expansion':'Genişletilmiş'}
def display_character(row):
 raw=row['name'];name=re.sub(r'[_]+',' ',raw).strip();lower=name.lower()
 if row['id']=='pair-model0':return 'Pedro - Temel (Kırmızı Takım)'
 if row['id']=='pair-model1':return 'Christopher - Temel (Mavi Takım)'
 if lower.startswith('gm '):return 'OG '+('Kadın' if 'woman' in lower else 'Erkek')+' Karakteri ('+('Kırmızı' if row['sourceTeam']=='red' else 'Mavi')+' Takım)'
 # Standard source families have published full names; keep their actual version.
 first=lower.split()[0];base=FULL.get(first)
 if not base:
  for key in sorted(FULL,key=len,reverse=True):
   if lower.startswith(key) and lower[len(key):] in ['se','re']:first=key;base=FULL[key];name=key+' '+lower[len(key):];break
 if base:
  remainder=name[len(first):].strip()
  for component in base.split()[1:]:remainder=re.sub(r'^'+re.escape(component)+r'\b\s*','',remainder,flags=re.I)
  parts=[]
  for part in remainder.split():parts.append(SUFFIX.get(part.lower(),part))
  return base+(' · '+' '.join(parts) if parts else '')
 for key,value in sorted(SUFFIX.items(),key=lambda kv:-len(kv[0])):name=re.sub(r'\b'+re.escape(key)+r'\b',value,name,flags=re.I)
 return name

def mode_name(name):
 qualifiers=[];remaining=name
 prefix=''
 if remaining.lower().startswith('pride ladder '):prefix='Klan Maçı · ';remaining=remaining[len('Pride Ladder '):]
 elif remaining.lower().startswith('ladder_'):prefix='Rekabetçi · ';remaining=remaining[len('Ladder_'):]
 families=[('TUTORIAL_FLAG','Öğretici Modu'),('Ex-Conquest','EX-İşgal Modu'),('Deathmatch','Ölüm Oyunu Modu'),('Conquest','İşgal Modu'),('Destruction','Yıkım Modu'),('Ice Hold','Uyku Modu'),('Wolfhunt','Kurt Avı Modu'),('Wolf Rush','Kurt Akını Modu'),('Match Point','Puan Maçı'),('Annihilation','İmha Modu'),('FreeForAll','Herkes Tek Modu')]
 label=None
 for source,target in families:
  if remaining.lower().startswith(source.lower()):label=target;remaining=remaining[len(source):];break
 if label is None:raise ValueError('Untranslated original mode: '+name)
 translations=[('Human vs Human','İnsanlara Karşı İnsanlar'),('Wolf vs Wolf','Kurtlara Karşı Kurtlar'),('Wolf vs Human','Kurtlara Karşı İnsanlar'),('All vs All','Herkes'),('Counter_Attack','Karşı Saldırı'),('NoHeavy','Ağır Silahsız'),('Heavy Weapon','Ağır Silah'),('Knife Mode','Bıçak'),('Pistol Mode','Tabanca'),('Sniper Mode','Keskin Nişancı'),('Snipe Mode','Keskin Nişancı'),('grenade','El Bombası'),('Normal',''),('Hero','Kahraman'),('Heavy','Ağır Silah'),('Revolt','İsyan'),('Dominate','Hâkimiyet'),('Arcade','Akın'),('Boss','Bölüm Sonu Canavarı')]
 for source,target in translations:remaining=re.sub(re.escape(source),target,remaining,flags=re.I)
 remaining=' · '.join(part.strip() for part in remaining.strip(' _').split('_') if part.strip())
 if remaining.isdigit():remaining+=' Dalga'
 return prefix+label+(' · '+remaining if remaining else '')

def run():
 chars=json.loads((ROOT/'godot/assets/library/characters.json').read_bytes())['characters'];visuals_path=ROOT/'godot/assets/library/visuals.json';visuals=json.loads(visuals_path.read_bytes());aliases={};facts=[]
 for row in chars:aliases[row['id']]={'name':display_character(row),'originalName':row['name'],'basis':'source family/version + published full character name; default reference screenshots; GM translated as Oyun Görevlisi'}
 textures=json.loads((ROOT/'godot/assets/ui/catalog.json').read_bytes())['textures']
 for row in visuals['tattoos']:
  source=row.get('sourceTexture','').replace('\\','/').lower();stem=pathlib.PurePosixPath(source).stem
  name,group=tattoo_alias(row)
  legacy={12236:12955,20096:20803,21112:21803}
  if row['sourceId'] in legacy:row['canonicalId']='tattoo-'+str(legacy[row['sourceId']]);row['visualAliasBasis']='Older source record shares the exact gold OG illustration; retain ownership, show one card per region.'
  aliases[row['id']]={'name':name,'originalName':row['name'],'basis':'localized original texture family, color and verified body region; official historical caption not established for every variant'}
  row['setKey']=group
  if stem in ['tattoo_gm','tattoo_gm_gl','tattoo_gm_db','tattoo_gm_dr','tattoo_gm_dp']:
   prefix={'body':'b','left':'l','right':'r'}[row['role']];key='wt_interface/item/power/'+stem.replace('tattoo_', 'tattoo_'+prefix+'_',1)+'.dtx';art=textures[key]
   row['uvTranspose']=row['role']=='body';row['renderPriority']=1;row['icon']=art['asset'];row['iconRegion']=[0,0,210,75];row['iconSource']={'path':key,'sha256':art['sourceSha256'],'basis':'Original distinct body/left/right shop card, not the shared tattoo skin.'}
  records=row.get('sourcePerformance',{}).get('records',[])
  values={tuple(r['values']) for r in records}
  if len(values)==1:
   v=next(iter(values));bonuses=row.get('appliedBonuses',{});bonuses.update(rangePercent=v[0],damagePercent=v[1],transformPercent=v[2],healthPercent=v[3],armorPercent=v[4],speedPercent=v[5]);bonuses.pop('stunRecoveryPercent',None);row['appliedBonuses']=bonuses
   row['sourcePerformance']['unknownValueIndices']=[6]
   facts.append({'id':row['id'],'rawValues':list(v),'applied':bonuses})
  # Missing source descriptions still show actual decoded, non-invented values.
  if not row.get('description') or row['name'].lower().startswith(('tattoo','tatoo')):
   name=aliases.get(row['id'],{}).get('name',row['name']);row['description']=name+'\nKurt formunda ilgili bölgeye takılır. Özellikler kaynak eşya kaydından gösterilir.'
 visuals_path.write_text(json.dumps(visuals,ensure_ascii=False,indent=2)+'\n')
 stats={};raw=gzip.decompress((ROOT/'docs/pc_sources_018/character&tattoo.dat.gz').read_bytes());by_id=collections.defaultdict(list)
 for offset in range(0,len(raw),17):
  if raw[offset+16]==100:by_id[struct.unpack_from('<H',raw,offset)[0]].append({'offset':offset,'flags':list(raw[offset+2:offset+9]),'values':list(raw[offset+9:offset+16])})
 shop=json.loads((ROOT/'godot/assets/items/shop.json').read_bytes())['items']
 for row in chars:
  records=by_id[shop.get(row['id'],{}).get('sourceId',-1)];forms={}
  for form,flag in [('human',0),('wolf',1)]:
   matches=[r for r in records if r['flags'][2]==flag];values={tuple(r['values']) for r in matches}
   if len(values)==1:
    record=matches[0];forms[form]={'values':record['values'],'gpPercent':record['flags'][3],'goldPercent':record['flags'][5],'sourceOffsets':[r['offset'] for r in matches]}
  if forms:stats[row['id']]=forms
 modes=json.loads((ROOT/'godot/assets/maps/catalog.json').read_bytes())['modes']
 out=ROOT/'godot/assets/presentation';out.mkdir(exist_ok=True)
 catalog={'schemaVersion':1,'characterStats':stats,'items':aliases,'modes':{str(int(row['id'])):{'name':mode_name(row['sourceName']),'sourceName':row['sourceName']} for row in modes},'statLabels':{'rangePercent':'Kurt Saldırı Menzili','damagePercent':'Saldırı Hasarı','transformPercent':'Kurt Dönüşüm Hızı','healthPercent':'Fazladan YP','armorPercent':'Kurt Zırh Puanı','speedPercent':'Kurt Hızı','gpPercent':'GP','goldPercent':'Altın'}}
 (out/'catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
 proof={'sourcePerformanceSha256':hashlib.sha256(raw).hexdigest(),'fields':{'0':'rangePercent','1':'damagePercent','2':'transformPercent','3':'healthPercent','4':'armorPercent','5':'speedPercent','6':'unresolved'},'evidence':{'rangeDamage':'Existing ten exact source claw descriptions; byte 255 is a literal +255, not zero; user OG screenshot totals 765.','transformHealth':'Exact source rows 12011,12019,12020,12021,12023,12024 match their original transformation/HP descriptions.','armorSpeed':'Source dragon texture record 12031 has 3/3/3/3/9/3; modern dragon reference independently identifies armor 9 and speed 3. Source six-stat icons and OG screenshot provide a second check.','stacking':'Additive local implementation; original stacking/caps not fully decoded.'},'tattoos':facts,'scope':'Range/damage/health/speed apply in local matches; transformation controls form action lock. Armor is displayed from the source; body-part defence and freeze mechanics are not a complete PC simulation.'}
 (ROOT/'docs/item-stat-fields-018.json.gz').write_bytes(gzip.compress(json.dumps(proof,ensure_ascii=False).encode(),mtime=0))
 print('PRESENTATION',len(chars),'characters',len(catalog['modes']),'translated modes',sum(k.startswith('tattoo') for k in aliases),'localized tattoos',len(facts),'source-stat records')
if __name__=='__main__':run()
