"""Index a public Drive RAR and extract one data file without storing the whole archive.

Never runs the Windows client. Archive paths are names, never extraction destinations.
Optional dependencies: rarfile and libarchive-c (system libarchive with RAR5 support).
"""
import argparse
from collections import OrderedDict
import gzip
import hashlib
from html.parser import HTMLParser
import io
import json
from pathlib import Path
import re
import struct
import urllib.parse
import urllib.request
import zlib


class DownloadForm(HTMLParser):
    def __init__(self):
        super().__init__()
        self.fields = {}
    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if tag == 'input' and values.get('type') == 'hidden' and values.get('name'):
            self.fields[values['name']] = values.get('value', '')


def drive_url(file_id):
    if not re.fullmatch(r'[a-zA-Z0-9_-]+', file_id):
        raise ValueError('Invalid Drive file ID')
    base = 'https://drive.usercontent.google.com/download'
    url = base + '?' + urllib.parse.urlencode({'id': file_id, 'export': 'download'})
    with urllib.request.urlopen(urllib.request.Request(url, headers={'Range': 'bytes=0-65535'}), timeout=60) as response:
        if response.status == 206:
            return url, int(response.headers['Content-Range'].rsplit('/', 1)[1])
        form = DownloadForm()
        form.feed(response.read(65536).decode('utf-8', errors='replace'))
    if form.fields.get('id') != file_id or form.fields.get('confirm') != 't':
        raise ValueError('Public download unavailable; authentication or sharing access is required')
    url = base + '?' + urllib.parse.urlencode(form.fields)
    with urllib.request.urlopen(urllib.request.Request(url, headers={'Range': 'bytes=0-65535'}), timeout=60) as response:
        if response.status != 206:
            raise ValueError('Drive did not provide a ranged binary download')
        return url, int(response.headers['Content-Range'].rsplit('/', 1)[1])


class RangeFile(io.RawIOBase):
    def __init__(self, url, size, block_size=8 * 1024 * 1024):
        self.url, self.size, self.block_size = url, size, block_size
        self.position, self.transferred = 0, 0
        self.cache = OrderedDict()
    def readable(self): return True
    def seekable(self): return True
    def tell(self): return self.position
    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else self.size + offset
        if self.position < 0: raise ValueError('Negative archive offset')
        return self.position
    def read_range(self, start, end):
        if not 0 <= start <= end < self.size:
            raise ValueError('Archive range exceeds source')
        request = urllib.request.Request(self.url, headers={'Range': f'bytes={start}-{end}'})
        with urllib.request.urlopen(request, timeout=60) as response:
            if response.status != 206 or not response.headers.get('Content-Range', '').startswith(f'bytes {start}-'):
                raise ValueError('Server returned the wrong archive range')
            data = response.read(end-start+1)
        if len(data) != end-start+1: raise ValueError('Truncated archive range')
        self.transferred += len(data)
        return data
    def read(self, size=-1):
        remaining = min(self.size-self.position, size if size >= 0 else self.size-self.position)
        chunks = []
        while remaining > 0:
            index, offset = divmod(self.position, self.block_size)
            if index not in self.cache:
                start = index * self.block_size
                self.cache[index] = self.read_range(start, min(self.size-1, start+self.block_size-1))
                if len(self.cache) > 8: self.cache.popitem(last=False)
            data = self.cache[index]
            take = min(remaining, len(data)-offset)
            chunks.append(data[offset:offset+take]);self.position += take;remaining -= take
        return b''.join(chunks)


def write_index(file_id, output):
    import rarfile
    url, size = drive_url(file_id)
    remote = RangeFile(url, size)
    archive = rarfile.RarFile(remote)
    files = [{'name': entry.filename, 'size': entry.file_size, 'packed': entry.compress_size,
              'offset': entry.header_offset, 'crc32': f'{entry.CRC:08x}' if entry.CRC is not None else None}
             for entry in archive.infolist()]
    result = {'driveFileId': file_id, 'archiveBytes': size, 'solid': archive.is_solid(),
              'inspection': 'RAR headers only; source SHA-256 and runtime behavior are not established', 'files': files}
    with gzip.open(output, 'wt', encoding='utf-8') as stream:
        json.dump(result, stream, ensure_ascii=False, separators=(',', ':'))
    print(f'Indexed {len(files)} entries; no game files executed.')


def vint(data, offset):
    number, shift = 0, 0
    while offset < len(data) and shift <= 63:
        value = data[offset];offset += 1;number |= (value & 127) << shift
        if not value & 128: return number, offset
        shift += 7
    raise ValueError('Invalid RAR5 variable integer')


def extract_entry(index_path, member, output, maximum_bytes=256*1024*1024):
    import libarchive
    with gzip.open(index_path, 'rt', encoding='utf-8') as stream: index = json.load(stream)
    if index.get('solid') is not False: raise ValueError('Selective extraction requires a verified non-solid RAR')
    matches = [row for row in index['files'] if row['name'] == member]
    if len(matches) != 1: raise ValueError('Select exactly one archive path')
    entry = matches[0]
    if not 0 < entry['size'] <= maximum_bytes: raise ValueError('Selected member exceeds extraction limit or is a directory')
    url, size = drive_url(index['driveFileId'])
    if size != index['archiveBytes']: raise ValueError('Source archive size changed; re-index it')
    remote = RangeFile(url, size)
    header = remote.read_range(0, 65535)
    if header[:8] != b'Rar!\x1a\x07\x01\x00': raise ValueError('Expected RAR5 archive')
    # Preserve the main block, whose end is also the first file-header offset.
    first = min(row['offset'] for row in index['files'])
    if not 8 < first <= len(header): raise ValueError('Invalid main RAR header')
    start = int(entry['offset'])
    file_header = remote.read_range(start, min(size-1, start+511))
    header_size, offset = vint(file_header, 4)
    total_header = header_size + offset
    if total_header > 1048576: raise ValueError('Unbounded RAR file header')
    block = remote.read_range(start, start+total_header+int(entry['packed'])-1)
    end = b'\x03\x05\x00\x00'
    end = struct.pack('<I', zlib.crc32(end)) + end
    result = None
    with libarchive.memory_reader(header[:first]+block+end) as archive:
        for item in archive:
            if str(item.pathname) != member: raise ValueError('Unexpected archive member')
            data = bytearray()
            for chunk in item.get_blocks():
                data.extend(chunk)
                if len(data) > maximum_bytes: raise ValueError('Decoded member exceeds extraction limit')
            if len(data) != entry['size']: raise ValueError('Decoded member size mismatch')
            if entry.get('crc32') and f'{zlib.crc32(data):08x}' != entry['crc32']: raise ValueError('Decoded member CRC mismatch')
            result = bytes(data)
    if result is None: raise ValueError('RAR decoder did not return requested member')
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(result)
    proof = {'archive': index['driveFileId'], 'sourcePath': member, 'bytes': len(result), 'sha256': hashlib.sha256(result).hexdigest()}
    output.with_suffix(output.suffix+'.origin.json').write_text(json.dumps(proof, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(proof, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    index = commands.add_parser('index');index.add_argument('drive_file_id');index.add_argument('output', type=Path)
    extract = commands.add_parser('extract');extract.add_argument('index', type=Path);extract.add_argument('member');extract.add_argument('output', type=Path)
    args = parser.parse_args()
    if args.command == 'index': write_index(args.drive_file_id, args.output)
    else: extract_entry(args.index, args.member, args.output)


if __name__ == '__main__': main()
