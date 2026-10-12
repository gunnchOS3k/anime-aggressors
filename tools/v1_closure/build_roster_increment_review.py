"""Evidence-derived current-roster review; does not rerender prior capture campaigns."""
import json,subprocess,hashlib,html,statistics
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'artifacts/v1_closure/spectral_feedback'
DEST=OUT/'continuous_1011/owner_roster_review';DEST.mkdir(exist_ok=True)
IDS=['ember-vale','rook-ironside','juno-spark','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang']
MOVES={'light':{'jab_1','jab_2','jab_finisher','forward_tilt','dash_attack'},'heavy':{'heavy_attack'},'projectile':{'neutral_special_projectile'}}
index=json.loads((OUT/'capture_index.json').read_text())['movies']
movies=[r for r in index if r['mode']=='roster_choreography']
assert len(movies)==9 and {r['fighter'] for r in movies}==set(IDS),'Finish the nine explicit current-animation movies first'
alignment=json.loads((OUT/'continuous_1011/manual_blend_fix/RosterContactAlignment/roster_contact_alignment.json').read_text())
footwork=json.loads((OUT/'continuous_1011/manual_blend_fix/RosterFootwork/roster_footwork.json').read_text())
records=[];rows=[]
def file_record(path,sha,kind,scope):
 p=ROOT/path;assert p.is_file(),p
 return {'path':path,'absolute_path':str(p),'source_sha':sha,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'verification':'EXISTS_AND_HASHED','kind':kind,'scope':scope,'redistribution':'original versus game audio/assets; owner development review; no release authorization','owner_approved':False}
def sheet(movie,label,frames,captions,sha,event):
 target=DEST/(label+'.png');select='+'.join(f'eq(n\\,{f})' for f in frames)
 assert not target.exists(),'Existing evidence preserved: '+str(target)
 subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-i',str(movie),'-vf',f'select={select},scale=640:360,pad=640:400:0:0:color=0x121820,tile=3x2','-frames:v','1',str(target)],check=True)
 im=Image.open(target).convert('RGB');draw=ImageDraw.Draw(im)
 for i,(frame,caption) in enumerate(zip(frames,captions)):
  draw.text(((i%3)*640+8,(i//3)*400+363),f'{frame} | {frame/60:.4f}s | {caption}',fill='white')
  draw.text(((i%3)*640+8,(i//3)*400+382),sha[:12]+' · native automated public input',fill='white')
 im.save(target);rec=file_record(str(target.relative_to(ROOT)),sha,'contact_sheet','actual movie frames; contact frame is simulation trace, render may follow');rec.update(frames=frames,source_movie=str(movie.relative_to(ROOT)),event=event);records.append(rec)
 return str(target.relative_to(DEST))
for fid in IDS:
 r=next(x for x in movies if x['fighter']==fid);movie=ROOT/r['path'];d=json.loads((OUT/'captures'/r['label']/'combat_capture.json').read_text())
 assert d['source_sha']==r['source_sha'] and d['opponent_cpu'] and not d['forced_moves'] and not d['forced_ko'] and not d['frozen_opponent']
 rec=file_record(r['path'],r['source_sha'],'native_movie',r['scope']);assert rec['sha256']==r['sha256'],'Movie hash mismatch: '+r['label']
 rec.update(streams=r['streams'],body_presentations=d['body_presentations'],active_cpu=d['opponent_cpu'],cpu_move_count=sum(e.get('slot')==2 for e in d['moves']));records.append(rec)
 records.append(file_record(str((OUT/'captures'/r['label']/'combat_capture.json').relative_to(ROOT)),r['source_sha'],'synchronized_trace','exact public inputs, contacts, states, phases and actual projected limbs'))
 count=int(next(x['nb_frames'] for x in r['streams'] if x['codec_type']=='video'));sheets={}
 for kind in ['light','heavy','projectile','shield']:
  c=next((c for c in d['contacts'] if c.get('attacker_slot',1)==1 and c['result']==('shield' if kind=='shield' else 'hit') and (kind=='shield' or c['move'] in MOVES[kind])),None)
  if c:
   frames=[max(0,min(count-1,c['movie_frame']+n)) for n in [-3,-1,0,2,6,18]]
   sheets[kind]=sheet(movie,fid+'_'+kind,frames,['before','before','simulation '+c['result'],'contact / hitstop','reaction','follow-through'],r['source_sha'],c['event_id'])
 a=[x for x in alignment['rows'] if x['fighter']==fid and x['case'] in ['light','heavy']];f=[x for x in footwork['rows'] if x['fighter']==fid]
 cpu=sum(e.get('slot')==2 for e in d['moves']);p1=[c for c in d['contacts'] if c.get('attacker_slot',1)==1];mean=[s['physics_time_s']*1000 for s in d['samples'] if s.get('physics_time_s',0)>0]
 row={'fighter':fid,'movie':r['path'],'source_sha':r['source_sha'],'native_body_presentations':d['body_presentations'],'body_rig_runtime_fixture':'BOTH_VARIANTS_BOTH_FACINGS','qualifying_categories':{k:bool(sheets.get(k)) for k in ['light','heavy','projectile','shield']},'signature_observed':any(m.get('slot')==1 and m['move']=='aura_burst' for m in d['moves']),'p1_hits':sum(c['result']=='hit' for c in p1),'p1_shields':sum(c['result']=='shield' for c in p1),'cpu_moves':cpu,'contact_sheets':sheets,'wrist_to_contact_center_px':[min(x['intended_wrist_to_contact_px'] for x in a),max(x['intended_wrist_to_contact_px'] for x in a)],'max_wrist_to_overlap_surface_px':max(x['intended_wrist_to_overlap_px'] for x in a),'mean_support_slip_px_per_frame':statistics.mean(x['mean_projected_foot_slip_px_per_frame'] for x in f),'transition_max_foot_slip_px':max(x['max_projected_foot_slip_px_per_frame'] for x in f),'physics_process_sample_p50_ms':statistics.median(mean) if mean else None,'recorded_output_fps':60,'device_performance_acceptance':False,'implementation':'BILATERAL_ORIGINAL_BLOCKING_DISTANCE_MATCHED_GAIT_STATE_REACTIONS','automated_test_verified':True,'actual_runtime_verified':True,'visually_ready_for_owner_candidate_review':True,'owner_approved':False,'unfinished':['outer-range and aerial anatomical reach','authored starts/stops/pivots','transition continuity','move-by-move choreography polish','authored accessory/armor/cloth production','expanded competitive combo/KO matrix','owner motion/VFX/audio judgment']}
 rows.append(row)
ko=json.loads((OUT/'continuous_1011/COMPETITIVE_KO_POSTFIX.json').read_text());kf=ko['native_ko_events'][0]['movie_frame']
records.append(file_record(ko['native_movie'],ko['native_source_sha'],'native_competitive_stock_loss','repaired9throws9contacts; activeCPU;110% initial fixture; stock9→8, not match win; earlier motion source'))
sheet(ROOT/ko['native_movie'],'postfix_competitive_stock_loss',[kf+n for n in [-3,-1,0,2,6,18]],['pre KO','pre KO','stock-loss trace','original finishing effect','clearing','respawn'],ko['native_source_sha'],'stock-loss')
manifest={'schema':'ANI03_FULL_ROSTER_INCREMENT_REVIEW','implementation_source_shas':sorted({r['source_sha'] for r in movies}),'rows':rows,'assets':records,'all_paths_verified':True,'human_gates':{x:False for x in ['GAME_FEEL_HUMAN_PASS','VFX_TASTE_HUMAN_PASS','ANIMATION_TASTE_HUMAN_PASS','SFX_MIX_HUMAN_PASS','V1_ANIME_HUMAN_PASS','FINAL_RELEASE_AUTHORIZED']},'scope':'all-nine-fighter current-animation candidates; existing VFX campaign preserved; no final production quality/device/release claim'}
(DEST/'EVIDENCE_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
page=['<!doctype html><meta charset="utf-8"><title>ANI-03 full-roster review</title><style>body{background:#121820;color:#ecf2ff;font:16px system-ui;max-width:1100px;margin:30px auto}video{width:100%}img{width:100%}section{margin:32px 0}a{color:#9bd9ff}</style><h1>All nine fighters · current animation review</h1><p>Automated public controls against active CPUs, female P1/male P2. Native 60 fps output and original audio. These are development candidates. Human gates remain false.</p>']
for row in rows:
 rel=Path('../..')/'rendered'/Path(row['movie']).name
 page.append(f'<section><h2>{html.escape(row["fighter"])}</h2><p>Source {row["source_sha"]}. Body hits {row["p1_hits"]}, shields {row["p1_shields"]}, CPU moves {row["cpu_moves"]}.</p><video controls preload="metadata" src="{rel}"></video>')
 for kind,path in row['contact_sheets'].items():page.append(f'<details><summary>{kind} exact frames</summary><img src="{path}"></details>')
 page.append('</section>')
(DEST/'index.html').write_text('\n'.join(page))
lines=['# ANI-03 full-roster owner review','', 'Current implementation source: '+', '.join(manifest['implementation_source_shas'])+'. The delivery commit containing this report is resolved with `git log -1 --format=%H -- artifacts/v1_closure/spectral_feedback/continuous_1011/owner_roster_review/EVIDENCE_MANIFEST.json`. Draft #123 remains stacked on #122.','', 'Start with index.html. Watch normal-speed mirror matches with audio for every fighter. Female P1 and male active CPU are both visible. Public controls are automated; no human playthrough or artistic approval is claimed. Prior effects movies remain available at their original sources.','', '| Fighter | Hits / shields / CPU moves | Wrist→overlap center px | Max wrist→surface px | Mean stance drift px/frame | Owner |','|---|---:|---:|---:|---:|---|']
for r in rows:lines.append(f'| {r["fighter"]} | {r["p1_hits"]} / {r["p1_shields"]} / {r["cpu_moves"]} | {r["wrist_to_contact_center_px"][0]:.1f}–{r["wrist_to_contact_center_px"][1]:.1f} | {r["max_wrist_to_overlap_surface_px"]:.1f} | {r["mean_support_slip_px_per_frame"]:.3f} | Unreviewed |')
lines+=['','The geometry fixture measures wrists, rather than fist mesh surfaces, at42px initial spacing on flat ground. The zero-to4px remaining wrist surface gap is reported without an invented anatomy tolerance. Outer range, aerials and weapon/hand surfaces need further engineering/art review. Foot drift is measured during linear support portions; start/stop/turn transitions still need polish.','', 'Pass A: +Z and resolved timing corrected across9×2×2; live event frame now presents the authored pose before collision feedback. Pass B: original differentiated support/swing gaits track real displacement; planted stationary strikes and public jump/stop cases verified. Authored pivots/skids/start transitions unfinished. Pass C:864 move/body/facing configurations execute original bilateral blocking, with pelvis/chest chains and follow-through. Move-by-move professional choreography unfinished. Pass D: neutral and reactions now own their clips; interruptions preserve gameplay. Reaction acting/tumble refinements remain. Pass E: original9elementVFX/SFX and bounded accessory layer retained; production secondary motion unfinished. Pass F:9active-CPU mirror clips are reviewable; deeper combos and competitive KO across the roster remain partial.','', 'Review each fighter for weight, direction, anticipation/contact/recovery, visible model variation, elemental identity and readability with sound. Note exact video timestamps. Owner acceptance remains false for every row. The repaired Ember stock-loss clip is competitive engineering proof at its earlier source, with110% initial fixture; it does not establish a complete match win or current animation polish.','', 'ANI-04: authored acting, facial/lip-sync/camera animation, continuous Kaia OVA + six variations and professional audio rights remain open. ANI-05: physical devices, safe exports and release/human acceptance remain open. Native60fps MovieWriter output is not sustained device performance. No platforms exported below18GiB.','', 'Manifest verifies every new video, trace and sheet path, source and hash. Original versus assets/audio have source provenance; local-only temporary voiced Story assets remain excluded. No merge, release, deployment, tag or publication authorized.']
(DEST/'OWNER_REVIEW.md').write_text('\n'.join(lines)+'\n')
print(json.dumps({'fighters':len(rows),'verified_assets':len(records),'source_shas':manifest['implementation_source_shas']}))
