"""Decode source performance records and swing-trail bindings; preserve unknown fields explicitly."""
import collections,concurrent.futures,hashlib,json,pathlib,re,struct,sys,unicodedata
from pc_source_cache import PcSourceCache
from import_game_rules import read_item_text
from convert_character import texture_png
ROOT=pathlib.Path(__file__).resolve().parents[1];rawdir=ROOT/'../scratch/pc-selected'
raw=(rawdir/'character&tattoo.dat').read_bytes();assert len(raw)%17==0
performance=collections.defaultdict(list)
for p in range(0,len(raw),17):
 id=struct.unpack_from('<H',raw,p)[0];performance[id].append({'offset':p,'flags':list(raw[p+2:p+9]),'values':list(raw[p+9:p+16]),'kind':raw[p+16]})
text={r['id']:r for r in read_item_text((rawdir/'exitemtext.dat').read_bytes())}
# Two field meanings are cross-checked against all ten explicit claw descriptions.
for id,reach,damage in [(16011,5,10),(16012,0,15),(16013,5,5),(16014,5,5),(16015,5,20),(16016,5,7),(16017,0,10),(16018,5,10),(16019,10,0),(16020,10,20)]:
 assert any(r['kind']==54 and r['values'][:2]==[reach,damage] for r in performance[id]),id
kinds={51:'body',52:'left',53:'right',54:'claw'}
def selected(id,kind):
 rows=[r for r in performance[id] if r['kind']==kind];values={tuple(r['values'][:2]) for r in rows}
 return rows[0] if len(values)==1 else None

def normalized(name):
 name=name.lower().replace('ı','i');name=re.sub(r'\((sol|sağ|sag|sırt|sirt|gövde|govde)\)','',name);name=name.replace('dövmesi','').replace('dövme','')
 return re.sub('[^a-z0-9]','',unicodedata.normalize('NFKD',name).encode('ascii','ignore').decode())

def named_percent(description,labels):
 text=' '.join(description.split())
 for label in labels:
  m=re.search(label+r'\s*\+?\s*(?:%\s*(\d+)|(\d+)\s*%)',text,re.I)
  if m:return int(m[1] or m[2])
 return 0

catalog=json.loads((ROOT/'godot/assets/library/visuals.json').read_text());evidence=[]
for row in catalog['tattoos']:
 id=row['sourceId'];family={12:'body',20:'left',21:'right'}[id//1000];tag={'body':51,'left':52,'right':53}[family]
 assert row['role'] in ['unknown',family]
 matching=[r for r in performance[id] if r['kind'] in kinds]
 conflicts=[r for r in matching if kinds[r['kind']]!=family]
 row['sourceKindConflicts']=conflicts
 matching=[r for r in matching if r['kind']==tag]
 row['role']=family;row['setKey']=normalized(row['name']);row['roleEvidence']={'basis':'source performance kind 51/52/53, with ID family validated against every named source slot','performanceOffsets':[r['offset'] for r in matching]}
 desc=text.get(id,{}).get('description',row.get('description',''));row['description']=desc
 stats=selected(id,tag);row['sourcePerformance']={'records':matching,'unknownValueIndices':[2,3,4,5,6]}
 row['appliedBonuses']={'rangePercent':stats['values'][0] if stats else 0,'damagePercent':stats['values'][1] if stats and stats['values'][1]!=255 else 0,'healthPercent':named_percent(desc,['Fazladan YP','Fazladan YP Tutma']),'speedPercent':named_percent(desc,['Kurt Hızı']),'gpPercent':named_percent(desc,['Fazladan GP',r'(?<!\w)GP']),'goldPercent':named_percent(desc,['Altın'])}
 row['bonusesImplemented']=False;row['bonusScope']='Source range/damage fields plus explicitly percent-labelled HP/speed/GP/gold description values; other PC modifiers pending; additive stacking is mobile adaptation.'
 evidence.append({'id':id,'role':family,'binaryRoleRecords':len(matching),'applied':row['appliedBonuses']})
(ROOT/'godot/assets/library/visuals.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
# Whole source trail record: item ID + five bytes + texture + flag + four source bones + three optional source strings.
b=(rawdir/'abilityswingtrail.dat').read_bytes();pos=0;trails={}
def string():
 global pos
 n=struct.unpack_from('<H',b,pos)[0];pos+=2;assert n<4096;s=b[pos:pos+2*n].decode('utf-16le');pos+=2*n;return s
while pos<len(b):
 start=pos;id=struct.unpack_from('<H',b,pos)[0];config=list(b[pos+2:pos+7]);pos+=7
 texture=string();flag=b[pos];pos+=1;bones=[string() for _ in range(4)];tail=[string() for _ in range(3)]
 assert pos<=len(b) and all(len(name)<256 for name in bones)
 trails[id]={'sourceOffset':start,'texture':texture,'bones':bones,'configuration':config,'flag':flag,'tail':tail}
assert pos==len(b)
source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',sys.argv[1]);ui=json.loads((ROOT/'godot/assets/ui/catalog.json').read_text())['textures'];out=ROOT/'godot/assets/items/claws';out.mkdir(exist_ok=True)
claws=[];powers=json.loads((ROOT/'godot/assets/items/power.json').read_text())
for id,rows in performance.items():
 if not any(r['kind']==54 for r in rows):continue
 stat=selected(id,54)
 if not stat or id not in text:continue
 description=text[id]['description'];entry={'id':str(id),'sourceId':id,'name':text[id]['name'],'description':description,'category':'claw','slot':'claw','localPrice':0,'consumable':False,'offlineAvailable':True,'mobileTuning':{'damagePercent':stat['values'][1],'rangePercent':stat['values'][0]},'sourceStatsFullyImplemented':False,'sourcePerformance':rows,'iconBasis':'source_claw_trail_texture'}
 # Exitem card icon is selected by its literal source ID only when available.
 icon=ui.get('wt_interface/item/bullets/wolf.dtx',{}).get('asset','')
 entry['icon']=icon
 trail=trails.get(id)
 if trail:
  rawtex=source.get('root/'+trail['texture'].replace('\\','/').lower());path=out/(str(id)+'-trail.png');path.write_bytes(texture_png(rawtex));entry['trail']={**trail,'asset':'res://'+str(path.relative_to(ROOT/'godot')),'sourceSha256':hashlib.sha256(rawtex).hexdigest(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
  entry['icon']=entry['trail']['asset']
 claws.append(entry)
# Keep existing local support/energy/dash items and replace only previously decoded source claws.
default=trails[16001];default_key='root/'+default['texture'].replace('\\','/').lower()
if default_key in source.lookup:
 raw_default=source.get(default_key);default_path=out/'default-trail.png';default_path.write_bytes(texture_png(raw_default));powers['defaultClawTrail']={**default,'asset':'res://'+str(default_path.relative_to(ROOT/'godot')),'sourceSha256':hashlib.sha256(raw_default).hexdigest(),'sha256':hashlib.sha256(default_path.read_bytes()).hexdigest()}
else:
 powers['defaultClawTrail']={};powers['missingDefaultTrailSource']=default['texture']
old={r['id'] for r in claws};powers['items']=[r for r in powers['items'] if r['id'] not in old]+claws
powers['sourcePerformanceSha256']=hashlib.sha256(raw).hexdigest();powers['sourceTrailSha256']=hashlib.sha256(b).hexdigest()
(ROOT/'godot/assets/items/power.json').write_text(json.dumps(powers,ensure_ascii=False,indent=2)+'\n')
(ROOT/'docs/item-source-facts-015.json').write_text(json.dumps({'performanceSourceSha256':hashlib.sha256(raw).hexdigest(),'recordsDecoded':len(raw)//17,'recordBytes':17,'recordLayout':{'itemId':[0,2],'unknownFlags':[2,9],'rangePercent':9,'damagePercent':10,'unknownValues':[11,16],'kind':16},'kindEvidence':{'51':'body','52':'left','53':'right','54':'claw'},'tattoos':evidence,'claws':[r['sourceId'] for r in claws],'sourceTrailRecords':len(trails),'allPcModifiersDecoded':False},ensure_ascii=False,indent=2)+'\n')
print('TATTOOS',len(evidence),'CLAW_ITEMS',len(claws),'TRAILS',len(trails),flush=True)
