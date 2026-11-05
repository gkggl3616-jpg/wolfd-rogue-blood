"""Fetch exact entries from the user-provided non-solid PC RAR, with CRC and hash checks."""
import gzip,hashlib,json,pathlib,struct,threading,zlib,time,urllib.error
from pc_archive import drive_url,RangeFile,vint
class PcSourceCache:
 def __init__(self,index_path,folder):
  self.index=json.loads(gzip.decompress(pathlib.Path(index_path).read_bytes()));assert self.index['solid'] is False
  self.folder=pathlib.Path(folder);self.folder.mkdir(parents=True,exist_ok=True)
  self.rows={r['name'].replace('\\','/').casefold():r for r in self.index['files'] if r['size']>0}
  self.lookup={'root/'+k.split('/root/',1)[1]:r for k,r in self.rows.items() if '/root/' in k}
  self.url=None;self.remote=None;self.guard=threading.Lock();self.network_guard=threading.Lock();self.locks={}
 def ensure_remote(self):
  with self.network_guard:
   if self.remote is not None:return
   self.url,self.size=drive_url(self.index['driveFileId']);assert self.size==self.index['archiveBytes']
   self.remote=RangeFile(self.url,self.size)
   try:
    self.header=self.read_range(0,65535);self.first=min(r['offset'] for r in self.index['files'])
    assert self.header[:8]==b'Rar!\x1a\x07\x01\x00'
   except Exception:
    self.remote=None
    raise
 def read_range(self,start,end):
  for attempt in range(4):
   try:
    time.sleep(0.15)
    return self.remote.read_range(start,end)
   except (urllib.error.HTTPError,urllib.error.URLError) as error:
    if isinstance(error,urllib.error.HTTPError) and error.code not in [429,500,502,503,504]:raise
    if attempt==3:raise
    time.sleep(2**attempt)
 def get(self,path):
  row=self.lookup[path.replace('\\','/').casefold()] if path.lower().startswith('root/') else self.rows[path.replace('\\','/').casefold()]
  key=row['name'].replace('\\','/').casefold();target=self.folder/(hashlib.sha256(key.encode()).hexdigest()[:24]+pathlib.Path(key).suffix)
  with self.guard:lock=self.locks.setdefault(key,threading.Lock())
  with lock:
   if target.is_file():
    try:return target.read_bytes()
    except FileNotFoundError:pass
   self.ensure_remote()
   assert row['size']<=256*1024*1024
   start=row['offset'];head=self.read_range(start,start+511);n,offset=vint(head,4);assert n<1048576
   block=self.read_range(start,start+n+offset+row['packed']-1)
   end=b'\x03\x05\x00\x00';end=struct.pack('<I',zlib.crc32(end))+end
   import libarchive
   result=None
   with libarchive.memory_reader(self.header[:self.first]+block+end) as archive:
    for item in archive:
     assert str(item.pathname)==row['name'];result=b''.join(item.get_blocks());assert len(result)==row['size']
     assert not row.get('crc32') or f'{zlib.crc32(result):08x}'==row['crc32']
   assert result is not None;pending=target.with_suffix(target.suffix+'.pending');pending.write_bytes(result);pending.replace(target)
   target.with_suffix(target.suffix+'.origin.json').write_text(json.dumps({'sourcePath':row['name'],'sha256':hashlib.sha256(result).hexdigest(),'bytes':len(result)}))
   return result
