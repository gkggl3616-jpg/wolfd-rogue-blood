"""Capture and bind real Godot/OpenGL screenshots to the current runtime."""
import argparse, hashlib, json, os, pathlib, re, subprocess
from validate_mobile import code_fingerprint
ROOT=pathlib.Path(__file__).resolve().parents[1]
SUITES={
 'update020':('visual_020','update-020','update-020-visual-validation.json',9),
 'update019':('visual_019','update-019','update-019-visual-validation.json',12),
 'update018':('visual_018','update-018','update-018-visual-validation.json',14),
 'update017':('visual_017','update-017','update-017-visual-validation.json',18),
 'update016':('visual_016','update-016','update-016-visual-validation.json',10),
 'update015':('visual_015','update-015','update-015-visual-validation.json',10),
 'human':('visual_human_reference','human-014','human-visual-validation.json',3),
 'mobile':('visual_mobile','pc-native','mobile-visual-validation.json',44),
 'pc':('visual_pc_reference','pc-reference','pc-reference-visual-validation.json',16),
 'equipment':('visual_equipment_gifts','equipment-013','equipment-visual-validation.json',17),
}
def capture(godot,suites):
 for suite in suites:
  script,folder,report_name,minimum=SUITES[suite];destination=ROOT/'docs/review'/folder;destination.mkdir(parents=True,exist_ok=True)
  fingerprint=code_fingerprint();print('Capturing '+suite,flush=True)
  result=subprocess.run([str(godot),'--path',str(ROOT/'godot'),'--rendering-method','gl_compatibility','--audio-driver','Dummy','--fixed-fps','60','--script','res://tests/'+script+'.gd','--',str(destination)],text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=900)
  if result.returncode or re.search(r'(?m)^(SCRIPT ERROR:|ERROR:|WARNING:.*(?:leaked|orphan))',result.stdout):raise RuntimeError(result.stdout)
  if fingerprint!=code_fingerprint():raise RuntimeError('Runtime changed during capture')
  report=json.loads((destination/'report.json').read_text())
  if report['failures'] or len(report['captures'])<minimum:raise RuntimeError('Incomplete capture suite '+suite)
  if report.get('rendering')!='gl_compatibility':raise RuntimeError('Expected real compatibility rendering')
  for shot in report['captures']:
   path=pathlib.Path(shot['path']);shot['path']=str(path.relative_to(ROOT));shot['sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
   if not shot['saved'] or path.stat().st_size<1000:raise RuntimeError('Missing/empty capture '+str(path))
  report['runtimeCodeSha256']=fingerprint
  (ROOT/'docs'/report_name).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
  (destination/'report.json').unlink()
  print(suite+': '+str(len(report['captures']))+' real captures, no errors',flush=True)
if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--godot',type=pathlib.Path,required=True);parser.add_argument('--suites',nargs='+',choices=SUITES,default=list(SUITES));args=parser.parse_args()
 try:capture(args.godot,args.suites)
 except (OSError,ValueError,RuntimeError,subprocess.SubprocessError) as error:parser.exit(2,str(error)+'\n')
