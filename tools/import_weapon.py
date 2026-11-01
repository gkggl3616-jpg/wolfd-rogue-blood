"""Convert the exact first-person AK-47/hand asset referenced by Weapon11."""
import argparse,hashlib,json,re,struct
from pathlib import Path
from scan_xfs import unpack_index,recover_entry
from convert_character import load,glb,texture_png
ROOT=Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser();parser.add_argument('folder',type=Path);args=parser.parse_args()
    archive=args.folder/'wolf.xfs';lookup={e['path'].lower():e for e in unpack_index(archive)}
    raw=recover_entry(archive,lookup['root/attributes/weapons.txt']);text=raw.decode('cp1254',errors='replace')
    text=re.sub(r'/\*.*?\*/','',text,flags=re.S);text=re.sub(r'//[^\r\n]*','',text)
    match=re.search(r'(?m)^\[Weapon11\]\s*\n(.*?)(?=^\[|\Z)',text,re.S|re.M)
    if not match:raise ValueError('Weapon11 missing')
    values={k.lower():v.strip().strip('"') for k,v in re.findall(r'^\s*(\w+)\s*=\s*([^\r\n]*)',match[1],re.M)}
    key=('root/'+values['pvmodel'].replace('\\','/')).lower();model_raw=recover_entry(archive,lookup[key]);clips=dict(idle='idle0',walk='Walk',fire='Fire',reload='Reload',select='Select')
    asset=load(model_raw,set(clips.values()));asset['info']['sha256']=hashlib.sha256(model_raw).hexdigest()
    if asset['children']:raise ValueError('Unexpected weapon donor')
    optional={'WT_PV_AKEI47_MUZ-01','WT_PV_AKEI47_MUZ-02','WT_PV_AKEI47_MUZ-03','WT_PV_AKEI47_MUZ-04','WT_PV_AKEI47_BUTT-01'}
    omitted=[m['name'] for m in asset['meshes'] if m['name'] in optional];asset['meshes']=[m for m in asset['meshes'] if m['name'] not in optional]
    skins={}
    for slot in {m['material'] for m in asset['meshes']}:
        name=values['pvskin'+str(slot)];skins[slot]=(name,texture_png(recover_entry(archive,lookup[('root/'+name.replace('\\','/')).lower()])))
    output=ROOT/'godot/assets/weapons/ak47';output.mkdir(parents=True,exist_ok=True)
    result=glb(asset,asset,skins,clips,output/'viewmodel.glb',root_scale=1,freeze_root=False,alpha_mask=False)
    result.update(name='AK-47',sourceDefinition='Weapon11',source=key,sourceSha256=hashlib.sha256(model_raw).hexdigest(),sourceTableSha256=hashlib.sha256(raw).hexdigest(),position=[float(x) for x in values['pos'].strip('<>').split(',')],shotsPerClip=int(values['shotsperclip']),fireIntervalMs=float(values['fireinterval']),reloadSeconds=float(asset['animations']['Reload']['times'][-1]),omittedAttachmentVariants=omitted,fullWeaponSystem=False)
    result['godotPosition']=[result['position'][0],result['position'][1],-result['position'][2]]
    result['godotReflectZ']=True
    sound_archive=args.folder/'sound.xfs';sounds={e['path'].lower():e for e in unpack_index(sound_archive)};result['sounds']={}
    for action in ['fire','reload']:
        source='root/wt_snd/mainweapon/akei47/akei47_'+action+'.wav';data=recover_entry(sound_archive,sounds[source])
        if data[:4]!=b'RIFF' or data[8:12]!=b'WAVE':raise ValueError('Unexpected weapon sound format')
        (output/(action+'.wav')).write_bytes(data)
        result['sounds'][action]=dict(asset='res://assets/weapons/ak47/'+action+'.wav',source=source,sha256=hashlib.sha256(data).hexdigest())
    (output/'weapon.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8');(ROOT/'docs/weapon-conversion.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(result))

if __name__=='__main__':main()
