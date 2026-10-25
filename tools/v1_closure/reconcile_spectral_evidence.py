"""Verify existing review assets and completed ledgers, without replaying gameplay."""
import json,subprocess,hashlib,re,shutil
from pathlib import Path
from datetime import datetime,timezone
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/spectral_feedback'
HEAD=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
RUNTIME='f858246970a129565473fb00f447bd931bb12350'
def read(name):return json.loads((OUT/name).read_text())
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def ancestor(value):return subprocess.run(['git','merge-base','--is-ancestor',value,HEAD],cwd=ROOT,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode==0
assets=[];errors=[];seen=set()
def asset(path,source,kind,scope,restriction='original visual/audio development review; human/final distribution gates remain false',expected=None,movie=None,frames=None):
    p=Path(path);p=p if p.is_absolute() else ROOT/p
    if p in seen:return
    seen.add(p)
    row={'path':str(p.relative_to(ROOT)),'absolute_path':str(p),'kind':kind,'source_sha':source,'source_is_ancestor':ancestor(source),'scope':scope,'redistribution_restriction':restriction,'local_only':'local_media' in p.parts}
    if not p.is_file():row['verification_status']='MISSING';errors.append(row['path'])
    else:
        row['sha256']=sha(p);row['bytes']=p.stat().st_size
        if expected and row['sha256']!=expected:errors.append(row['path']+':hash mismatch')
        if kind=='video':
            row['streams']=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_entries','stream=codec_type,codec_name,duration,r_frame_rate,nb_frames','-of','json',str(p)],text=True))['streams']
            video=next((s for s in row['streams'] if s['codec_type']=='video'),None);audio=next((s for s in row['streams'] if s['codec_type']=='audio'),None)
            if not video or not audio or video['r_frame_rate']!='60/1':errors.append(row['path']+':missing 60 fps A/V')
            elif abs(float(video['duration'])-float(audio['duration']))>.06:errors.append(row['path']+':A/V duration mismatch')
            row['video_frames']=int(video['nb_frames']) if video else 0
        else:
            with Image.open(p) as image:row['dimensions']=list(image.size);image.verify()
        row['verification_status']='VERIFIED_FILE_AND_METADATA' if not any(e.startswith(row['path']) for e in errors) else 'FAILED'
    if not row['source_is_ancestor']:errors.append(row['path']+':invalid source lineage')
    if movie:row['source_movie']=movie
    if frames:
        row['source_frames']=frames
        source_row=next((r for r in assets if r['path']==movie or r['absolute_path']==movie),None)
        if not source_row or max(frames)>=source_row.get('video_frames',0):errors.append(row['path']+':frame range outside source')
    assets.append(row)
for row in read('capture_index.json')['movies']:
    asset(row['path'],row['source_sha'],'video',row['scope'],expected=row['sha256'])
    if row['mode']=='charge':assets[-1]['acceptance_status']='FAILED_CHARGE_CONTINUITY; preserved and superseded'
    else:assets[-1]['acceptance_status']='TECHNICAL_CAPTURE_VERIFIED; owner quality unapproved'
for row in read('combo_probe_index.json')['attempts']:
    if row['native_movie']:asset(row['path'],row['source_sha'],'video',row['scope'],expected=row['sha256'])
derived=read('LIFECYCLE_AND_SLOW_REVIEW.json')
for row in derived['slowed_clips']:asset(row['path'],row['source_sha'],'video',row['scope'],expected=row['sha256'],movie=row['source_movie'])
for row in derived.get('superseded_slower_clips',[]):
    before=len(errors)
    asset(row['path'],row['source_sha'],'video',row['scope'],expected=row['sha256'],movie=row['source_movie'])
    assets[-1]['acceptance_status']='FAILED_DERIVED_AV_DURATION; preserved and superseded'
    # A known failed derivative remains indexed, but does not invalidate its replacement.
    assets[-1]['known_failures']=errors[before:];errors[before:]=[]
stock=read('NATIVE_STOCK_LOSS.json')
asset(stock['path'],stock['source_sha'],'video',stock['scope'],'LOCAL OWNER REVIEW ONLY: possible temporary formant Story speech; audio redistribution not approved',expected=stock['sha256'])
for row in read('CONTACT_SHEETS.json'):
    frames=row['frames_left_to_right_then_down']
    asset(row['path'],row['source_sha'],'contact_sheet',row['note'],movie=row['source_movie'],frames=frames)
    detail=ROOT/row['path'];detail=detail.with_name(detail.stem+'_detail.png')
    if detail.exists():asset(detail,row['source_sha'],'contact_sheet','original renderer crop; same source frames',movie=row['source_movie'],frames=frames)
for row in derived['sheets']:asset(row['path'],row['source_sha'],'contact_sheet',row['scope'],movie=row['movie'],frames=row['frames'])
gallery=read('shape_gallery/launch_manifest.json')
for p in (OUT/'shape_gallery').glob('*.png'):asset(p,gallery['runtime_source_sha'],'shape_gallery','original native Compatibility raster; fixture, not ordinary combat')
# Every linked local media artifact and every package image/movie must be accounted for.
for path in list((OUT/'rendered').glob('*.mp4'))+list((OUT/'contact_sheets').glob('*.png')):
    if path not in seen:errors.append(str(path.relative_to(ROOT))+':unindexed asset')
review=(OUT/'OWNER_REVIEW.md').read_text()
for path in re.findall(r'\]\((/[^)]+)\)',review):
    if not Path(path).exists():errors.append(path+':broken owner link')
tests=read('regressions/results.json')['rows'];expected={'ChargeContinuity','SpectralFeedback','InterruptedMove','CombatActivation','ElementalPerformance','OwnerOverrideFaces','DialogueProduction','FullCampaign','ShippingRosterPath','CampaignRestart','CollectibleRuntime','SelectCriticalLaunchHarness'}
assert {r['test'] for r in tests}==expected
for r in tests:
    folder=OUT/'regressions'/r['test'];log=(folder/'stdout.log').read_text();launch=json.loads((folder/'launch_manifest.json').read_text())
    r['reconciled_log_sha256']=sha(folder/'stdout.log');r['reconciled_launch_sha256']=sha(folder/'launch_manifest.json')
    executed=launch['runtime_source_sha'];r['execution_source_sha']=executed
    r['godot_source_tree_sha']=subprocess.check_output(['git','rev-parse',executed+':game-godot'],cwd=ROOT,text=True).strip()
    tested_tree=subprocess.check_output(['git','rev-parse',RUNTIME+':game-godot'],cwd=ROOT,text=True).strip()
    r['source_equivalent_to_runtime_checkpoint']=r['godot_source_tree_sha']==tested_tree
    r['metadata_note']='Runner records the batch-start SHA; launcher records the per-suite execution SHA. Godot source tree identity is checked explicitly.'
    r['verification_status']='VERIFIED_PASS' if r['passed'] and r['exit_code']==0 and not r['script_errors'] and 'SCRIPT ERROR' not in log and ancestor(executed) and r['source_equivalent_to_runtime_checkpoint'] and r['source_sha']==RUNTIME else 'UNVERIFIED'
    if r['verification_status']!='VERIFIED_PASS':errors.append(r['test']+':ledger/log mismatch')
    r['not_rerun_during_reconciliation']=True
runtime_diff=subprocess.check_output(['git','diff','--name-only',RUNTIME,HEAD,'--','game-godot/scripts','game-godot/shaders','game-godot/data','game-godot/assets'],cwd=ROOT,text=True).splitlines()
assert not runtime_diff,'Runtime differs from final tested source'
gates=read('ACCEPTANCE_GATES.json');assert all(v is False for v in gates.values() if isinstance(v,bool))
result={'schema':'ani03_evidence_reconciliation/v1','verified_at_utc':datetime.now(timezone.utc).isoformat(),'verified_head':HEAD,'tested_runtime_sha':RUNTIME,'runtime_changes_since_test':runtime_diff,'assets':assets,'regressions':tests,'errors':errors,'all_required_assets_verified':not errors,'human_acceptance_earned':False,'new_capture_campaign_run':False}
(OUT/'EVIDENCE_MANIFEST.json').write_text(json.dumps(result,indent=2)+'\n')
(OUT/'regressions/results.json').write_text(json.dumps({'rows':tests,'exports_run':False,'reconciliation_head':HEAD,'all_twelve_verified':not errors and all(r['verification_status']=='VERIFIED_PASS' for r in tests)},indent=2)+'\n')
print(json.dumps({'assets':len(assets),'videos':sum(a['kind']=='video' for a in assets),'contact_sheets':sum(a['kind']=='contact_sheet' for a in assets),'regressions':len(tests),'errors':errors}))
if errors:raise SystemExit(1)
