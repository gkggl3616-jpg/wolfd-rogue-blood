"""Decode every 140-byte source set and expose only complete priced packages."""
import collections,gzip,hashlib,json,pathlib,struct
from import_game_rules import read_item_text
ROOT=pathlib.Path(__file__).resolve().parents[1]
def run():
 shop_path=ROOT/'godot/assets/items/shop.json';shop=json.loads(shop_path.read_bytes());prices=gzip.decompress((ROOT/'docs/pc_sources_017/shopdata.dat.gz').read_bytes());sets_raw=gzip.decompress((ROOT/'docs/pc_sources_018/setitemdata.dat.gz').read_bytes());assert len(sets_raw)%140==0
 source_prices={struct.unpack_from('<I',prices,p+4)[0]:p for p in range(0,len(prices),359)};text={r['id']:r for r in read_item_text(gzip.decompress((ROOT/'docs/pc_sources_018/exitemtext.dat.gz').read_bytes()))};labels=json.loads((ROOT/'godot/assets/presentation/catalog.json').read_bytes())['items'];portraits=json.loads((ROOT/'godot/assets/ui/character-portraits.json').read_bytes())['portraits']
 original={}
 for file,key in [('library/weapons.json','items'),('library/characters.json','characters'),('library/visuals.json','tattoos'),('items/power.json','items')]:
  for row in json.loads((ROOT/'godot/assets'/file).read_bytes())[key]:original[str(row['id'])]=row
 for row in json.loads((ROOT/'godot/assets/items/rules.json').read_bytes())['items']:original[str(int(row['id']))]=row
 by_source=collections.defaultdict(list)
 for key,item in shop['items'].items():
  row=original.get(key,{})
  if row and row.get('available',True) and row.get('engineImported',True):
   name=labels.get(key,{}).get('name',row.get('name',key));icon=portraits.get(key,{}).get('asset',row.get('icon',row.get('texture','')))
   by_source[item['sourceId']].append({'id':key,'kind':item['kind'],'name':name,'icon':icon})
 entries=[];proof=[];related=collections.defaultdict(list)
 for pos in range(0,len(sets_raw),140):
  ident=struct.unpack_from('<I',sets_raw,pos)[0];members=[];unsupported=[]
  for i in range(17):
   item,term=struct.unpack_from('<II',sets_raw,pos+4+i*8)
   if not item:continue
   choices=by_source[item]
   if len(choices)!=1:unsupported.append(item)
   else:members.append({**choices[0],'sourceItemId':item,'sourceTerm':term})
  offers=[];price_offset=source_prices.get(ident)
  if price_offset is not None:
   for currency,offset in shop['currencyOffsets'].items():
    values=list(struct.unpack_from('<6i',prices,price_offset+offset));active=[(i,v) for i,v in enumerate(values) if 0<v<1000000000]
    if active:
     index,price=active[0];offers.append({'currency':currency,'price':price,'sourceOptionIndex':index,'sourceOffset':price_offset})
  complete=bool(members) and not unsupported
  row={'id':'set-'+str(ident),'sourceId':ident,'name':text.get(ident,{}).get('name') or ((members[0]['name']+' Seti') if members else 'Özel Set'),'description':text.get(ident,{}).get('description',''),'members':members,'offers':offers,'available':complete and bool(offers),'sourceOffset':pos,'unsupportedMembers':unsupported,'nameBasis':'original item text' if text.get(ident,{}).get('name') else 'descriptive name from the actual first component; original set caption unavailable'}
  proof.append(row)
  if row['available']:
   entries.append(row)
   for member in members:related[member['id']].append(row['id'])
 for key,item in shop['items'].items():
  item['relatedSets']=related.get(key,[])
  item['pricingStatus']='priced' if item['offers'] else ('included_in_priced_set' if item['relatedSets'] else ('source_prices_zero' if item['sourceOffsets'] else 'source_record_absent'))
 shop_path.write_text(json.dumps(shop,ensure_ascii=False,indent=2)+'\n')
 out=ROOT/'godot/assets/items/sets.json';out.write_text(json.dumps({'schemaVersion':1,'items':entries,'sourceSha256':hashlib.sha256(sets_raw).hexdigest(),'recordBytes':140,'sourceRecords':len(sets_raw)//140,'purchaseScope':'Original complete package at its source price; one permanent local copy per listed component. Original term fields are evidence, not implemented rental expiry.'},ensure_ascii=False,indent=2)+'\n')
 (ROOT/'docs/pc_sources_018').mkdir(exist_ok=True);(ROOT/'docs/pc_sources_018/setitemdata.dat.gz').write_bytes(gzip.compress(sets_raw,mtime=0))
 (ROOT/'docs/source-set-audit-018.json.gz').write_bytes(gzip.compress(json.dumps({'records':proof,'pricingStatusCounts':dict(collections.Counter(r['pricingStatus'] for r in shop['items'].values())),'unpricedSourceItemsWithCompletePricedSets':sum(not r['offers'] and bool(r['relatedSets']) for r in shop['items'].values())},ensure_ascii=False).encode(),mtime=0))
 print('SOURCE_SETS',len(proof),'decoded',len(entries),'complete and priced',sum(not r['offers'] and bool(r['relatedSets']) for r in shop['items'].values()),'previously unpriced items have a complete priced set')
if __name__=='__main__':run()
