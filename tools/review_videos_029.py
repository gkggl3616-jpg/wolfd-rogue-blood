"""Reproduce native-sized five-second screenshots from locally downloaded reference videos."""
import argparse,json,pathlib,subprocess,hashlib,re,math,concurrent.futures
from PIL import Image,ImageDraw
ROOT=pathlib.Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--media-root',type=pathlib.Path,required=True);p.add_argument('--output',type=pathlib.Path,required=True);args=p.parse_args();OUT=args.output;OUT.mkdir(parents=True,exist_ok=True)
sources=json.loads((ROOT/'docs/video-audit-026.json').read_bytes())['sources']
paths={**{f'old{i}':args.media_root/f'drive-videos/video-{i}/original.mp4' for i in range(1,5)},**{f'new{i}':args.media_root/f'new-wolf-videos/video-{i}/original.mp4' for i in [1,2]}}
def run(source):
 key=source['key'];src=paths[key];assert hashlib.sha256(src.read_bytes()).hexdigest()==source['sha256'];base=OUT/key;base.mkdir(exist_ok=True);frames=base/'frames';frames.mkdir(exist_ok=True)
 log=base/'decode.log'
 with log.open('w') as out:
  subprocess.run(['ffmpeg','-hide_banner','-threads','1','-i',str(src),'-an','-vf',"select='gte(t,selected_n*5)',showinfo",'-fps_mode','vfr','-q:v','2','-start_number','0','-y',str(frames/'%05d.jpg')],stdout=subprocess.DEVNULL,stderr=out,check=True)
 times=[float(x) for x in re.findall(r'\bn:\s*\d+.*?pts_time:([\d.]+)',log.read_text())];files=sorted(frames.glob('*.jpg'));assert len(files)==len(times)==math.ceil(source['durationSeconds']/5),(key,len(files),len(times));entries=[]
 for i,(p,t) in enumerate(zip(files,times)):
  assert 0<=t-i*5<.06,(key,i,t)
  entries.append({'gridSecond':i*5,'actualPtsSecond':t,'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
 sheets=base/'sheets';sheets.mkdir(exist_ok=True)
 for start in range(0,len(files),16):
  group=files[start:start+16];w=400;h=225;image=Image.new('RGB',(w*4,(h+25)*math.ceil(len(group)/4)),(15,15,15));draw=ImageDraw.Draw(image)
  for j,p in enumerate(group):
   original=Image.open(p);original.thumbnail((w,h));x=j%4*w;y=j//4*(h+25);image.paste(original,(x,y+25));t=times[start+j];draw.text((x+5,y+5),f'{key} #{start+j:03d} {int(t)//60:02d}:{t%60:05.2f}',fill='white')
  image.save(sheets/f'{start//16:03d}.jpg',quality=92)
 report={**source,'localOriginal':str(src),'sampleIntervalSeconds':5,'fullNativeDecodeCompleted':True,'continuousRealtimeHumanPlayback':False,'everyFrameIndividuallyVerified':False,'captures':entries,'sheets':[str(p) for p in sorted(sheets.glob('*.jpg'))]};(base/'manifest.json').write_text(json.dumps(report,indent=2));print('RECHECK_029_EXTRACTED',key,len(files),'frames',len(report['sheets']),'pages',flush=True);return report
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:result=list(pool.map(run,sources))
(OUT/'manifest.json').write_text(json.dumps({'sources':result,'totalFrames':sum(len(s['captures']) for s in result),'totalSeconds':sum(s['durationSeconds'] for s in result)},indent=2))
print('ALL_FIVE_SECOND_FRAMES_READY',sum(len(s['captures']) for s in result),flush=True)
