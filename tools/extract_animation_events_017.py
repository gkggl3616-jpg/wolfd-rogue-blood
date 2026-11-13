"""Preserve source animation event strings and named sockets from the actual imported donors."""
import argparse,gzip,hashlib,json,pathlib
from pc_source_cache import PcSourceCache
from ltb_metadata import inspect_ltb
ROOT=pathlib.Path(__file__).resolve().parents[1]
def normalize(path):
 p=path.replace('\\','/').lower()
 return 'root/'+p.split('/root/')[-1].removeprefix('root/')
def run(cache):
 source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',cache);paths=set()
 for char in json.loads((ROOT/'godot/assets/library/characters.json').read_bytes())['characters']:
  for form in ['human','wolf']:
   paths.add(normalize(char[form]['donor']))
   for action in char[form].get('sourceActions',{}).values():
    if action.get('donor'):paths.add(normalize(action['donor']))
 for row in json.loads((ROOT/'godot/assets/mutations/catalog.json').read_bytes())['models']:paths.add(normalize(row['donor']))
 result={};failures=[]
 for path in sorted(paths):
  try:
   b=source.get(path);info=inspect_ltb(b);result[path]=dict(sourceSha256=hashlib.sha256(b).hexdigest(),sockets=info['socketDefinitions'],animations={a['name']:dict(durationMs=a['durationMs'],events=a['keyEvents']) for a in info['animations']})
   print('EVENT_DONOR',path,flush=True)
  except Exception as e:failures.append(dict(source=path,error=str(e)))
 out=dict(schemaVersion=1,models=result,failures=failures)
 p=ROOT/'docs/animation-events-source-017.json.gz';p.write_bytes(gzip.compress(json.dumps(out,ensure_ascii=False,separators=(',',':')).encode(),mtime=0))
 print('EVENT_DONOR_RESULT',len(result),'failures',failures,flush=True)
if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('cache',type=pathlib.Path);run(p.parse_args().cache)
