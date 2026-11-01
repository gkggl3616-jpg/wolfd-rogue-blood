"""Read XFS directory indexes and recover control declarations. No game is executed."""
import argparse
import collections
import hashlib
import gzip
import json
from pathlib import Path
import re
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
KEYS = {2:'1',3:'2',4:'3',5:'4',6:'5',7:'6',8:'7',9:'8',10:'9',11:'0',14:'Backspace',15:'Tab',16:'Q',17:'W',18:'E',19:'R',20:'T',21:'Y',23:'I',25:'P',26:'[',27:']',28:'Enter',29:'Sol Ctrl',30:'A',31:'S',32:'D',33:'F',34:'G',35:'H',38:'L',39:';',40:"'",41:'`',42:'Sol Shift',44:'Z',45:'X',46:'C',47:'V',48:'B',49:'N',50:'M',51:',',52:'.',56:'Sol Alt',57:'Space',60:'F2',62:'F4',63:'F5',66:'F8',67:'F9',200:'Yukarı',203:'Sol ok',205:'Sağ ok',207:'End',208:'Aşağı'}
LABELS = {'Forward':'İleri','Backward':'Geri','StrafeLeft':'Sola hareket','StrafeRight':'Sağa hareket','Activate':'Etkileşim','Reload':'Şarjör değiştir','TurnAround':'Arkaya dön','Duck':'Eğil','Jump':'Zıpla','Speed':'Hız / yürü-koş','Fire':'Ateş','Strafe':'Yana hareket kipi','Left':'Sola dön','Right':'Sağa dön','LookUp':'Yukarı bak','LookDown':'Aşağı bak','LeanLeft':'Sola eğil','LeanRight':'Sağa eğil','Score':'Skor tablosu','Mission':'Görev','Inventory':'Envanter','ChangeCharacter':'Karakter / dönüşüm','ChangePistol':'Tabanca','ChangeRifle':'Tüfek','ChangeGrenade':'El bombası','ChangeBomb':'Bomba','LastWeapon':'Son silah','QuickWeapon1':'Hızlı silah 1','QuickWeapon2':'Hızlı silah 2','SendMessage':'Sohbet','TeamMessage':'Takım sohbeti','PrideMessage':'Klan sohbeti','WolfMedicalKitUse':'Kurt sağlık kiti','WolfSteamPackUse':'Kurt güç paketi','MultiWeaponChange':'Çoklu silah değişimi','InGameWeaponView':'Silahı incele','Flashlight':'Fener','Graffiti':'Grafiti','MakeScreenShot':'Ekran görüntüsü','Recording':'Kayıt','Yes':'Evet','No':'Hayır','MoveBody':'Gövde taşı','HolsterWeapon':'Silahı indir','Radio':'Telsiz','ZoomIn':'Yakınlaştır','ZoomOut':'Uzaklaştır','NextWeapon':'Sonraki silah','PrevWeapon':'Önceki silah','NextAmmo':'Mermi türü','DuckLock':'Eğilme kilidi','CenterView':'Bakışı ortala','ViewIntel':'Bilgi ekranı','ViewKeys':'Tuş bilgisi','Messenger':'Mesajlar','CompassToggle':'Pusula'}

def unpack_index(path):
    with path.open('rb') as f:
        off = struct.unpack('<I', f.read(4))[0]
        if not 4 <= off < path.stat().st_size:
            raise ValueError('Invalid directory offset')
        f.seek(off)
        tail = f.read()
    streams = []
    for i in range(min(96, len(tail)-1)):
        if tail[i:i+2] in (b'\x78\xda',b'\x78\x9c',b'\x78\x01'):
            try:
                decoder = zlib.decompressobj()
                content = decoder.decompress(tail[i:], 32*1024*1024)
                if decoder.eof: streams.append(content)
            except zlib.error: pass
    header = next(s for s in streams if s.startswith(b'XFS'))
    index = max(streams, key=len)
    rows = []
    if header.startswith(b'XFS2'):
        for pos in range(0,len(index),128):
            item = index[pos:pos+128]
            if len(item)!=128: raise ValueError('Incomplete XFS2 record')
            name = item[:112].split(b'\0')[0].decode('cp1254','replace').replace('\\','/')
            offset, flag, size, packed = struct.unpack_from('<IIII',item,112)
            rows.append(dict(path=name,offset=offset,size=size,packed=packed,flag=flag,children=0))
    else:
        cursor=0
        def visit(parent='',depth=0):
            nonlocal cursor
            if depth>64: raise ValueError('Directory depth')
            count=struct.unpack_from('<I',index,cursor)[0]; cursor+=4
            length=index[cursor]; cursor+=1
            name=index[cursor:cursor+length].decode('cp1254','replace'); cursor+=length
            offset=int.from_bytes(index[cursor:cursor+6],'little')
            size,packed=struct.unpack_from('<II',index,cursor+6)
            flag=index[cursor+14]; cursor+=15
            name=parent+'/'+name if parent else name
            rows.append(dict(path=name,offset=offset,size=size,packed=packed,flag=flag,children=count))
            for _ in range(count): visit(name,depth+1)
        visit()
        if cursor!=len(index): raise ValueError('Unconsumed directory data')
    for row in rows:
        if row['offset']+row['packed']>off: raise ValueError('File outside data region')
    return rows

def recover_small(path,entry):
    with path.open('rb') as f:
        f.seek(entry['offset']); raw=f.read(entry['packed'])
    for i in range(min(32,len(raw)-1)):
        if raw[i:i+2] in (b'\x78\xda',b'\x78\x9c',b'\x78\x01'):
            try:
                decoder=zlib.decompressobj(); data=decoder.decompress(raw[i:], max(entry['size']+1,1))
                if decoder.eof and len(data)==entry['size']: return data
            except zlib.error: pass
    raise ValueError('Not a supported single-stream entry')

def recover_entry(path, entry, max_bytes=128*1024*1024):
    """Decode complete XFS block chains, including the final short block."""
    if not 0 <= entry['size'] <= max_bytes:
        raise ValueError('Entry exceeds extraction limit')
    if entry['flag'] != 1:
        raise ValueError('Unsupported XFS entry compression flag')
    with Path(path).open('rb') as stream:
        stream.seek(entry['offset'])
        packed=stream.read(entry['packed'])
    cursor=0; output=bytearray()
    def take(length):
        nonlocal cursor
        if cursor+length>len(packed): raise ValueError('Truncated XFS block')
        part=packed[cursor:cursor+length]; cursor+=length
        return part
    while cursor<len(packed):
        length=int.from_bytes(take(3),'little'); expected=65536
        stored=bool(length & 0x400000)
        if length & 0x800000:
            expected=length & 0x3fffff
            if not 0<expected<=65536: raise ValueError('Invalid XFS short block size')
            length=expected if stored else int.from_bytes(take(3),'little')
        else:
            length &= 0x3fffff
            if stored and length!=expected:raise ValueError('Invalid XFS stored full block size')
        take(2)  # Archive-specific checksum; zlib validates its own checksum below.
        if stored:
            block=take(length)
        else:
            decoder=zlib.decompressobj()
            block=decoder.decompress(take(length),expected+1)
            if not decoder.eof or decoder.unused_data or len(block)!=expected:
                raise ValueError('Invalid XFS compressed block')
        output.extend(block)
        if len(output)>entry['size']: raise ValueError('XFS entry size overflow')
    if len(output)!=entry['size']: raise ValueError('XFS entry size mismatch')
    return bytes(output)

def mobile(action):
    if action in ('Forward','Backward','StrafeLeft','StrafeRight','Strafe','AxisLeftRight','AxisForwardBackward'): return 'Sol sanal çubuk'
    if action in ('Left','Right','LookUp','LookDown','AxisYaw','AxisPitch','MouseAim'): return 'Sağ bakış alanı'
    if action in ('Fire','Activate','Reload','Jump','Duck','Speed','ChangeCharacter'): return 'Ana dokunmatik düğme'
    if action.startswith(('Weapon_','Number_','Choose_','QuickWeapon')) or action in ('ChangeRifle','ChangePistol','ChangeGrenade','ChangeBomb','LastWeapon','PrevWeapon','NextWeapon','MultiWeaponChange'): return 'Silah / seçim menüsü'
    if action in ('MakeScreenShot','Recording','QuickSave','QuickLoad','LeaveUnassigned') or action.startswith('Axis'): return 'Araçlar / motor uyarlaması gerekli'
    return 'Diğer kontroller menüsü'

def main():
    parser=argparse.ArgumentParser(); parser.add_argument('folder',type=Path); args=parser.parse_args()
    inventory=[]; settings=None
    for p in sorted(args.folder.glob('*.xfs')):
        entries=unpack_index(p)
        h=hashlib.sha256()
        with p.open('rb') as f:
            while chunk:=f.read(4*1024*1024): h.update(chunk)
        inventory.append(dict(archive=p.name,bytes=p.stat().st_size,sha256=h.hexdigest(),entries=entries))
        for entry in entries:
            if entry['path'].lower().endswith('/autoexec.cfg'):
                settings=recover_small(p,entry).decode('utf-8')
    if settings is None: raise ValueError('No autoexec.cfg found')
    bindings=collections.defaultdict(list); empty=[]
    for line in settings.splitlines():
        if not line.startswith('rangebind '): continue
        tokens=re.findall(r'"([^"]*)"',line)
        device,key,*actions=tokens
        if device=='##keyboard':
            code=int(key.removeprefix('##')); key=KEYS.get(code, f'Tarama kodu {code}')
        else: key={'##3':'Fare düğmesi ##3 (ateş)','##4':'Fare düğmesi ##4 (etkileşim)','##z-axis':'Fare tekerleği'}.get(key,key)
        if not actions: empty.append(key)
        for action in actions: bindings[action].append(dict(device=device,key=key,raw=tokens[1]))
    controls=[]
    for action,num in re.findall(r'^AddAction (\S+) (-?\d+)', settings,re.M):
        label=LABELS.get(action,re.sub(r'([a-z])([A-Z])',r'\1 \2',action).replace('_',' '))
        controls.append(dict(action=action,id=int(num),label=label,bindings=bindings[action],mobile=mobile(action),status='atanmış' if bindings[action] else 'tanımlı, tuş atanmamış'))
    result=dict(title='Wolf Rogue Blood',source='2490271990696398.xfs / Root/autoexec.cfg',scope='Statik yapılandırma taraması. Komut tanımı, oyun modunda çalıştığını kanıtlamaz. Klavye adları Windows DirectInput tarama kodu yorumudur; bölgesel noktalama değişebilir. Fare düğmeleri dosyadaki ham kodlarıyla korunmuştur.',controls=controls,unboundKeys=empty)
    (ROOT/'web/controls.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    inventory_bytes=json.dumps(inventory,ensure_ascii=False,indent=2).encode('utf-8')
    (ROOT/'docs/archive-inventory.json').write_bytes(inventory_bytes)
    (ROOT/'docs/archive-inventory.json.gz').write_bytes(gzip.compress(inventory_bytes,mtime=0))
    lines=['# Wolf Rogue Blood — kontrol taraması','',result['scope'],'',f"{len(controls)} komut; {sum(bool(c['bindings']) for c in controls)} komutta tuş ataması bulundu.",'','| Komut | ID | PC ataması | Mobil karşılık |','|---|---:|---|---|']
    for c in controls: lines.append(f"| {c['action']} | {c['id']} | {', '.join(b['key'] for b in c['bindings']) or 'Atanmamış'} | {c['mobile']} |")
    lines+=['','## Aynı tuşa atanmış komutlar','', 'Birlikte atama, komutların eşzamanlı çalıştığını kanıtlamaz; oyun durumuna bağlı olabilir. Mobil laboratuvar bunları ayrı komutlar olarak sunar.','']
    grouped=collections.defaultdict(list)
    for c in controls:
        for b in c['bindings']: grouped[(b['device'],b['key'])].append(c['action'])
    for (_,key),actions in grouped.items():
        if len(actions)>1: lines.append(f"- {key}: {', '.join(actions)}")
    lines+=['','## Sınırlar','','Paket indekslerinin tamamı okundu ve kayıt sınırları doğrulandı. Büyük dosyaların içeriği bütünüyle açılmadı. Kontrol listesi bulunan autoexec.cfg içindeki bütün AddAction ve rangebind satırlarını kapsar; oyun kodundaki sabit tuşları veya sunucu komutlarını kapsadığı iddia edilmez.','.xfs paketleri mobil uygulama kaynak kodu değildir. Oyun motoru, derleme projesi ve hesap sunucusu ayrıca gerekir.']
    (ROOT/'docs/KONTROLLER.md').write_text('\n'.join(lines),encoding='utf-8')
    print(json.dumps(dict(archives=len(inventory),entries=sum(len(x['entries']) for x in inventory),actions=len(controls),boundActions=sum(bool(c['bindings']) for c in controls))))

if __name__=='__main__': main()
