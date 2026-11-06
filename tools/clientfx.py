"""Read text ClientFX definitions without discarding property curves or asset names."""
import collections,re

def parse(data):
    text=data.decode('cp1254').replace('\r\n','\n')
    groups={}
    for block in re.split(r'(?m)^\s*GroupName: ',text)[1:]:
        name=block.splitlines()[0].strip();nodes=[]
        for fx in re.split(r'(?m)^\s*FxName: ',block)[1:]:
            kind=fx.splitlines()[0].split(';')[0].strip();props=collections.defaultdict(list)
            for key,kind_id,value in re.findall(r'PropName: (.*?)\n\s*Type: (\d+)\n\s*\w+: (.*)',fx):
                key=key.strip();value=value.strip();kind_id=int(kind_id)
                if kind_id==1:value=int(value)
                elif kind_id==2:value=float(value)
                elif kind_id in (4,5,6):value=list(map(float,value.split()))
                props[key].append(value)
            nodes.append({'type':kind,'start':float(re.search(r'StartTime: ([\d.]+)',fx)[1]),'end':float(re.search(r'EndTime: ([\d.]+)',fx)[1]),'properties':dict(props)})
        if name in groups:raise ValueError('Duplicate effect '+name)
        groups[name]={'nodes':nodes}
    if not groups:raise ValueError('No ClientFX groups decoded')
    return groups

def value(node,key,default=None):return node['properties'].get(key,[default])[0]
def path_value(node,key):
    result=value(node,key,'')
    return result.split('|')[-1].replace('\\','/').lower() if isinstance(result,str) and result not in ('','...') else ''

def parse_butes(data):
    text=re.sub(r'/\*.*?\*/','',data.decode('cp1254'),flags=re.S);result={}
    for block in re.split(r'(?m)^\s*\[',text)[1:]:
        name,body=block.split(']',1);values={}
        for key,value in re.findall(r'(?m)^\s*(\w+)\s*=\s*(.*?)\s*$',body):
            if value.startswith('"'):value=value.split('"',2)[1]
            elif value.startswith('<'):
                value=[float(v.strip()) for v in value.split('>',1)[0][1:].split(',')]
            else:
                value=value.split('//',1)[0].strip()
                try:value=float(value) if any(c in value.lower() for c in ['.','e']) else int(value)
                except ValueError:pass
            values[key]=value
        result[name.strip()]=values
    return result
