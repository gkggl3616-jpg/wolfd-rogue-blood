"""Decode named PC ClientFX groups and preserve their timing, curves and actual asset bindings."""
import gzip,json,re,pathlib,hashlib,struct,collections,sys
from pc_source_cache import PcSourceCache
from convert_character import load,glb,texture_png
from audit_characters import parse_model_definitions
ROOT=pathlib.Path(__file__).resolve().parents[1];source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',sys.argv[1]);raw=gzip.decompress((ROOT/'docs/pc-clientfx.fxf.gz').read_bytes());text=raw.decode('cp1254').replace('\r\n','\n');out=ROOT/'godot/assets/abilities/source_roars';out.mkdir(exist_ok=True);assets={}
def get(path):return source.get('root/'+path.replace('\\','/').lower())
def png(path):
 key=path.replace('\\','/').lower()
 if key in assets:return assets[key]
 b=get(path);p=out/(hashlib.sha256(key.encode()).hexdigest()[:20]+'.png');p.write_bytes(texture_png(b));result={'asset':'res://'+str(p.relative_to(ROOT/'godot')),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'source':path,'sourceSha256':hashlib.sha256(b).hexdigest()};assets[key]=result;return result
sprites={}
def sprite(path):
 if path in sprites:return sprites[path]
 b=get(path);count,fps,*_=struct.unpack_from('<5I',b);assert count<512;offset=20;frames=[]
 for i in range(count):
  n=struct.unpack_from('<H',b,offset)[0];offset+=2;name=b[offset:offset+n].decode('cp1254').rstrip('\0');offset+=n;frames.append(png(name)['asset'])
 assert offset==len(b)
 result={'frames':frames,'fps':fps,'source':path,'sourceSha256':hashlib.sha256(b).hexdigest()};sprites[path]=result;return result
records={};failures=[]
for group in re.split(r'(?m)^\s*GroupName: ',text)[1:]:
 name=group.splitlines()[0].strip()
 if not name.startswith('Howling_'):continue
 nodes=[]
 for block in re.split(r'(?m)^\s*FxName: ',group)[1:]:
  kind=block.splitlines()[0].split(';')[0];props=collections.defaultdict(list)
  for key,typ,value in re.findall(r'PropName: (.*?)\n\s*Type: (\d+)\n\s*\w+: (.*)',block):
   key=key.strip();value=value.strip();typ=int(typ)
   if typ==1:value=int(value)
   elif typ==2:value=float(value)
   elif typ in (4,5,6):value=list(map(float,value.split()))
   props[key].append(value)
  def val(key,default=''):return props.get(key,[default])[0]
  node={'type':kind,'start':float(re.search(r'StartTime: ([\d.]+)',block)[1]),'end':float(re.search(r'EndTime: ([\d.]+)',block)[1]),'properties':dict(props)}
  try:
   if kind=='ParticleSystem':
    path=val('Sprite').split('|')[-1]
    if path and path!='...':node.update(sprite(path))
    else:node['frames']=[png(val('Texture').split('|')[-1])['asset']];node['fps']=1
   elif kind=='LTBModel':
    path=val('Model').split('|')[-1];asset=load(get(path),set());skin_path=val('SpriteSkin0').split('|')[-1];s=sprite(skin_path) if skin_path and skin_path!='...' else {'frames':[png(val('Skin0').split('|')[-1])['asset']],'fps':1};skin=pathlib.Path(ROOT/'godot'/s['frames'][0].removeprefix('res://')).read_bytes();p=out/(hashlib.sha256(path.encode()).hexdigest()[:20]+'.glb');glb(asset,asset,{0:(path,skin)},{},p,root_scale=.016,alpha_mask=False,external_texture_dir=out)
    node.update(asset='res://'+str(p.relative_to(ROOT/'godot')),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),frames=s['frames'],fps=s['fps'])
   elif kind!='DynaLight':raise ValueError('Unsupported effect '+kind)
   nodes.append(node)
  except Exception as e:failures.append({'group':name,'type':kind,'reason':str(e)})
 records[name]={'nodes':nodes}
 print('SOURCE_ROAR',name,len(nodes),flush=True)
defs={r['id']:r for r in parse_model_definitions(gzip.decompress((ROOT/'docs/pc-modelbutes.txt.gz').read_bytes()))};chars=json.loads((ROOT/'godot/assets/library/characters.json').read_bytes())['characters'];bindings={}
for c in chars:
 model=defs[c['wolf']['sourceDefinition']];names=[v for k,v in model['values'].items() if k.startswith('ClientFXOnce') and v in records]
 if names:bindings[c['id']]=names[0]
result={'schemaVersion':1,'sourceSha256':hashlib.sha256(raw).hexdigest(),'groups':records,'characters':bindings,'textures':assets,'failures':failures,'scope':'Original models/sprites, timing and color/scale curves. Particle emission and socket fallback use a bounded mobile adapter; not every PC engine feature.'}
(ROOT/'godot/assets/abilities/source-roars.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n');print('SOURCE_ROAR_RESULT',len(bindings),'bindings',len(assets),'textures','failures',failures)
