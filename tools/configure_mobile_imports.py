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
profile={'schemaVersion':1,'sourceImagesModified':False,'textureFolders':folders,'textureCompression':'Godot lossy WebP, quality 0.95, source PNG retained','uiIconsCompression':'lossless','audioCompression':'Godot QOA','sourceAudioModified':False}
(ROOT/'godot/assets/mobile-import-profile.json').write_text(json.dumps(profile,indent=2)+'\n')
print('Configured render imports:',changed)
