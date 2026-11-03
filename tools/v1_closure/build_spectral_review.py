"""Derive labeled original movie frames and short slowed review clips; no effect recreation."""
import json,subprocess,hashlib
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/spectral_feedback'
SHEETS=OUT/'contact_sheets';SHEETS.mkdir(exist_ok=True)
def sheet(movie,label,frames,captions):
    target=SHEETS/(label+'.png')
    select='+'.join(f'eq(n\\,{f})' for f in frames)
    subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',str(movie),'-vf',f'select={select},scale=640:360,pad=640:400:0:0:color=0x121820,tile=3x2','-frames:v','1',str(target)],check=True)
    im=Image.open(target).convert('RGB');draw=ImageDraw.Draw(im)
    for i,(frame,caption) in enumerate(zip(frames,captions)):
        draw.text(((i%3)*640+10,(i//3)*400+364),f'Frame {frame} | {frame/60:.4f} s | {caption}',fill='white')
    im.save(target)
    return {'path':str(target.relative_to(ROOT)),'movie':str(movie.relative_to(ROOT)),'frames':frames,'captions':captions,'scope':'actual 60 fps renderer frames; labels refer to observed traces, no recreated effects'}
records=[]
index=json.loads((OUT/'capture_index.json').read_text())
probes=json.loads((OUT/'combo_probe_index.json').read_text())['attempts']
whiff_sources=[{**r,'folder':'captures'} for r in index['movies']]+[{**r,'mode':'active','folder':'combo_probes'} for r in probes if r['native_movie']]
for r in whiff_sources:
    if r['mode']!='charge_continuous':continue
    d=json.loads((OUT/'captures'/r['label']/'combat_capture.json').read_text())
    start=next(e['movie_frame'] for e in d['public_inputs'] if 'special' in e['actions'] and 'shield' in e['actions'])
    burst=next(e['movie_frame'] for e in d['move_phases'] if e['move']=='aura_burst' and e['phase']=='active')
    launch=next(e['movie_frame'] for e in d['move_phases'] if e['move']=='neutral_special_projectile' and e['phase']=='active')
    contact=next((e['movie_frame'] for e in d['contacts'] if e['attacker']==r['fighter'] and e['move']=='neutral_special_projectile' and e['result']=='hit'),launch+45)
    end=next((e['process_frame']+1 for e in d['presentation_events'] if e['fid']==r['fighter'] and e['kind']==5 and e['process_frame']>contact),contact+20)
    frames=[start+30,start+240,burst+2,launch+14,contact+2,max(end+8,contact+10)]
    records.append({**sheet(ROOT/r['path'],r['label']+'_lifecycle',frames,['growing held charge','full held charge','actual signature release','projectile flight','actual projectile contact' if contact!=launch+45 else 'flight / no contact selected','observed dissipation']), 'source_sha':r['source_sha'],'P2_idle_not_combo_evidence':True})
for r in whiff_sources:
    if r['mode']!='active' or r['fighter'] not in ['ember-vale','juno-spark']:continue
    d=json.loads((OUT/r['folder']/r['label']/'combat_capture.json').read_text())
    for e in d.get('move_phases',[]):
        if e['fighter']!=r['fighter'] or e['phase']!='active' or e['move']=='neutral_special_projectile':continue
        f=e['movie_frame']
        recovery=next((x['movie_frame'] for x in d['move_phases'] if x['fighter']==r['fighter'] and x['move']==e['move'] and x['phase']=='recovery' and x['movie_frame']>f),f+12)
        if any(f-20<=c['movie_frame']<=recovery+3 for c in d['contacts']):continue
        records.append({**sheet(ROOT/r['path'],r['label']+'_whiff',[f+x for x in [-3,-1,0,2,6,18]],['preparation','preparation','active swing / no contact','whiff / no contact','whiff / no contact','recovery']), 'source_sha':r['source_sha'],'move':e['move'],'no_resolution_events_through_recovery':True})
        break
stock=json.loads((OUT/'NATIVE_STOCK_LOSS.json').read_text())
ko=stock['ko_events'][0];f=ko['movie_frame']
records.append({**sheet(Path(stock['path']),'story_authentic_stock_loss',[f+x for x in [-3,-1,0,2,6,18]],['before stock loss','before stock loss','stock-loss trace','finishing effect','finishing effect','clearing effect']), 'source_sha':stock['source_sha'],'scope':stock['scope'],'audio_movie_local_only':True})
slow=[]
for r in probes:
    if not r['native_movie']:continue
    d=json.loads((OUT/'combo_probes'/r['label']/'combat_capture.json').read_text())
    second=next(c for c in d['contacts'] if c['attacker']==r['fighter'] and c['result']=='hit' and c['follow_up_before_control'])
    first=max((c for c in d['contacts'] if c['attacker']==r['fighter'] and c['result']=='hit' and c['movie_frame']<second['movie_frame']),key=lambda c:c['movie_frame'])
    start=max(0,first['movie_frame']/60-.25);end=second['movie_frame']/60+.65
    target=OUT/'rendered'/(r['label']+'_true_combo_slow3x_av_verified.mp4')
    if target.exists():raise SystemExit('Existing derived evidence preserved: '+str(target))
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-ss',str(start),'-t',str(end-start),'-i',str(ROOT/r['path']),'-vf','setpts=3*PTS','-af','atempo=0.5,atempo=0.666666667,apad','-t',str(round((end-start)*3,6)),'-r','60','-c:v','libx264','-crf','21','-pix_fmt','yuv420p','-c:a','aac','-movflags','+faststart',str(target)],check=True)
    slow.append({'path':str(target.relative_to(ROOT)),'source_movie':r['path'],'source_sha':r['source_sha'],'original_start_s':start,'original_end_s':end,'first_contact':first['movie_frame'],'second_contact':second['movie_frame'],'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'scope':'3x slowed actual footage; original mixed audio time-stretched for review; normal movie alone establishes original timing/audio'})
(OUT/'LIFECYCLE_AND_SLOW_REVIEW.json').write_text(json.dumps({'sheets':records,'slowed_clips':slow},indent=2)+'\n')
print(json.dumps({'lifecycle_sheets':len(records),'slowed_clips':len(slow)}))
