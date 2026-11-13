"""Read and hash every supplied RAR member; never execute or store PC binaries."""
from collections import Counter
import argparse
import datetime
import gzip
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import tempfile
import time
import zlib

from pc_archive import drive_url, RangeFile, vint
from ltb_metadata import inspect_ltb

ROOT=Path(__file__).resolve().parents[1]


def decoded_blocks(payload, member, unrar=None):
    """Decode a single non-solid member; a damaged member cannot hide later files."""
    import libarchive
    try:
        # Complete validation before yielding: decoder errors must not leave a
        # partially hashed prefix before the independent fallback is attempted.
        with libarchive.memory_reader(payload) as archive:
            result = None
            for entry in archive:
                if str(entry.pathname) != member and not (entry.isdir and str(entry.pathname).rstrip('/')==member.rstrip('/')):
                    raise ValueError('Unexpected archive member')
                result = b''.join(entry.get_blocks(block_size=1024*1024))
        if result is None: raise ValueError('Decoder returned no archive member')
        yield result
        return
    except libarchive.exception.ArchiveError:
        if not unrar: raise
    with tempfile.TemporaryDirectory(prefix='wolf-rar-member-') as folder:
        path=Path(folder)/'member.rar';path.write_bytes(payload)
        # The copied main header contains the original Quick Open offset. It is
        # invalid in this isolated member archive; disable Quick Open explicitly.
        process=subprocess.Popen([unrar,'p','-qo-','-inul','-p-',str(path)],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        try:
            while block:=process.stdout.read(1024*1024):yield block
            error=process.stderr.read(4096)
            if process.wait()!=0:raise ValueError('Independent RAR decoder failed: '+error.decode('utf-8',errors='replace'))
        finally:
            if process.poll() is None:process.kill();process.wait()


def member_metadata(packed,header_length):
    if zlib.crc32(packed[4:header_length]) != struct.unpack_from('<I',packed)[0]:raise ValueError('RAR member header CRC mismatch')
    _,cursor=vint(packed,4)
    kind,cursor=vint(packed,cursor);flags,cursor=vint(packed,cursor)
    if flags&1:_,cursor=vint(packed,cursor)
    data_size=0
    if flags&2:data_size,cursor=vint(packed,cursor)
    file_flags,cursor=vint(packed,cursor);size,cursor=vint(packed,cursor);_,cursor=vint(packed,cursor)
    if file_flags&2:cursor+=4
    crc=None
    if file_flags&4:crc=struct.unpack_from('<I',packed,cursor)[0];cursor+=4
    compression,cursor=vint(packed,cursor);_,cursor=vint(packed,cursor);name_size,cursor=vint(packed,cursor)
    name=packed[cursor:cursor+name_size].decode('utf-8')
    return {'kind':kind,'name':name,'compression':compression,'size':size,'dataSize':data_size,'crc':crc,'directory':bool(file_flags&1)}


def empty_directory(packed,header_length,expected_name):
    info=member_metadata(packed,header_length)
    if info['kind']!=2 or not info['directory'] or info['size'] or info['dataSize'] or info['name'].rstrip('/')!=expected_name.rstrip('/'):
        raise ValueError('Directory header does not match the indexed empty directory')
    return b''


def stored_quick_open(packed, header_length, expected):
    """RAR's QO service is archive metadata, not a game asset or executable."""
    info=member_metadata(packed,header_length)
    size=info['size'];crc=info['crc']
    if info['kind']!=3 or info['name']!='QO' or info['compression']>>7&7 or size!=expected or size!=info['dataSize']:raise ValueError('Unsupported archive service encoding')
    payload=packed[header_length:]
    if len(payload)!=size or crc is not None and zlib.crc32(payload)!=crc:raise ValueError('RAR service payload CRC mismatch')
    return payload


def scan(file_id, output, summary_path, index_path, unrar=None, resume=False):
    with gzip.open(index_path,'rt',encoding='utf-8') as stream:index=json.load(stream)
    if index['driveFileId']!=file_id or index.get('solid') is not False:raise ValueError('A verified matching non-solid index is required')
    url, packed_size=drive_url(file_id)
    if packed_size!=index['archiveBytes']:raise ValueError('Archive size changed; re-index before scanning')
    remote=RangeFile(url,packed_size)
    first=min(row['offset'] for row in index['files'])
    main=remote.read_range(0,first-1)
    ending=b'\x03\x05\x00\x00';ending=struct.pack('<I',zlib.crc32(ending))+ending
    started=time.monotonic()
    rows=0; total=0; unique={}; types=Counter(); model_errors=Counter(); models=0; parsed=0
    text_files=0
    pending=output.with_suffix(output.suffix+'.pending')
    replay=[]
    if resume and pending.exists():
        try:
            with gzip.open(pending,'rt',encoding='utf-8') as previous:
                for line in previous:
                    try:info=json.loads(line)
                    except json.JSONDecodeError:break
                    entry=index['files'][len(replay)]
                    if (info.get('source'),info.get('bytes'),info.get('archiveOffset'),info.get('packedBytes'))!=(entry['name'],entry['size'],entry['offset'],entry['packed']) or info.get('contentRead') is not True or not re.fullmatch('[0-9a-f]{64}',info.get('sha256','')):
                        raise ValueError('Resume prefix does not match the source header index')
                    replay.append(info)
        except EOFError:pass  # Only complete, already validated JSONL records survive an interruption.
        for info in replay:
            suffix=Path(info['source']).suffix.lower();sha=info['sha256'];rows+=1;total+=info['bytes'];types[suffix or '(none)']+=1
            if info['bytes'] and sha not in unique:
                unique[sha]=info
                if suffix=='.ltb':
                    models+=1
                    if info.get('ltb',{}).get('parsed'):parsed+=1
                    else:model_errors[info.get('ltb',{}).get('reason','unknown').split(':',1)[0]]+=1
                elif suffix in {'.txt','.cfg','.ini','.csv'}:text_files+=1
        print(json.dumps({'resumedVerifiedEntries':rows,'decodedBytesAlreadyVerified':total}),flush=True)
    resume_count=rows
    with gzip.open(pending,'wt',encoding='utf-8') as report:
            for info in replay:report.write(json.dumps(info,ensure_ascii=False,separators=(',',':'))+'\n')
            replay.clear()
            for entry in index['files'][rows:]:
                name=entry['name']; suffix=Path(name).suffix.lower()
                digest=hashlib.sha256(); count=0; head=b''; data=bytearray()
                retain=suffix=='.ltb' and entry['size']<=128*1024*1024
                remote.seek(entry['offset']);header=remote.read(512)
                length,offset=vint(header,4);header_length=length+offset
                if header_length>1048576:raise ValueError('Unbounded RAR member header')
                remote.seek(entry['offset']);packed=remote.read(header_length+entry['packed'])
                if name=='QO':blocks=[stored_quick_open(packed,header_length,entry['size'])]
                elif name.endswith('/') and entry['size']==0:blocks=[empty_directory(packed,header_length,name)]
                else:blocks=decoded_blocks(main+packed+ending,name,unrar)
                for block in blocks:
                    digest.update(block);count+=len(block)
                    if len(head)<164:head=(head+block)[:164]
                    if retain:data.extend(block)
                if count!=entry['size']:
                    raise ValueError(f'Decoded size mismatch: {name}')
                sha=digest.hexdigest()
                info={'source':name,'bytes':count,'archiveOffset':entry['offset'],'packedBytes':entry['packed'],
                      'sha256':sha,'type':suffix or 'directory_or_no_suffix','contentRead':True}
                if name=='QO':info['archiveServiceMetadata']=True
                if name.endswith('/') and count==0:info['archiveDirectory']=True
                if count:
                    if sha in unique:
                        info['byteIdenticalTo']=unique[sha]['source']
                        if suffix=='.ltb' and 'ltb' in unique[sha]:info['ltb']=unique[sha]['ltb']
                    else:
                        if suffix=='.ltb':
                            models+=1
                            try:
                                if not retain:raise ValueError('Model exceeds bounded parser input limit')
                                metadata=inspect_ltb(bytes(data))
                                info['ltb']={'parsed':True,'bytesParsed':metadata['bytesParsed'],'nodes':metadata['nodeCount'],
                                             'skeletonSha256':metadata['skeletonSha256'],'bindPoseSha256':metadata['bindPoseSha256'],
                                             'animationCount':metadata['animationCount'],'animations':metadata['animations'],
                                             'childModels':metadata['childModels'],'mesh':metadata['mesh']}
                                parsed+=1
                            except (ValueError,struct.error,UnicodeError) as exc:
                                reason=str(exc);info['ltb']={'parsed':False,'reason':reason};model_errors[reason.split(':',1)[0]]+=1
                        elif suffix=='.dtx' and len(head)>=164:
                            resource,version,width,height=struct.unpack_from('<IiHH',head)
                            info['dtx']={'resource':resource,'version':version,'width':width,'height':height,'pixelFormat':head[26]}
                        elif suffix in {'.txt','.cfg','.ini','.csv'}:text_files+=1
                        unique[sha]=info
                rows+=1;total+=count;types[suffix or '(none)']+=1
                report.write(json.dumps(info,ensure_ascii=False,separators=(',',':'))+'\n')
                if rows%1000==0:print(json.dumps({'entries':rows,'readGiB':round(total/1024**3,2),'uniqueModelsParsed':parsed,'elapsedSeconds':round(time.monotonic()-started)}),flush=True)
    pending.replace(output)
    summary={'schemaVersion':1,'driveFileId':file_id,'archiveBytes':packed_size,'entriesRead':rows,'decodedBytesIncludingDuplicateTrees':total,
             'uniqueBytePayloads':len(unique),'fileTypes':dict(types),'uniqueLtbPayloads':models,'fullyParsedUniqueModels':parsed,'unsupportedLtbPayloads':models-parsed,'ltbParserIssues':dict(model_errors),
             'textFilesRead':text_files,'allMemberBytesRead':True,'windowsBinariesExecuted':False,'fullGamePortComplete':False,
             'headerIndexSha256':hashlib.sha256(index_path.read_bytes()).hexdigest(),
             'rarDecoders':'libarchive with optional independent unrar fallback',
             'resumedVerifiedEntries':resume_count,
             'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'elapsedSecondsThisInvocation':round(time.monotonic()-started),
             'scope':'Every member read and SHA-256 hashed; supported LTB metadata fully parsed and DTX headers inspected. Not a gameplay or visual-equivalence claim.'}
    summary_path.write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(summary,ensure_ascii=False,indent=2),flush=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('file_id');parser.add_argument('--output',type=Path,default=ROOT/'docs/pc-content-scan.jsonl.gz')
    parser.add_argument('--summary',type=Path,default=ROOT/'docs/pc-content-scan-summary.json')
    parser.add_argument('--index',type=Path,default=ROOT/'docs/pc-archive-inventory.json.gz')
    parser.add_argument('--unrar',help='Optional Unix decoder executable, used only for unsupported RAR blocks')
    parser.add_argument('--resume',action='store_true',help='Resume complete verified records from an interrupted pending scan')
    args=parser.parse_args();scan(args.file_id,args.output,args.summary,args.index,args.unrar,args.resume)
