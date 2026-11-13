"""Decode source voice rows and mode options; preserve exact source IDs and offsets."""
import argparse,collections,gzip,hashlib,json,pathlib,re,struct
ROOT=pathlib.Path(__file__).resolve().parents[1]

def voice_rows(data):
    rows=[];pos=0
    while pos<len(data):
        start=pos;ident,event,count,n=struct.unpack_from('<HBBH',data,pos);pos+=6
        if not 0<n<1024 or pos+n*2>len(data):raise ValueError('Invalid voice row')
        prefix=data[pos:pos+n*2].decode('utf-16le');pos+=n*2
        if not prefix.lower().startswith('wt_snd\\') or not 1<=count<=32:raise ValueError('Unexpected source voice definition')
        rows.append(dict(model=ident,event=event,count=count,prefix=prefix,offset=start))
    if pos!=len(data):raise ValueError('Voice table not exhausted')
    return rows

def source_options(data,kind):
    fmt='<HBHBH' if kind=='time' else '<HBHBHB';size=struct.calcsize(fmt)
    if len(data)%size:raise ValueError('Truncated source mode options')
    result=[]
    for p in range(0,len(data),size):
        row=struct.unpack_from(fmt,data,p)
        if kind=='time':record=dict(mode=row[0],context=row[1],seconds=row[2],default=bool(row[3]),displayUnit=row[4],offset=p)
        else:record=dict(mode=row[0],context=row[1],points=row[2],rounds=row[3],caption=row[4],default=bool(row[5]),offset=p)
        result.append(record)
    return result

def run(folder):
    dst=ROOT/'docs/pc_sources_017';dst.mkdir(exist_ok=True);raw={}
    for name in ['wolfsound','humansound','modetime','modemission','modeinfo','modeplayer','wolfvars','wolfattr','weapondata']:
        b=(folder/(name+'.dat')).read_bytes();raw[name]=b;(dst/(name+'.dat.gz')).write_bytes(gzip.compress(b,mtime=0))
    media=json.loads((ROOT/'godot/assets/shared_media/catalog.json').read_bytes())['sounds'];voices={};missing=[]
    for form in ['human','wolf']:
        rows=voice_rows(raw[form+'sound']);result={}
        for row in rows:
            prefix='root/'+row['prefix'].replace('\\','/').lower();keys=[prefix+str(i)+'.wav' for i in range(1,row['count']+1)];keys=[key for key in keys if key in media]
            if not keys and prefix+'.wav' in media:keys=[prefix+'.wav']
            if not keys:missing.append(row)
            result.setdefault(str(row['model']),{})[str(row['event'])]=dict(row,keys=keys)
        voices[form]=result
    # Only numeric sound_key IDs actually present in the imported donor tracks.
    events=json.loads(gzip.decompress((ROOT/'docs/animation-events-source-017.json.gz').read_bytes()));needed=set(map(int,re.findall(r'(?i)sound_key\s+(\d+)\s+\d+',json.dumps(events))))
    b=raw['weapondata'];headers=[]
    for match in re.finditer('normal'.encode('utf-16le'),b):
        p=match.start()-17
        if p<0:continue
        ident,kind=struct.unpack_from('<II',b,p)
        if 0<ident<100000 and kind<16 and struct.unpack_from('<H',b,p+15)[0]==6:headers.append((p,ident))
    weapon_sounds={}
    for i,(start,ident) in enumerate(headers):
        if ident not in needed:continue
        end=headers[i+1][0] if i+1<len(headers) else len(b);paths=[]
        for match in re.finditer(rb'W\x00T\x00_\x00S\x00n\x00d\x00.{0,400}?\.\x00w\x00a\x00v\x00',b[start:end],re.S|re.I):
            p=start+match.start();n=struct.unpack_from('<H',b,p-2)[0]
            if n*2==len(match.group()):
                source=match.group().decode('utf-16le');key='root/'+source.replace('\\','/').lower()
                paths.append(dict(source=source,offset=p,key=key if key in media else ''))
        if str(ident) in weapon_sounds:raise ValueError('Ambiguous natural-weapon audio ID')
        weapon_sounds[str(ident)]=dict(offset=start,sounds=paths)
    times=source_options(raw['modetime'],'time');goals=source_options(raw['modemission'],'goal');catalog=json.loads((ROOT/'godot/assets/maps/catalog.json').read_bytes());modes={}
    for mode in catalog['modes']:
        ident=int(mode['id']);family=int(mode['sourceFlags'][5]);flags=mode['sourceFlags']
        modes[str(ident)]=dict(id=ident,name=mode['sourceName'],family=family,redForm=flags[7],blueForm=flags[8],times=[r for r in times if r['mode']==ident and r['context']==0],goals=[r for r in goals if r['mode']==ident and r['context']==0],sourceFlags=flags)
    facts=dict(schemaVersion=1,sources={k:dict(path='root/wt_attributes/'+k+'.dat',sha256=hashlib.sha256(v).hexdigest(),bytes=len(v)) for k,v in raw.items()},voices=voices,weaponSounds=weapon_sounds,modes=modes,voiceRows=sum(len(voice_rows(raw[f+'sound'])) for f in ['human','wolf']),missingVoices=missing,scope='Exact voice rows, natural-weapon sound references and source mode options. Match simulation and rendering are implemented separately from these source facts.')
    out=ROOT/'godot/assets/gameplay';out.mkdir(exist_ok=True);(out/'source.json').write_text(json.dumps(facts,ensure_ascii=False,indent=2)+'\n');(out/'animation-events.json').write_text(json.dumps(events,ensure_ascii=False,indent=2)+'\n')
    print('GAMEPLAY_SOURCE',facts['voiceRows'],'voice rows',len(modes),'modes',len(weapon_sounds),'natural weapon audio banks','missing voices',len(missing))
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('source_folder',type=pathlib.Path);run(p.parse_args().source_folder)
