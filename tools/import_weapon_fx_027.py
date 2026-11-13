"""Decode each weapon's actual PV/HH FX fields and verify original LTB sockets."""
import argparse,concurrent.futures,gzip,hashlib,json,struct
from pathlib import Path
from ltb_metadata import inspect_ltb
from pc_source_cache import PcSourceCache
ROOT=Path(__file__).resolve().parents[1]
def weapon_rows(raw,items,models):
    result={}
    for item in items:
        pos=int(item['sourceModelOffset']);strings=[]
        def text():
            nonlocal pos
            n=struct.unpack_from('<H',raw,pos)[0];pos+=2
            if n>2048 or pos+n*2>len(raw):raise ValueError('Invalid native weapon string')
            value=raw[pos:pos+n*2].decode('utf-16le');pos+=n*2;return value
        # PV and UI: model + seven skin slots + six render styles each.
        for _ in range(28):strings.append(text())
        normalize=lambda s:s.replace('\\','/').lower().removeprefix('root/')
        assert normalize(strings[0])==normalize(models[item['model']]['source'])
        placement=struct.unpack_from('<6f',raw,pos);pos+=24
        offset=pos;pv=text();hh_model=text()
        if hh_model and not hh_model.lower().endswith('.ltb'):raise ValueError('Invalid native HH model boundary')
        # PV is independently bounded by the following HH model field.
        result[item['id']]={'sourceId':int(item['sourceId']),'sourceOffset':int(item['sourceOffset']),
            'muzzleFieldOffset':offset,'sourceModel':'root/'+normalize(strings[0]),'sourceGroup':pv,
            'sourcePosition':placement[:3],'sourceMuzzlePosition':placement[3:],'category':item['category']}
    return result
def run(cache):
    raw=gzip.decompress((ROOT/'docs/pc_sources_017/weapondata.dat.gz').read_bytes())
    library=json.loads((ROOT/'godot/assets/library/weapons.json').read_text())
    rows=weapon_rows(raw,library['items'],library['models'])
    fx=json.loads((ROOT/'godot/assets/clientfx/catalog.json').read_text());known={s.casefold():s for s in fx['groups']}
    source=PcSourceCache(ROOT/'docs/pc-archive-inventory.json.gz',cache);records={};issues=[]
    needed={item['model'] for item in library['items'] if rows[item['id']]['sourceGroup'].casefold() in known}
    def inspect(key):
        model=library['models'][key];name='root/'+model['source'].replace('\\','/').lower().removeprefix('root/')
        data=source.get(name);assert hashlib.sha256(data).hexdigest()==model['sourceSha256']
        info=inspect_ltb(data);sockets={r['name']:r for r in info['socketDefinitions']}
        flash=next((s for n,s in sockets.items() if n.casefold()=='flash'),None)
        return name,{'sourceSha256':model['sourceSha256'],'sockets':sockets,'socket':flash,'skeletonSha256':info['skeletonSha256'],'bones':info['bones']}
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        futures={pool.submit(inspect,k):k for k in sorted(needed)}
        for future in concurrent.futures.as_completed(futures):
            key=futures[future]
            try:
                name,record=future.result();records[name]=record
                if record['socket'] is None:issues.append({'model':name,'reason':'Original Flash socket absent'})
                print('VERIFIED_WEAPON_MODEL',len(records),'/',len(needed),name,flush=True)
            except Exception as error:issues.append({'model':library['models'][key]['source'],'reason':str(error)})
    items={};bindings={};used={}
    for ident,row in rows.items():
        group=known.get(row['sourceGroup'].casefold(),'');record=records.get(row['sourceModel'],{})
        result=dict(row,group=group,sourceSha256=record.get('sourceSha256',''),particleScaleAdapter=1.0)
        if row['sourceGroup'] in ('','EffectMuzzle'):result['noSourceMuzzle']=True
        elif group and record.get('socket'):
            result.update(socket=record['socket'],sockets=record['sockets']);used.setdefault(row['sourceModel'],set()).add(group)
        else:result['unresolved']='Missing source group' if not group else 'Missing verified original Flash socket'
        items[ident]=result
    for ident,item in items.items():
        if item.get('socket') and len(used.get(item['sourceModel'],[]))==1:bindings[item['sourceModel']]=item
    # Preserve the existing independent default AK-47 association.
    previous=json.loads((ROOT/'godot/assets/weapons/muzzle-bindings.json').read_text())
    for source_name,record in previous.get('bindings',{}).items():bindings.setdefault(source_name,record)
    result={'schemaVersion':2,'weaponTableSha256':hashlib.sha256(raw).hexdigest(),'items':items,'bindings':bindings,
        'models':records,'scope':'Exact PV FX field of all native weapon records; original model hashes and per-socket bone transforms. No invented FX for empty/placeholder definitions.','issues':issues}
    (ROOT/'godot/assets/weapons/muzzle-bindings.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    proof={'weaponTableSha256':result['weaponTableSha256'],'records':len(rows),'verifiedModels':len(records),
        'boundItems':sum('socket' in x for x in items.values()),'noSourceMuzzle':sum(x.get('noSourceMuzzle',False) for x in items.values()),
        'unresolved':[{'item':k,'group':v['sourceGroup'],'reason':v['unresolved']} for k,v in items.items() if 'unresolved' in v], 'modelIssues':issues,
        'recordLayout':'28 UTF-16LE strings (PV/UI model, 7 skins, 6 render styles), 6 float32 placement values, PV FX string, HH model string; exact sourceModelOffset and model identity checked for every item.'}
    (ROOT/'docs/weapon-fx-source-027.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n');print('WEAPON_FX_RESULT',json.dumps({k:v for k,v in proof.items() if k not in ['unresolved','modelIssues','recordLayout']}),flush=True)
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('cache',type=Path);run(p.parse_args().cache)
