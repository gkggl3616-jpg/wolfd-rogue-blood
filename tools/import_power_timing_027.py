"""Bind native support/energy counter fields; preserve unresolved native fields."""
import gzip,hashlib,json,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def run():
 raw=gzip.decompress((ROOT/'docs/pc_sources_020/exitemdata.dat.gz').read_bytes());pos=0;found={}
 while pos<len(raw):
  start=pos;ident=struct.unpack_from('<I',raw,pos)[0];header=raw[pos:pos+57];pos+=57
  for _ in range(2):
   size=struct.unpack_from('<H',raw,pos)[0];pos+=2;assert size<2048;pos+=size*2+4
  if ident in [19001,19002,19501,19502]:
   found[str(ident)]={'offset':start,'headerHex':header.hex(),'useLimit':struct.unpack_from('<I',header,33)[0],
    'instant':struct.unpack_from('<I',header,37)[0],'periodic':struct.unpack_from('<I',header,41)[0],
    'tickSeconds':struct.unpack_from('<I',header,45)[0],'seconds':struct.unpack_from('<I',header,49)[0],
    'cooldownSeconds':struct.unpack_from('<I',header,53)[0]}
 assert pos==len(raw) and len(found)==4
 assert [(found[k]['useLimit'],found[k]['instant'],found[k]['periodic'],found[k]['tickSeconds'],found[k]['seconds']) for k in found]==[(1,50,2,1,15),(2,100,5,1,15),(99,50,5,1,7),(99,25,2,1,10)]
 path=ROOT/'godot/assets/items/power.json';data=json.loads(path.read_text())
 for item in data['items']:
  if item['id'] not in found:continue
  native=found[item['id']];tuning=item['mobileTuning'];tuning['seconds']=native['seconds'];tuning['tickSeconds']=native['tickSeconds']
  tuning.pop('healthDrainPerMinute',None);tuning.pop('regenerationPerMinute',None)
  if item['slot']=='energy':tuning['healthDrainPercentPerTick']=native['periodic']
  else:tuning['regenerationPerTick']=native['periodic']
  item['nativeTiming']={'source':'root/wt_attributes/exitemdata.dat','sourceSha256':hashlib.sha256(raw).hexdigest(),**native}
 data['powerTimingEvidence']='docs/power-timing-source-027.json';path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 proof={'sourceSha256':hashlib.sha256(raw).hexdigest(),'records':found,
  'fields':{'33':'use limit (99: unlimited pack)','37':'instant heal or current-HP cost percent','41':'periodic heal amount or current-HP drain percent','45':'tick seconds','49':'effect duration seconds','53':'reuse delay seconds'},
  'crossChecks':['Medical instant50/100, use1/2 and duration15 agree with independent source item descriptions.','Old 13-minute recording at169.2..177.2 seconds:150,147,144,141,138,135,132,130,127=floor(150*.98^n). Game timer advances at real-time speed.','New33-minute recording: after support reaches320, cash energy and medical ticks give318,317,315=floor(h*.98+5), preserving fractional HP.'],
  'textConflict':'The translated per-minute wording conflicts with native tick fields and both recordings. Gold duration is7 in the binary, not the text10.','unresolved':['Speed +50/+100 unit and unrelated header fields remain unverified; existing speed adapters remain explicitly identified.']}
 (ROOT/'docs/power-timing-source-027.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n')
if __name__=='__main__':run()
