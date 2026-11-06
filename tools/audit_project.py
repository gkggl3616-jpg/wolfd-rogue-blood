"""Hash every project file and check literal Godot resource dependencies without executing assets."""
from collections import Counter
import datetime
import gzip
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[1]
REFERENCE=re.compile(r'''["'](res://[^"'\r\n]+)["']''')
TEXT={'.gd','.tscn','.tres','.godot','.json'}
# Exact negative fixtures and write-only reports in excluded QA scripts.
# Keep them in the evidence instead of reporting them as missing game assets.
TEST_REFERENCES={
    ('godot/tests/combat_continuation.gd','res://missing-character.glb'):'negative_model_fixture',
    ('godot/tests/pc_reference_expansion.gd','res://not-a-reward.png'):'negative_reward_fixture',
    ('godot/tests/persistence.gd','res://__missing_unbound_tattoo__.png'):'negative_tattoo_fixture',
    ('godot/tests/human_reference.gd','res://../docs/human-reference-validation.json'):'test_report_output',
    ('godot/tests/pc_reference_expansion.gd','res://../docs/pc-reference-expansion-validation.json'):'test_report_output',
    ('godot/tests/round_equipment_gifts.gd','res://../docs/round-equipment-gift-validation.json'):'test_report_output',
}


def resource_path(reference):
    path=(ROOT/'godot'/reference.removeprefix('res://')).resolve()
    return path if path.is_relative_to((ROOT/'godot').resolve()) else None


def run():
    names=subprocess.run(['rg','--files','--hidden','-0','-g','!.git','-g','!.godot','-g','!__pycache__',
                          '-g','!docs/project-file-audit.jsonl.gz','-g','!docs/project-file-audit-summary.json','.'],cwd=ROOT,stdout=subprocess.PIPE,check=True).stdout.split(b'\0')
    files=sorted({name.decode().removeprefix('./') for name in names if name})
    issues=[];expected=[];types=Counter();total=0;references=0;windows=[];models=0
    output=ROOT/'docs/project-file-audit.jsonl.gz'
    with gzip.open(output,'wt',encoding='utf-8') as report:
        for name in files:
            path=ROOT/name
            if not path.is_file():continue
            sha=hashlib.sha256();size=0;head=b''
            with path.open('rb') as stream:
                while block:=stream.read(1024*1024):
                    sha.update(block);size+=len(block)
                    if not head:head=block[:164]
            total+=size;types[path.suffix.lower()]+=1
            report.write(json.dumps({'path':name,'bytes':size,'sha256':sha.hexdigest()},separators=(',',':'))+'\n')
            if head.startswith(b'MZ'):windows.append(name)
            if path.suffix.lower() in TEXT:
                try:content=path.read_text(encoding='utf-8-sig')
                except UnicodeError:
                    issues.append({'path':name,'issue':'text_encoding'});continue
                if path.suffix=='.json':
                    try:json.loads(content)
                    except json.JSONDecodeError as exc:issues.append({'path':name,'issue':'json_syntax','line':exc.lineno})
                for reference in sorted(set(REFERENCE.findall(content))) if path.is_relative_to(ROOT/'godot') else []:
                    if any(token in reference for token in ['%','{','*']) or reference.startswith('res://.godot/'):continue
                    if not Path(reference).suffix:continue
                    reason=TEST_REFERENCES.get((name,reference))
                    if reason:
                        expected.append({'path':name,'resource':reference,'reason':reason})
                        continue
                    references+=1;target=resource_path(reference)
                    if target is None or not target.exists():issues.append({'path':name,'issue':'missing_literal_resource','resource':reference})
            elif path.suffix.lower()=='.glb':
                models+=1
                if len(head)<20 or head[:4]!=b'glTF' or struct.unpack_from('<II',head,4)!=(2,size):
                    issues.append({'path':name,'issue':'glb_header'})
                else:
                    length,kind=struct.unpack_from('<II',head,12)
                    if kind!=0x4e4f534a or length>size-20:issues.append({'path':name,'issue':'glb_json_chunk'})
                    else:
                        with path.open('rb') as stream:stream.seek(20);document=json.loads(stream.read(length))
                        for group in ['buffers','images']:
                            for record in document.get(group,[]):
                                uri=record.get('uri','')
                                if uri and not uri.startswith('data:') and not (path.parent/uri).is_file():issues.append({'path':name,'issue':'missing_glb_dependency','resource':uri})
            elif path.suffix.lower()=='.png' and not head.startswith(b'\x89PNG\r\n\x1a\n'):issues.append({'path':name,'issue':'png_header'})
    summary={'schemaVersion':1,'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'filesHashed':len(files),'bytesRead':total,
             'fileTypes':dict(types),'literalResourceReferencesChecked':references,'glbHeadersChecked':models,'issues':issues,'expectedTestReferences':expected,
             'windowsExecutablesInProject':windows,'runtimeBehaviorValidated':False,'originalPcPixelEquivalenceValidated':False,
             'scope':'Every nonignored repository file read and SHA-256 hashed; Godot literal resource paths, JSON syntax, GLB containers and PNG headers checked. Git objects, generated caches and this audit output are excluded.'}
    (ROOT/'docs/project-file-audit-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({k:v for k,v in summary.items() if k not in {'fileTypes','issues'}},ensure_ascii=False,indent=2))
    print('issues:',len(issues))
    return summary


if __name__=='__main__':run()
