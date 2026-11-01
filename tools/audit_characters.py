"""Audit source assets; never admit an unverified character to a runtime roster."""
import argparse
import collections
import gzip
import hashlib
import json
from pathlib import Path
import posixpath
import re
from ltb_metadata import inspect_ltb
from scan_xfs import unpack_index, recover_entry

ROOT=Path(__file__).resolve().parents[1]

def normalize(path):
    return posixpath.normpath(re.sub('/+','/',path.replace('\\','/'))).casefold()

def parse_model_definitions(data):
    text=data.decode('cp1254',errors='replace')
    text=re.sub(r'/\*.*?\*/','',text,flags=re.S)
    text=re.sub(r'//[^\r\n]*','',text)
    result=[]
    for match in re.finditer(r'^\[([^\]]+)\]([^\[]*)',text,re.M):
        if not re.fullmatch(r'Model\d+',match[1]):continue
        values={key.strip():value.strip().strip('"') for key,value in re.findall(r'^\s*(\w+)\s*=\s*([^\r\n]+)',match[2],re.M)}
        result.append(dict(id=match[1],name=values.get('Name',match[1]),model=values.get('ModelFile',''),values=values))
    return result

def identity(name):
    return re.sub(r'[^a-z0-9]','',name.casefold().replace('wolf',''))

def check_roster(roster):
    """Fail closed: a report candidate is not an approved, imported game asset."""
    reasons=[]
    if not isinstance(roster,dict):return ['Roster must be an object']
    if roster.get('schemaVersion')!=1: reasons.append('Unsupported roster schema')
    if not isinstance(roster.get('characters'),list):return reasons+['Characters must be an array']
    seen=set()
    for character in roster.get('characters',[]):
        if not isinstance(character,dict):reasons.append('Character must be an object');continue
        ident=character.get('id')
        if not isinstance(ident,str) or not ident or ident in seen: reasons.append('Missing or duplicate character id')
        seen.add(str(ident))
        for form in ('human','wolf'):
            asset=character.get(form)
            if not isinstance(asset,dict): reasons.append(f'{ident}: {form} form missing');continue
            for field in ('modelSha256','skeletonSha256','animationSetSha256'):
                if not re.fullmatch('[a-f0-9]{64}',str(asset.get(field,''))):reasons.append(f'{ident}: {form} {field} missing')
            if not asset.get('animationClips'):reasons.append(f'{ident}: {form} animation clips missing')
            if asset.get('missingDependencies') or asset.get('skeletonCompatible') is not True:reasons.append(f'{ident}: {form} dependencies/rig not verified')
        if character.get('engineImported') is not True or character.get('visualValidation')!='passed': reasons.append(f'{ident}: engine import and visual validation required')
        if character.get('pairConfirmed') is not True:reasons.append(f'{ident}: human/wolf pair unconfirmed')
    return reasons

def audit(folder):
    archive=folder/'wolf.xfs'
    if not archive.exists():archive=folder/'WolfRogue.xfs'
    entries=unpack_index(archive); lookup={normalize(e['path']):e for e in entries}
    definition=lookup['root/attributes/modelbutes.txt']
    definitions=parse_model_definitions(recover_entry(archive,definition))
    models=[]
    for entry in entries:
        if not normalize(entry['path']).startswith('root/wt_chars/') or Path(entry['path']).suffix.casefold()!='.ltb':continue
        result=dict(path=entry['path'],size=entry['size'])
        try:
            data=recover_entry(archive,entry)
            result.update(status='parsed',sha256=hashlib.sha256(data).hexdigest(),**inspect_ltb(data))
        except (ValueError,UnicodeError,IndexError) as error:result.update(status='quarantined',error=str(error))
        models.append(result)
    model_lookup={normalize(m['path']):m for m in models}
    dependencies=[]
    for model in models:
        model['dependencies']=[]
        for reference in model.get('childModels',[]):
            target=normalize(posixpath.join(posixpath.dirname(model['path']),reference.replace('\\','/')))
            donor=model_lookup.get(target)
            edge=dict(model=model['path'],reference=reference,resolved=donor['path'] if donor else None,exists=donor is not None)
            if donor and donor['status']=='parsed':
                edge['skeletonExact']=model.get('skeletonSha256')==donor['skeletonSha256']
                edge['bindPoseExact']=model.get('bindPoseSha256')==donor['bindPoseSha256']
                edge['missingBones']=sorted(set(b['name'] for b in donor['bones'])-set(b['name'] for b in model['bones']))
                edge['animationCount']=donor['animationCount']
            model['dependencies'].append(edge);dependencies.append(edge)
    records=[]
    for item in definitions:
        model=model_lookup.get(normalize('Root/'+item['model']))
        missing=[]
        for key,value in item['values'].items():
            if re.fullmatch(r'(Skin|RenderStyle)\d+',key) and value and normalize('Root/'+value) not in lookup:missing.append(dict(field=key,path=value))
        children=model.get('dependencies',[]) if model else []
        clips=[]
        if model:
            clips=[a['name'] for a in model.get('animations',[]) if a['frames']>1 and not a['name'].startswith('@')]
            for edge in children:
                donor=model_lookup.get(normalize(edge['resolved'] or ''))
                if donor:clips.extend(a['name'] for a in donor.get('animations',[]) if a['frames']>1 and not a['name'].startswith('@'))
        reasons=[]
        if not model:reasons.append('model_missing')
        elif model['status']!='parsed':reasons.append('model_parse_failed')
        if missing:reasons.append('skin_or_render_style_missing')
        if any(not edge.get('exists') for edge in children):reasons.append('animation_model_missing')
        if any(edge.get('skeletonExact') is not True for edge in children):reasons.append('skeleton_requires_review')
        if not clips:reasons.append('playable_animation_missing')
        rec=dict(id=item['id'],name=item['name'],form='wolf' if 'wolf' in (item['name']+' '+item['model']).casefold() else 'human',model=item['model'],modelExists=model is not None,animationClipCount=len(set(clips)),missingAssets=missing,issues=reasons,identity=identity(item['name']),meshIdentity=identity(Path(item['model'].replace('\\','/')).stem),skeletonSha256=model.get('skeletonSha256') if model else None,included=False)
        records.append(rec)
    for record in records:
        opposite=[r for r in records if r['form']!=record['form'] and ((r['identity']==record['identity'] and r['identity']) or (r['meshIdentity']==record['meshIdentity'] and r['meshIdentity']))]
        unique={normalize(r['model']) for r in opposite}
        record['counterpartIds']=[r['id'] for r in opposite]
        record['counterpartPaths']=sorted({r['model'] for r in opposite})
        if not opposite:record['issues'].append('counterpart_not_found')
        elif len(unique)>1:record['issues'].append('counterpart_ambiguous')
    own_issues={r['id']:tuple(r['issues']) for r in records}
    for record in records:
        if record['counterpartIds'] and any(own_issues[ident] for ident in record['counterpartIds']):
            record['issues'].append('counterpart_requires_review')
        record['structuralCandidate']=not record['issues']
        record['runtimeStatus']='excluded_pending_engine_and_visual_validation'
    skeletons=collections.defaultdict(list)
    for model in models:
        if model['status']=='parsed':skeletons[model['skeletonSha256']].append(model['path'])
    summary=dict(archivesEntries=len(entries),modelDefinitions=len(records),uniqueReferencedModels=len({normalize(r['model']) for r in records}),characterDirectoryModels=len(models),parsedModels=sum(m['status']=='parsed' for m in models),dependencyEdges=len(dependencies),missingChildModels=sum(not e['exists'] for e in dependencies),exactSkeletonEdges=sum(e.get('skeletonExact') is True for e in dependencies),differentSkeletonEdges=sum(e.get('skeletonExact') is False for e in dependencies),differentBindPoseEdges=sum(e.get('bindPoseExact') is False for e in dependencies),skeletonGroups=len(skeletons),structuralCandidates=sum(r['structuralCandidate'] for r in records),approvedCharacters=0,issues=dict(collections.Counter(issue for r in records for issue in r['issues'])))
    full=dict(schemaVersion=1,title='Wolf Rogue Blood',scope='Statik model/iskelet/animasyon denetimi. Mesh geometrisi ve animasyonların görsel sonucu oyun motorunda doğrulanmadı.',summary=summary,models=models,definitions=records,dependencies=dependencies,skeletonGroups=dict(skeletons))
    catalog=dict(schemaVersion=1,title='Wolf Rogue Blood',summary=summary,scope=full['scope'],characters=records,androidBuild=dict(status='blocked',apkProduced=False,blockers=['editable_game_engine_project_missing','android_game_runtime_missing','converted_and_visually_validated_assets_missing','account_and_gameplay_server_source_missing']))
    return full,catalog

def main():
    parser=argparse.ArgumentParser();parser.add_argument('folder',type=Path);args=parser.parse_args()
    full,catalog=audit(args.folder)
    raw=json.dumps(full,ensure_ascii=False,separators=(',',':')).encode()
    (ROOT/'docs/character-audit.json.gz').write_bytes(gzip.compress(raw,mtime=0))
    (ROOT/'web/characters.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
    (ROOT/'docs/character-summary.json').write_text(json.dumps(full['summary'],ensure_ascii=False,indent=2),encoding='utf-8')
    report=['# Wolf Rogue Blood — karakter denetimi','',full['scope'],'','## Sayımlar','']
    report += [f'- {key}: {value}' for key,value in full['summary'].items() if not isinstance(value,dict)]
    report += ['','Model kayıtları kostüm/varyantları ve NPC tanımlarını da kapsar. Bunlar benzersiz oynanabilir karakter sayısı değildir. Yaklaşık 130 karakter iddiası bu sayımla doğrulanmış sayılmaz.','','## Dahil edilmeyenler','','Hiçbir karakter otomatik olarak oyuna eklenmedi. İnsan/kurt eşi, model/kaplama bağımlılığı, iskelet ve oynanabilir animasyon kontrolünde sorun bulunanlar engellenir. Yapısal adaylar da motor aktarımı ve görsel test yapılana kadar onaylı kadroya giremez.','','Kemik adları ve hiyerarşisi eşitliği, dinlenme pozu eşitliği veya görsel animasyon uyumluluğu anlamına gelmez. İnsan ve kurt iskeletlerinin birbiriyle aynı olması beklenmez; her form kendi animasyon sağlayıcısıyla karşılaştırılır.','','## Kayıtlar','','| Kimlik | İsim | Form | Animasyon | Eş adayları | Sorunlar |','|---|---|---|---:|---|---|']
    for row in catalog['characters']:
        report.append(f"| {row['id']} | {row['name'].replace('|','/')} | {row['form']} | {row['animationClipCount']} | {', '.join(row['counterpartIds']) or 'yok'} | {', '.join(row['issues']) or 'Motor/görsel onay bekliyor'} |")
    report+=['','## Tekrar üretim','','`python tools/audit_characters.py "paket-klasoru"`','','LTB şema başvurusu: https://github.com/Five-Damned-Dollarz/io_scene_lithtech/blob/master/src/reader_ltb_pc.py. Ayrıştırıcı yalnızca standart kütüphane kullanır; dışarıdan indirilen kodu çalıştırmaz.']
    (ROOT/'docs/KARAKTERLER.md').write_text('\n'.join(report),encoding='utf-8')
    print(json.dumps(full['summary'],ensure_ascii=True))

if __name__=='__main__':main()
