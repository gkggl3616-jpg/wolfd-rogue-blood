"""Bind every tattoo to its exact original exitemdata shop card and source role."""
import gzip,hashlib,json,pathlib,struct,sys
from pc_source_cache import PcSourceCache
from convert_character import texture_png
ROOT=pathlib.Path(__file__).resolve().parents[1]
def run(cache):
 raw=(ROOT/'../scratch/pc-selected/exitemdata.dat').read_bytes();pos=0;rows={}
 while pos<len(raw):
  start=pos;ident=struct.unpack_from('<I',raw,pos)[0];pos+=57;art=[]
  for _ in range(2):
   n=struct.unpack_from('<H',raw,pos)[0];pos+=2;assert n<1000
   path=raw[pos:pos+2*n].decode('utf-16le').replace('\\','/').lower();pos+=2*n
   width,height=struct.unpack_from('<HH',raw,pos);pos+=4;art.append({'path':path,'size':[width,height]})
  if ident in rows:assert rows[ident]['art']==art, ('Conflicting source card',ident)
  else:rows[ident]={'offset':start,'art':art}
 assert pos==len(raw)
 source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',cache);ui=json.loads((ROOT/'godot/assets/ui/catalog.json').read_bytes())['textures'];catalog=json.loads((ROOT/'godot/assets/library/visuals.json').read_bytes());proof=[]
 for row in catalog['tattoos']:
  binding=rows[row['sourceId']];art=next((a for a in binding['art'] if a['path'] in ui),binding['art'][0]);key=art['path'];image=ui.get(key)
  if image is None:
   raw_image=source.get('root/'+key);dst=ROOT/'godot/assets/presentation'/('tattoo-'+str(row['sourceId'])+'.png');dst.write_bytes(texture_png(raw_image));image={'asset':'res://'+str(dst.relative_to(ROOT/'godot')),'sourceSha256':hashlib.sha256(raw_image).hexdigest()}
  row.update(icon=image['asset'],iconRegion=[0,0,420 if art['size'][0]==512 else 210,150 if art['size'][0]==512 else 75],uvTranspose=row['role']=='body',renderPriority=1,iconSource={'path':key,'sha256':image['sourceSha256'],'exitemOffset':binding['offset'],'basis':'Exact source item ID in fully parsed exitemdata.dat; separate normal shop art, never skin UV atlas.'})
  proof.append({'id':row['id'],'role':row['role'],'sourceOffset':binding['offset'],'sourceIcon':key,'asset':row['icon']})
 (ROOT/'godot/assets/library/visuals.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
 (ROOT/'docs/tattoo-cards-020.json').write_text(json.dumps({'sourceSha256':hashlib.sha256(raw).hexdigest(),'records':len(rows),'sourceRecordLayout':'57-byte header + 2 x UTF-16LE string and uint16 width/height; entire file exhausted','bindings':proof,'scope':'Original per-item card art, all torso UVs use the same correction as approved OG; no original skin/GLB edits.'},ensure_ascii=False,indent=2)+'\n')
 (ROOT/'docs/pc_sources_020').mkdir(exist_ok=True);(ROOT/'docs/pc_sources_020/exitemdata.dat.gz').write_bytes(gzip.compress(raw,mtime=0))
 print('TATTOO_CARDS_020',len(proof),'exact original icons',flush=True)
if __name__=='__main__':run(pathlib.Path(sys.argv[1]))
