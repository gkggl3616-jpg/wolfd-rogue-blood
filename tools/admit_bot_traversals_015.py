"""Reject precomputed arcs that fail either direction in actual CharacterBody3D physics."""
import hashlib,json,pathlib
ROOT=pathlib.Path(__file__).resolve().parents[1];path=ROOT/'godot/assets/maps/traversals.json';records=json.loads(path.read_bytes());proof=json.loads((ROOT/'docs/bot-traversal-validation-015.json').read_bytes());assert proof['traversalsSha256']==hashlib.sha256(path.read_bytes()).hexdigest()
passed={(int(r['map']),r['link'],r['reversed']) for r in proof['landings'] if r['landingError']<0.85};rejected=[]
for record in records:
 accepted=[]
 for index,link in enumerate(record['links']):
  if all((int(record['number']),index,direction) in passed for direction in ([False,True] if link.get("bidirectional",True) else [False])):accepted.append(link)
  else:rejected.append({'map':record['number'],'candidateIndex':index,'candidate':link,'reason':'Every enabled direction must launch and land within 0.85m in actual bot collision physics'})
 record['links']=accepted;record['validation']+=' Also admitted by CharacterBody3D landing tests for every enabled direction.'
(ROOT/'docs/bot-traversal-rejections-015.json').write_text(json.dumps({'rejected':rejected,'candidateFailures':proof['failures'],'finalLinkCount':sum(len(r['links']) for r in records)},indent=2)+'\n')
path.write_text(json.dumps(records,indent=2)+'\n');print('Accepted links',sum(len(r['links']) for r in records),'rejected',len(rejected))
