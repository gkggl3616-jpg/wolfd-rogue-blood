"""Import all supplied ClientFX groups, retaining unavailable nodes as explicit diagnostics."""
import argparse,gzip,json,hashlib,struct,pathlib,collections
from clientfx import parse,parse_butes,path_value,value
from pc_source_cache import PcSourceCache
from convert_character import load,glb,texture_png
from audit_characters import parse_model_definitions
ROOT=pathlib.Path(__file__).resolve().parents[1]

def run(folder):
    source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',folder)
    out=ROOT/'godot/assets/clientfx';out.mkdir(exist_ok=True)
    raw=gzip.decompress((ROOT/'docs/pc-clientfx.fxf.gz').read_bytes());groups=parse(raw);known={n.casefold():n for n in groups}
    media=json.loads((ROOT/'godot/assets/shared_media/catalog.json').read_bytes())
    sprites={};textures={};models={};issues=[]
    for entry in json.loads((ROOT/'godot/assets/library/visuals.json').read_bytes())['effects']:
        sprites[entry['source'].lower().removeprefix('root/')]={k:entry[k] for k in ['frames','fps','sourceSha256']}
        for frame,info in zip(entry['frames'],entry.get('frameSources',[])):
            textures[info['source'].replace('\\','/').lower().removeprefix('root/')]=dict(asset=frame,sha256=hashlib.sha256((ROOT/'godot'/frame.removeprefix('res://')).read_bytes()).hexdigest(),source=info['source'],sourceSha256=info['sourceSha256'])
    for path,info in json.loads((ROOT/'godot/assets/abilities/source-roars.json').read_bytes())['textures'].items():textures.setdefault(path.replace('\\','/').lower(),info)
    def fetch(path):return source.get('root/'+path.removeprefix('root/'))
    def texture(path):
        if path in textures:return textures[path]
        b=fetch(path);png=texture_png(b);p=out/(hashlib.sha256(path.encode()).hexdigest()[:24]+'.png');p.write_bytes(png)
        textures[path]=dict(asset='res://'+str(p.relative_to(ROOT/'godot')),sha256=hashlib.sha256(png).hexdigest(),source=path,sourceSha256=hashlib.sha256(b).hexdigest());return textures[path]
    def sprite(path):
        if path in sprites:return sprites[path]
        b=fetch(path);count,fps,*_=struct.unpack_from('<5I',b);assert 0<count<512;offset=20;frames=[]
        for _ in range(count):
            n=struct.unpack_from('<H',b,offset)[0];offset+=2;name=b[offset:offset+n].decode('cp1254').rstrip('\0').replace('\\','/').lower();offset+=n;frames.append(texture(name)['asset'])
        assert offset==len(b)
        sprites[path]=dict(frames=frames,fps=fps,sourceSha256=hashlib.sha256(b).hexdigest());return sprites[path]
    def frames(node,sprite_key='Sprite',texture_key='Texture'):
        p=path_value(node,sprite_key)
        if p and p!='...':return sprite(p)
        p=path_value(node,texture_key)
        if p and p!='...':return dict(frames=[texture(p)['asset']],fps=1)
        return dict(frames=[],fps=1)
    native_raw=gzip.decompress((ROOT/'docs/pc_sources_017/fx.txt.gz').read_bytes())
    butes=parse_butes(native_raw);projectiles={}
    for tag,props in butes.items():
        if not tag.startswith('ProjectileFX') or props.get('Name','').casefold() not in ['fireball_se','lightningball_se','radiationball_se','iceball_se']:continue
        name=props['Name'];projectiles[name]=dict(properties=props,sourceSection=tag)
        group_props={key:[v] for key,v in props.items()};group_props.update(Model=['ltb|'+props['Model']],Skin0=['dtx|'+props['Skin']],AttachName=['RightHand'],UpdatePos=['4,Fixed,Follow,PlayerView,NodeAttach,SocketAttach'],BlendMode=['1,None,Additive,Multiply'],ModelScale=[props.get('ModelScale',[1,1,1])])
        groups[name]=dict(sourceType='ProjectileFX',sourceSection=tag,nodes=[dict(type='LTBModel',start=0.0,end=float(props.get('Lifetime',1)),properties=group_props),dict(type='CreateFX',start=0.0,end=float(props.get('Lifetime',1)),properties=dict(FXName=[props['FXName']],Loop=['1,No,Yes'],AttachName=['RightHand'],UpdatePos=['4,Fixed,Follow,PlayerView,NodeAttach,SocketAttach']))])
        known[name.casefold()]=name
    types=collections.Counter()
    for name,group in groups.items():
        for index,node in enumerate(group['nodes']):
            types[node['type']]+=1;node['available']=True
            try:
                kind=node['type']
                if kind in ['Sprite','ParticleSystem','SpriteSystem','FlareSpriteFX']:node.update(frames(node))
                elif kind in ['LightningFX','PolyTrail']:
                    p=path_value(node,'Texture')
                    if p and p!='...':node['texture']=texture(p)['asset']
                elif kind=='PlaySound':
                    p=path_value(node,'Sound');key='root/'+p.removeprefix('root/');sound=media['sounds'].get(key)
                    if not sound:raise ValueError('Source sound unavailable: '+p)
                    node['sound']=sound['asset'];node['soundSourceSha256']=sound['sourceSha256']
                elif kind=='LTBModel':
                    path=path_value(node,'Model');skin_defs={};skin_frames={}
                    for slot in range(5):
                        f=frames(node,'SpriteSkin'+str(slot),'Skin'+str(slot))
                        if f['frames']:
                            skin_frames[str(slot)]=f;png=(ROOT/'godot'/f['frames'][0].removeprefix('res://')).read_bytes();skin_defs[slot]=(path,png)
                    animation=value(node,'AniName','');key=hashlib.sha256((path+json.dumps(skin_frames,sort_keys=True)+animation).encode()).hexdigest()[:24]
                    if key not in models:
                        b=fetch(path);a=load(b,{animation} if animation else set());clips={animation:animation} if animation and animation in a['animations'] and len(a['animations'][animation]['times'])>1 else {}
                        p=out/(key+'.glb');glb(a,a,skin_defs,clips,p,root_scale=.016,freeze_root=False,alpha_mask=False,external_texture_dir=out,allow_untextured=True)
                        models[key]=dict(asset='res://'+str(p.relative_to(ROOT/'godot')),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),source=path,sourceSha256=hashlib.sha256(b).hexdigest(),meshSlots={m['name']:str(m['material']) for m in a['meshes']})
                    node.update(models[key]);node['skins']=skin_frames;node['animation']=animation
                elif kind=='CreateFX':
                    target=known.get(str(value(node,'FXName','')).casefold())
                    if not target:raise ValueError('Nested effect not found: '+str(value(node,'FXName','')))
                    node['group']=target
                elif kind not in ['DynaLight','CamJitter']:raise ValueError('Unsupported node '+kind)
            except Exception as error:
                node['available']=False;node['unavailableReason']=str(error);issues.append(dict(group=name,node=index,type=node['type'],reason=str(error)))
        group['available']=all(n['available'] for n in group['nodes']);print('FX_GROUP',name,len(group['nodes']),group['available'],flush=True)
    definitions={v['id']:v for v in parse_model_definitions(gzip.decompress((ROOT/'docs/pc-modelbutes.txt.gz').read_bytes()))}
    bindings={}
    chars=json.loads((ROOT/'godot/assets/library/characters.json').read_bytes())['characters']
    for char in chars:
        bindings[char['id']]={}
        for form in ['human','wolf']:
            props=definitions[char[form]['sourceDefinition']]['values'];slots={}
            for key,fx in props.items():
                if key.startswith('ClientFX') and fx:slots[key]=known.get(fx.casefold(),fx)
            bindings[char['id']][form]=dict(definition=char[form]['sourceDefinition'],effects=slots,donor='root/'+char[form]['donor'].replace('\\','/').lower().removeprefix('root/'))
    mutation_bindings={}
    for row in json.loads((ROOT/'godot/assets/mutations/catalog.json').read_bytes())['models']:
        props=definitions[row['definition']]['values']
        effects={key:known.get(fx.casefold(),fx) for key,fx in props.items() if key.startswith('ClientFX') and fx}
        donor='root/'+row['donor'].replace('\\','/').lower().split('/root/')[-1].removeprefix('root/')
        mutation_bindings[row['definition']]=dict(definition=row['definition'],effects=effects,donor=donor)
    map_sprites={}
    for path in (ROOT/'godot/assets/maps').glob('*-objects.json'):
        for row in json.loads(path.read_bytes()):
            if row['type']!='ScaleSprite':continue
            key=row['properties'].get('Filename','').replace('\\','/').lower().removeprefix('root/')
            if not key or key in map_sprites:continue
            try:map_sprites[key]=sprite(key) if key.endswith('.spr') else dict(frames=[texture(key)['asset']],fps=1)
            except Exception as error:map_sprites[key]=dict(frames=[],fps=1,unavailableReason=str(error))
    result=dict(schemaVersion=1,sourceGroupCount=628,projectiles=projectiles,nativeButesSha256=hashlib.sha256(native_raw).hexdigest(),mapSprites=map_sprites,mutations=mutation_bindings,sourceSha256=hashlib.sha256(raw).hexdigest(),groups=groups,characters=bindings,textures=textures,models=models,issues=issues,typeCounts=dict(types),scope='Source event definitions and original assets; engine rendering adapter has explicit mobile bounds. Unavailable source/test nodes remain reported, never substituted.')
    p=ROOT/'godot/assets/clientfx/catalog.json';p.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    (ROOT/'docs/clientfx-import-017.json').write_text(json.dumps({k:result[k] for k in ['sourceSha256','issues','typeCounts','scope']}|dict(groups=len(groups),availableGroups=sum(g['available'] for g in groups.values()),models=len(models),textures=len(textures),characters=len(bindings)),ensure_ascii=False,indent=2)+'\n')
    print('FX_IMPORT_RESULT',len(groups),'groups',len(models),'models',len(issues),'unavailable nodes',flush=True)
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('cache',type=pathlib.Path);run(p.parse_args().cache)
