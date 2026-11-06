"""Join original 359-byte shop rows to imported items, without inventing missing prices.

Currency columns are identified by the gold/cash support-item pairs, weapon
cash prices and wolf-coin price column. Pack/duration flags are retained;
the offline purchase grants one permanent local copy (explicit adaptation).
"""
import collections,gzip,hashlib,json,pathlib,struct
ROOT=pathlib.Path(__file__).resolve().parents[1]
def run(folder):
 raw=(folder/'shopdata.dat').read_bytes();assert len(raw)%359==0
 records=collections.defaultdict(list)
 for pos in range(0,len(raw),359):
  row=raw[pos:pos+359];serial,item=struct.unpack_from('<II',row)
  records[item].append({'offset':pos,'serial':serial,'flags':list(row[8:17]),'gold':list(struct.unpack_from('<6i',row,65)),'cash':list(struct.unpack_from('<6i',row,90)),'kp':list(struct.unpack_from('<6i',row,290)),'rawHex':row.hex()})
 chars=json.loads((ROOT/'godot/assets/library/characters.json').read_bytes())['characters']
 table=(ROOT/'../scratch/pc-selected/characterdata.dat').read_bytes();assert len(table)%21==0
 bindings=collections.defaultdict(set)
 for pos in range(0,len(table),21):
  item=struct.unpack_from('<H',table,pos)[0];form=table[pos+6];model=struct.unpack_from('<H',table,pos+9)[0]
  if form==0:bindings['Model'+str(model)].add(item)
 weapons=json.loads((ROOT/'godot/assets/library/weapons.json').read_bytes())['items']
 tattoos=json.loads((ROOT/'godot/assets/library/visuals.json').read_bytes())['tattoos']
 powers=json.loads((ROOT/'godot/assets/items/power.json').read_bytes())['items']
 ability=json.loads((ROOT/'godot/assets/items/rules.json').read_bytes())['items']
 entries={};missing=[];ambiguous=[]
 for kind,rows in [('weapon',weapons),('character',chars),('tattoo',tattoos),('power',powers+ability)]:
  for entry in rows:
   if kind=='character':
    ids=bindings[entry['human']['sourceDefinition']];source_id=entry.get('sourceItemId',next(iter(ids)) if len(ids)==1 else 0)
   else:source_id=entry.get('sourceId',entry['id'])
   source_id=int(source_id);candidates=records[source_id]
   offers=[]
   # Conflicting duplicate rows do not silently choose a cheaper record.
   for currency in ['gold','cash','kp']:
    values={tuple(r[currency]) for r in candidates}
    if len(values)!=1:
     if len(values)>1:ambiguous.append({'id':entry['id'],'currency':currency,'sourceId':source_id})
     continue
    prices=next(iter(values));positive=[(i,v) for i,v in enumerate(prices) if 0<v<1000000000]
    if positive:
     index,price=positive[0];offers.append({'currency':currency,'price':price,'sourceOptionIndex':index,'sourceOffset':candidates[0]['offset']})
   entries[str(entry['id'])]={'id':str(entry['id']),'sourceId':source_id,'kind':kind,'offers':offers,'sourceOffsets':[r['offset'] for r in candidates]}
   if not offers:missing.append(str(entry['id']))
 out=ROOT/'godot/assets/items/shop.json'
 out.write_text(json.dumps({'schemaVersion':1,'currencyPolicy':{'unlimited':['cash','kp'],'scope':'User-requested offline allowance; not a claim of original PC account currency. Gold and GP remain finite.'},'sourceSha256':hashlib.sha256(raw).hexdigest(),'recordBytes':359,'recordCount':len(raw)//359,'currencyOffsets':{'gold':65,'cash':90,'kp':290},'purchaseScope':'One permanent local copy per purchase at the first positive source price. Original pack sizes, duration and promotional flags are preserved as evidence, not represented as decoded.','items':entries},ensure_ascii=False,indent=2)+'\n')
 proof={'sourceSha256':hashlib.sha256(raw).hexdigest(),'recordCount':len(raw)//359,'recordBytes':359,'items':len(entries),'pricedItems':sum(bool(e['offers']) for e in entries.values()),'unpricedItems':missing,'conflictingPrices':ambiguous,'allPcPricingFlagsDecoded':False,'currencyEvidence':{'gold':'19001 and 19501 gold item pairs','cash':'standard weapon/claw duration price block','kp':'separate original wolf-coin price column'},'localPurchaseScope':'One permanent offline item, not an original duration/pack entitlement','records':dict(records)}
 (ROOT/'docs/shop-source-017.json.gz').write_bytes(gzip.compress(json.dumps(proof,ensure_ascii=False,sort_keys=True).encode(),mtime=0))
 (ROOT/'docs/pc_sources_017/shopdata.dat.gz').write_bytes(gzip.compress(raw,mtime=0))
 print('SHOP_IMPORT',len(entries),'items',proof['pricedItems'],'priced',len(missing),'unpriced',len(ambiguous),'ambiguous')
if __name__=='__main__':
 import sys
 run(pathlib.Path(sys.argv[1]))
