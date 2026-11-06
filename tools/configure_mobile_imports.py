"""Keep original files intact; encode Android render copies with a reproducible size profile."""
import json,pathlib,re
ROOT=pathlib.Path(__file__).resolve().parents[1]
folders=['maps/textures','library/characters','library/character_skins','library/weapons','library/textures','weapons']
changed=0
for folder in folders:
 for path in (ROOT/'godot/assets'/folder).rglob('*.png.import'):
  text=path.read_text();updated=re.sub(r'(?m)^compress/mode=\d+$','compress/mode=1',text);updated=re.sub(r'(?m)^compress/lossy_quality=.*$','compress/lossy_quality=0.95',updated)
  if text!=updated:path.write_text(updated);changed+=1
for path in (ROOT/'godot/assets').rglob('*.wav.import'):
 text=path.read_text();updated=re.sub(r'(?m)^compress/mode=\d+$','compress/mode=2',text)
 if text!=updated:path.write_text(updated);changed+=1
# Disable generated mesh LOD and compressed vertex attributes on skinned actors.
# Imported render data is regenerated; the admitted original GLBs stay unchanged.
for folder in ['library/characters','mutations']:
 for path in (ROOT/'godot/assets'/folder).rglob('*.glb.import'):
  text=path.read_text();updated=text
  for key,value in [('meshes/generate_lods','false'),('meshes/create_shadow_meshes','false'),('meshes/force_disable_compression','true')]:
   updated=re.sub(r'(?m)^'+re.escape(key)+r'=.*$',key+'='+value,updated)
  if text!=updated:path.write_text(updated);changed+=1
profile={'schemaVersion':1,'sourceImagesModified':False,'textureFolders':folders,'textureCompression':'Godot lossy WebP, quality 0.95, source PNG retained','uiIconsCompression':'lossless','audioCompression':'Godot QOA','sourceAudioModified':False,'skinnedMeshes':{'vertexCompression':False,'generatedLods':False,'shadowMeshes':False,'sourceGlbsModified':False,'reason':'Compatibility renderer stability for skinned character surfaces on mobile GPUs'}}
(ROOT/'godot/assets/mobile-import-profile.json').write_text(json.dumps(profile,indent=2)+'\n')
print('Configured render imports:',changed)
