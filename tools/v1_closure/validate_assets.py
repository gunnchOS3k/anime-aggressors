"""Validate exported skin/clip contracts without claiming authored animation or taste."""
import hashlib,json,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];ART=ROOT/'artifacts/v1_closure'
manifest=json.loads((ART/'review/asset_manifest.json').read_text())
inv=json.loads((ROOT/'data/bibles/animation_inventory_v1.json').read_text())
required={s['id'] for c in inv['categories'] for s in c['slots']}
expressions={'battle_intent','attack_effort','pain','shock','fear','grief','determination','victory','defeat','cinematic_closeup'}
errors=[];rows=[]
for row in manifest['assets']:
 p=ROOT/row['path'];d=p.read_bytes();n=struct.unpack_from('<I',d,12)[0];g=json.loads(d[20:20+n]);names={a['name'] for a in g['animations']};missing=required-names
 joints=g['skins'][0]['joints'];unskinned=[i for i,mesh in enumerate(g['meshes']) if any('JOINTS_0' not in primitive['attributes'] for primitive in mesh['primitives'])]
 contaminated=[name for name in names if any(name.startswith(clip+'.') for clip in required)]
 targets={name for mesh in g['meshes'] for name in mesh.get('extras',{}).get('targetNames',[])}
 morph_meshes=sum(bool(mesh.get('extras',{}).get('targetNames')) for mesh in g['meshes'])
 if expressions-targets:errors.append({'path':row['path'],'missing_facial_morphs':sorted(expressions-targets)})
 if missing:errors.append({'path':row['path'],'missing_slots':sorted(missing)})
 if len(joints)!=22 or unskinned:errors.append({'path':row['path'],'joints':len(joints),'unskinned_meshes':unskinned})
 if contaminated:errors.append({'path':row['path'],'contaminated_clips':contaminated})
 if hashlib.sha256(d).hexdigest()!=row['sha256']:errors.append({'path':row['path'],'hash_mismatch':True})
 rows.append({'path':row['path'],'joints':len(joints),'semantic_slot_candidates':len(required)-len(missing),'total_import_tracks':len(names),'unskinned_meshes':unskinned,'facial_morph_names':sorted(targets),'morph_meshes':morph_meshes,'source_binding_tracks':sorted(name for name in names if '.' in name)})
payload={'ok':not errors and len(rows)==64,'assets':len(rows),'errors':errors,'rows':rows,'scope':'GLB hashes, 22-joint skins, 111 semantic slot candidates, ten facial morph targets, no inherited suffixed semantic clips. Additional exporter object binding tracks listed separately; not authored motion approval.','ANIMATION_TASTE_HUMAN_PASS':False}
(ART/'glb_structural_evidence.json').write_text(json.dumps(payload,indent=2)+'\n');print('GLB_CONTRACT',payload['ok'],'rows',len(rows),'errors',len(errors))
raise SystemExit(0 if payload['ok'] else 1)
