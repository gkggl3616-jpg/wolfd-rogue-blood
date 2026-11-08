"""Run the eight-actor encounter and bind its report to one unchanged runtime."""
import argparse,json,re,subprocess
from validate_mobile import ROOT,code_fingerprint
def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--godot',default='godot');args=parser.parse_args()
    before=code_fingerprint()
    result=subprocess.run([args.godot,'--headless','--path','godot','--fixed-fps','60','--script','res://tests/bot_squad_029.gd'],cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=120)
    print(result.stdout,end='')
    if result.returncode or re.search(r'(?m)^(SCRIPT ERROR:|ERROR:|WARNING:.*(?:leaked|orphan))',result.stdout):return 1
    path=ROOT/'docs/bot-squad-029-validation.json';report=json.loads(path.read_text())
    if not report['passed'] or before!=code_fingerprint():return 1
    report['runtimeCodeSha256']=before;path.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');return 0
if __name__=='__main__':raise SystemExit(main())
