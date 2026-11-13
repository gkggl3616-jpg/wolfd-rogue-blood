"""Prepare source-derived anchors. Godot physics QA must approve before release."""
import json,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def main():
    rows=json.loads((ROOT/'docs/map-conversion.json').read_text(encoding='utf-8'));result=[]
    for row in rows:
        if row.get('error'):continue
        starts=[]
        for anchor in row['anchors']:
            props=anchor['properties'];pos=props.get('Pos')
            if anchor['type']!='GameStartPoint' or props.get('Locked') or not props.get('SpawnPoint',False) or not isinstance(pos,list) or len(pos)!=3 or not all(math.isfinite(v) for v in pos):continue
            rotation=props.get('Rotation',[0,0,0])
            starts.append(dict(name=props.get('Name'),team=props.get('Team'),position=[pos[0]*.016,pos[1]*.016,-pos[2]*.016],yaw=-float(rotation[1]),sourcePosition=pos,sourceRotation=rotation))
        result.append(dict(number=row['number'],previewAsset=row['previewAsset'],sha256=row['sha256'],sourceSha256=row['sourceSha256'],startPoints=starts,previewValidated=False,fullPort=False,collision='render_triangle_approximation',missingTextures=row['missingTextures'],limitations=['original_game_mode_rules_pending','interactive_world_models_pending','original_lighting_and_material_effects_pending']))
    (ROOT/'godot/assets/maps/previews.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print('Prepared previews:',len(result),'with spawn sets:',sum(bool(r['startPoints']) for r in result))

if __name__=='__main__':main()
