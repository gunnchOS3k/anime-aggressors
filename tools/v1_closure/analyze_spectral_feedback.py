"""Build owner review from observed collision traces; missing evidence stays missing."""
import json,csv,subprocess,hashlib,statistics,itertools
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/spectral_feedback'
IDS=['ember-vale','rook-ironside','juno-spark','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang']
FAMILIES=['turbulent combustion','compression fractures','branching voltage','pressure crescents','faceted crystals','orbital collapse','phase seams','subtractive aperture','constructed radiance']
index=json.loads((OUT/'capture_index.json').read_text());movies=index['movies'];captures=[]
for row in movies:
 data=json.loads((OUT/'captures'/row['label']/'combat_capture.json').read_text());captures.append((row,data))
def damage_band(value):return 'low' if value<40 else 'medium' if value<90 else 'high'
def move_class(mid):
 if '_air' in mid:return 'aerial'
 if mid=='heavy_attack':return 'heavy'
 if mid=='neutral_special_projectile':return 'projectile'
 return 'light' if mid in ['jab_1','jab_2','jab_finisher','forward_tilt','up_tilt','down_tilt','dash_attack'] else 'other'
combo=[]
for fid,band,category in itertools.product(IDS,['low','medium','high'],['light','heavy','aerial','projectile']):
 attempts=[];hits=[];blocks=[];follow=[]
 for row,data in captures:
  if row['mode']!='active' or row['fighter']!=fid:continue
  for event in data['moves']:
   if event['fighter']==fid and move_class(event['move'])==category:attempts.append({'capture':row['label'],'frame':event['movie_frame'],'initial_fixture_band':row['band']})
  for c in data['contacts']:
   if c['attacker']!=fid or move_class(c['move'])!=category or damage_band(c['damage_before'])!=band:continue
   item={'capture':row['label'],'frame':c['movie_frame'],'move':c['move'],'damage_before':c['damage_before'],'result':c['result'],'launch':c['launch'],'hitstop_frames':c['hitstop_frames'],'hitstun_seconds':c['hitstun_seconds']}
   if c['result']=='hit':hits.append(item)
   else:blocks.append(item)
   if c['follow_up_before_control'] and c['result']=='hit':follow.append(item)
 combo.append({'fighter':fid,'actual_damage_band':band,'move_class':category,'all_band_public_attempts':len(attempts),'confirmed_hits':len(hits),'defensive_contacts':len(blocks),'followups_before_control':len(follow),'status':'OBSERVED' if hits or blocks else 'NO_CONFIRMED_CONTACT_IN_CAPTURE','evidence':hits+blocks,'successful_followups':follow})
(OUT/'COMBO_MATRIX.json').write_text(json.dumps(combo,indent=2)+'\n')
with (OUT/'COMBO_MATRIX.csv').open('w') as f:
 writer=csv.DictWriter(f,fieldnames=[k for k in combo[0] if k not in ['evidence','successful_followups']]);writer.writeheader();writer.writerows({k:v for k,v in r.items() if k not in ['evidence','successful_followups']} for r in combo)
matrix=[]
for fid,family in zip(IDS,FAMILIES):
 records=[(r,d) for r,d in captures if r['fighter']==fid and r['mode']!='before']
 kinds={e['kind'] for _,d in records for e in d['presentation_events']}
 contacts=[c for _,d in records for c in d['contacts'] if c['attacker']==fid]
 for effect,kind in [('contact',0),('shield',1),('armor',10),('charge',2),('release',9),('flight',3),('dissipation',5),('hurt',8),('launch_smoke',4),('confirmed_stock_loss',7)]:
  matrix.append({'fighter':fid,'grammar':family,'effect':effect,'runtime':'IMPLEMENTED','source_fixture':'PASS' if effect!='confirmed_stock_loss' else 'AUTHENTIC_STOCK_LOSS_HOOK','current_renderer':'OBSERVED' if kind in kinds else 'NOT_CAPTURED','human_approved':False})
 matrix.append({'fighter':fid,'grammar':family,'effect':'terrain_collision','runtime':'CALLBACK_WIRED; existing projectile mask 6 excludes stage layer 1','source_fixture':'NOT_TERRAIN_AUTHORITY','current_renderer':'NOT_CAPTURED','human_approved':False})
 matrix.append({'fighter':fid,'grammar':family,'effect':'parry_clash','runtime':'UNSUPPORTED_BY_EXISTING_GAMEPLAY','source_fixture':'NO_FABRICATED_OUTCOME','current_renderer':'NOT_APPLICABLE','human_approved':False})
with (OUT/'FIGHTER_EFFECT_MATRIX.csv').open('w') as f:
 writer=csv.DictWriter(f,fieldnames=matrix[0].keys());writer.writeheader();writer.writerows(matrix)
perf=[]
for row,data in captures:
 if row['mode']=='before':continue
 values=data['pool'].get('cpu_update_us',[]);process=[s['process_time_s']*1000 for s in data['samples']];physics=[s['physics_time_s']*1000 for s in data['samples']]
 perf.append({'capture':row['label'],'mesh_pool':{k:v for k,v in data['pool'].items() if k!='cpu_update_us'},'vfx_cpu_update_us_median':statistics.median(values) if values else None,'vfx_cpu_update_us_max':max(values) if values else None,'engine_process_ms_median':statistics.median(process) if process else None,'engine_process_ms_max':max(process) if process else None,'engine_physics_ms_median':statistics.median(physics) if physics else None,'measurement':'Mac Apple M2 Compatibility; offline fixed-cadence MovieWriter; not sustained FPS or device certification'})
(OUT/'PERFORMANCE.json').write_text(json.dumps(perf,indent=2)+'\n')
# Frame sheets use actual movie frame numbers from resolution; no re-created effects.
sheets=[];(OUT/'contact_sheets').mkdir(exist_ok=True)
for row,data in captures:
 if row['fighter'] not in ['ember-vale','juno-spark'] or row['mode']!='active':continue
 chosen=[]
 for result in ['hit','shield']:
  item=next((c for c in data['contacts'] if c['attacker']==row['fighter'] and c['result']==result),None)
  if item:chosen.append(item)
 item=next((c for c in data['contacts'] if c['attacker']==row['fighter'] and c['follow_up_before_control'] and c['result']=='hit'),None)
 if item and item not in chosen:chosen.append(item)
 for n,c in enumerate(chosen):
  frame=c['movie_frame'];frames=[max(0,frame+x) for x in [-3,-1,0,2,6,18]]
  output=OUT/'contact_sheets'/f"{row['label']}_{n}_{c['result']}.png"
  select='+'.join(f'eq(n\\,{x})' for x in frames)
  subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',str(ROOT/row['path']),'-vf',f'select={select},scale=426:240,tile=3x2','-frames:v','1',str(output)],check=True)
  sheets.append({'path':str(output.relative_to(ROOT)),'source_sha':row['source_sha'],'source_movie':row['path'],'contact':c,'frames_left_to_right_then_down':frames,'times_s':[round(x/60,4) for x in frames],'cadence':60,'note':'actual renderer frames; trace frame may precede displayed mesh by one process frame; inspect before/at/after directly'})
(OUT/'CONTACT_SHEETS.json').write_text(json.dumps(sheets,indent=2)+'\n')
summary={'capture_source_shas':sorted({m['source_sha'] for m in movies if m['mode']!='before'}),'movies':len(movies),'full_nine_roster':all(any(m['fighter']==fid and m['mode']=='active' for m in movies) for fid in IDS),'active_cpu_followups':sum(r['followups_before_control'] for r in combo),'combo_cells_with_contact':sum(r['status']=='OBSERVED' for r in combo),'combo_cells_without_contact':sum(r['status']!='OBSERVED' for r in combo),'ko_captures':sum(m['ko_count'] for m in movies if m['mode']!='before'),'renderer_effect_rows_observed':sum(r['current_renderer']=='OBSERVED' for r in matrix),'all_human_gates_false':True,'heavy_exports_run':False}
(OUT/'IMPLEMENTATION_SUMMARY.json').write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary))
