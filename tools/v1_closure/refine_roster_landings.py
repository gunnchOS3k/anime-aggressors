"""Update onlyoriginal landing clips onall18approvedrigs; neverregeneratemodels."""
import json,hashlib,subprocess
from pathlib import Path
import build_combat_choreography as author
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/spectral_feedback/continuous_1011'
def digest(d):return hashlib.sha256(json.dumps(d,sort_keys=True,separators=(',',':')).encode()).hexdigest()
rows=[]
for fid in author.DIRECTION:
 for body in ['male','female']:
  path=ROOT/f'game-godot/data/animation/combat_choreography/{fid}_{body}.json';doc=json.loads(path.read_text());rig,h=author.rig(fid,body);assert h==doc['rig_sha256']
  old=digest({k:v for k,v in doc['clips'].items() if not k.startswith('land_')})
  for name in ['land_soft','land_hard']:doc['clips'][name]=author.make_state(rig,fid,name)
  assert old==digest({k:v for k,v in doc['clips'].items() if not k.startswith('land_')})
  path.write_text(json.dumps(doc,separators=(',',':'))+'\n')
  rows.append({'fighter':fid,'body':body,'path':str(path.relative_to(ROOT)),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'protected_rig_sha256':h,'non_landing_clips_unchanged':True,'motion_profile':author.LAND[fid],'max_baked_support_error_m':max(doc['clips'][x]['max_baked_support_error_m'] for x in ['land_soft','land_hard']),'status':'ORIGINAL_RUNTIME_LANDING_REFINEMENT_NOT_OWNER_APPROVED'})
(OUT/'LANDING_SOURCE_FILES.json').write_text(json.dumps({'parent_source_sha':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'rows':rows,'scope':'Original first-impact weight absorption, counterbalance and settleonexistingrigs; no gameplaylag/physics/geometrychanges. Offline support constraint doesnot certifyworldfloorplacement. Human qualityapprovalfalse.'},indent=2)+'\n')
print(json.dumps({'models':len(rows),'max_baked_support_error_m':max(r['max_baked_support_error_m'] for r in rows)}))
