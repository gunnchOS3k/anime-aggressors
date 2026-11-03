"""Bind preserved original GLBs to the actual game, inside encrypted storage.

No Blender baking, new art, public artifacts, downloads or gameplay overrides.
Requires an already completed 15-minute alternate-reader qualification.
"""
import argparse
import datetime
import hashlib
import json
import os
import plistlib
import re
import shutil
import struct
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PRIVATE = Path('/Volumes/gunnchos-private-art')
ARCHIVE = Path('/Volumes/gunnchOS-Archives')
HANDOFF = PRIVATE/'output/roster_original_strikes_native_v1/CURSOR_ART_ASSET_HANDOFF_v3.json'
HANDOFF_SHA = '115fde2449ce1022abbf7ecb6aba98e75105cd2baacbaa5d869d5fe0af16a6de'
DELTA = 'artifacts/v1_closure/production_8d/metric_stage_8d4/CURSOR_ART_DELTA_20261025.json'
IDS = ('ember-vale','rook-ironside','juno-spark','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang')
sys.path.insert(0,str(ROOT/'tools/v1_closure'))
sys.path.insert(0,str(ROOT/'tools/authored_animation'))
from native_recording_guard import active_media_jobs, run_owned_recording, budget
from private_production_8d4 import live_volume_probe, external_production_report
from audit_blender_402 import verify_audit


def reader():
    data=plistlib.loads(subprocess.check_output(['/usr/sbin/ioreg','-a','-p','IOUSB','-l']))
    found=[]
    def visit(value):
        if isinstance(value,list):
            for item in value: visit(item)
        elif isinstance(value,dict):
            if value.get('idVendor')==0x19ff and value.get('idProduct')==0x0764:
                found.append(value.get('IORegistryEntryID'))
            visit(value.get('IORegistryEntryChildren',[]))
    visit(data)
    if len(found)!=1: raise ValueError('Alternate reader absent or ambiguous')
    return found[0]


class Continuity:
    def __init__(self, receipt):
        record=json.loads(Path(receipt).read_text())
        if record.get('status')!='PASS_15_MINUTE_BOUNDED_OBSERVATION' or record.get('seconds',0)<900 or record.get('failures'):
            raise ValueError('Completed fault-free15minute qualification required before private reads')
        self.registry=record['reader_registry']
        self.since=datetime.datetime.fromisoformat(record['started']).strftime('%Y-%m-%d %H:%M:%S')
        self.devices={p:p.stat().st_dev for p in (PRIVATE,ARCHIVE) if p.is_mount()}
        if len(self.devices)!=2: raise ValueError('Both original mounts must be present')
        for path,uuid in ((PRIVATE,'7264122E-693D-4719-A42D-F1FAA488C119'),(ARCHIVE,'9C4EB36E-2864-42F8-BD0B-A4F67EBC7852')):
            info=plistlib.loads(subprocess.check_output(['/usr/sbin/diskutil','info','-plist',str(path)]))
            if info.get('VolumeUUID')!=uuid or info.get('FilesystemType')!='apfs': raise ValueError('Live volume identity changed')
        self.checked=0.0
        self.failure=None
        self.check()

    def __call__(self):
        try: self.check()
        except (OSError,ValueError,subprocess.SubprocessError) as error: self.failure=str(error)
        return self.failure

    def check(self):
        if self.failure: raise ValueError(self.failure)
        for path,device in self.devices.items():
            if not path.is_mount() or path.stat().st_dev!=device: raise ValueError('Actual mount loss/device change: '+str(path))
        if time.monotonic()-self.checked < 10: return
        if reader()!=self.registry: raise ValueError('Alternate reader re-enumerated')
        predicate='process == "kernel" AND (eventMessage CONTAINS[c] "USB Storage" OR eventMessage CONTAINS[c] "pipe stalled" OR eventMessage CONTAINS[c] "unrecoverable I/O")'
        text=subprocess.check_output(['/usr/bin/log','show','--start',self.since,'--style','compact','--predicate',predicate],text=True,stderr=subprocess.DEVNULL)
        faults=[line for line in text.splitlines() if any(term in line.lower() for term in ('hardware connection lost','pipe stalled','unrecoverable i/o','not found during wake up','device is not responding'))]
        if faults: raise ValueError('Fresh transport fault: '+faults[-1])
        self.checked=time.monotonic()


def confined(path, root=PRIVATE):
    path=Path(path)
    if not path.is_absolute(): path=root/path
    if not path.resolve().is_relative_to(root.resolve()): raise ValueError('Asset escapes protected source root')
    cursor=root
    for part in path.relative_to(root).parts:
        cursor=cursor/part
        if cursor.is_symlink(): raise ValueError('Source symlink rejected')
    return path


def checked(definition, guard, root=PRIVATE):
    guard.check()
    path=confined(definition['path'],root)
    digest=hashlib.sha256()
    with path.open('rb') as source:
        while True:
            guard.check()
            block=source.read(1024**2)
            if not block: break
            digest.update(block)
    if digest.hexdigest()!=definition['sha256']: raise ValueError('Preserved source hash changed: '+str(path))
    return path


def glb_contract(path, definition, bones):
    with Path(path).open('rb') as source:
        magic,version,length=struct.unpack('<4sII',source.read(12))
        count,kind=struct.unpack('<II',source.read(8));data=json.loads(source.read(count))
    if magic!=b'glTF' or version!=2 or kind!=0x4e4f534a or length!=Path(path).stat().st_size: raise ValueError('Invalid existing GLB')
    if len(data.get('skins',[]))!=1 or len(data.get('animations',[]))!=1: raise ValueError('Expected one original skinned actor/action')
    if data['animations'][0].get('name')!=definition['clip']: raise ValueError('Wrong original clip identity')
    names=[data['nodes'][i]['name'] for i in data['skins'][0]['joints']]
    if names!=bones: raise ValueError('Original skeleton names/order changed')
    if not any('WEIGHTS_0' in p.get('attributes',{}) and 'JOINTS_0' in p.get('attributes',{}) for m in data.get('meshes',[]) for p in m['primitives']): raise ValueError('Original skin attributes missing')
    for entry in data.get('buffers',[])+data.get('images',[]):
        if 'uri' in entry and not entry['uri'].startswith('data:'): raise ValueError('Unverified external GLB dependency')


def landmarks(export, move):
    contact=int(export['source_phase_landmarks']['contact'])
    last=int(export['frames'])-1
    # These are the preserved offline catalog phases, NOT replacement gameplay
    # values. The runtime resamples them onto its already resolved phase clock.
    total=sum(move[k] for k in ('startup_frames','active_frames','recovery_frames'))
    # Preserved baker samples each fighter's OWN original action range N.
    # Its contact is round((N-1)*startup/total), including Yin/Yang whose
    # authored action ranges are not identical to the newer catalog totals.
    if export['FPS']!=60 or not 2<=last<=240 or total<=0 or contact!=round(last*move['startup_frames']/total):
        raise ValueError('Authored landmarks/catalog do not match; do not invent a timing map')
    return {'contact':contact,'active_end':last*(move['startup_frames']+move['active_frames'])/total,'last':last}


def make_manifest(guard):
    checked({'path':str(HANDOFF),'sha256':HANDOFF_SHA},guard)
    handoff=json.loads(HANDOFF.read_text())
    delta=json.loads(subprocess.check_output(['git','show','HEAD:'+DELTA],cwd=ROOT))
    if delta['base_manifest_sha256']!=HANDOFF_SHA: raise ValueError('Delta belongs to another art baseline')
    wanted={(fid,body) for fid in IDS for body in ('male','female')}
    rows=[];verified=[]
    for row in handoff['rows']:
        identity=(row['fighter'],row['body'])
        if identity not in wanted: raise ValueError('Duplicate/unknown original fighter/body')
        wanted.remove(identity)
        catalog=json.loads((ROOT/'game-godot/data/moves'/f'{row["fighter"]}.json').read_text())
        moves={item['move_id']:item for item in catalog['moves']}
        if len(moves)!=24 or set(moves)!=set(row['moves']): raise ValueError('Canonical move inventory changed')
        if row['rig']['forward']!='+Z' or row['rig']['rest_policy']!='PRESERVE_ORIGINAL_BIND' or row['root_motion']!='PRESENTATION_ONLY_GAMEPLAY_ROOT_UNCHANGED': raise ValueError('Original rig/root contract differs')
        source=checked(row['source'],guard);verified.append(str(source))
        for key in ('original_source_protected','original_export_protected'):
            original=row[key];original_root=Path(original['archive_root'])
            if not original_root.is_relative_to(ARCHIVE/'10-Anime-Aggressors/art-source-snapshots'): raise ValueError('Unexpected immutable archive')
            verified.append(str(checked(original,guard,original_root)))
        exports={item['clip']:item for item in row['candidate_exports']};bound={}
        for mid in ('jab_1','heavy_attack'):
            export=exports[row['moves'][mid]['exported_clip']]
            phases=landmarks(export,moves[mid]);asset=checked(export,guard);verified.append(str(asset));glb_contract(asset,export,row['rig']['bones'])
            bound[mid]={**export,**phases,'path':str(asset)}
        # Preserve and validate the already-authored Juno finger-closure delta.
        for change in delta['rows']:
            if (change['fighter'],change['body'])!=identity: continue
            mid=change['move_id'];export=change['export'];phases=bound[mid]
            if export['source_frame_range']!=[0,phases['last']] or change['source_landmarks']['contact']!=phases['contact']: raise ValueError('Delta timing is not compatible')
            verified.append(str(checked(change['source'],guard)))
            asset=checked(export,guard);verified.append(str(asset));glb_contract(asset,export,row['rig']['bones'])
            verified.append(str(checked(change['review'],guard)))
            bound[mid]={**phases,**export,'path':str(asset)}
        review=row['native_review'];verified.append(str(checked({'path':review['video'],'sha256':review['sha256']},guard)))
        rows.append({'fighter':row['fighter'],'body':row['body'],'root_policy':'GAMEPLAY_ROOT_UNCHANGED','model':bound['jab_1'],'moves':bound,'source':row['source'],'rig':row['rig']})
    if wanted: raise ValueError('Missing original body identities')
    return {'schema':'private_battle_art.v1','review_only':True,'HUMAN_ART_APPROVED':False,'private_volume_uuid':'7264122E-693D-4719-A42D-F1FAA488C119','source_handoff_sha256':HANDOFF_SHA,'rows':rows},verified


def owner_state():
    directory=Path.home()/'Library/Application Support/Godot/app_userdata/Anime Aggressors'
    return {str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in directory.rglob('*') if p.is_file()} if directory.exists() else {}


def execute(args):
    os.umask(0o077)
    guard=Continuity(args.qualification)
    output=confined(args.output)
    if not output.is_relative_to(PRIVATE/'output') or output.exists(): raise ValueError('Use a NEW encrypted review output; originals preserved')
    identity=live_volume_probe(PRIVATE)
    tmpdir=PRIVATE/'tmp'
    preflight=external_production_report(output,identity=identity,internal_free_bytes=shutil.disk_usage('/System/Volumes/Data').free,external_free_bytes=None,tmpdir=str(tmpdir),probe=live_volume_probe)
    # Keep the stronger forecast measured during native integration, in
    # addition to the existing encrypted producer's external4+8GiB budget.
    storage=({'required_free_bytes':18*2**30+100*2**20,
              'scope':'Native import/playback + bounded PNGs ONLY; no movie, video encoding or raw-frame allocation'}
             if args.no_movie else budget(ROOT,output/'original_battle_60fps.avi',args.frames,60))
    required=storage['required_free_bytes']+1536*2**20
    if not preflight['PASS'] or shutil.disk_usage('/System/Volumes/Data').free<max(19*2**30,required):
        raise ValueError('Private native forecast failed: '+json.dumps({'free_bytes':shutil.disk_usage('/System/Volumes/Data').free,'required_bytes':max(19*2**30,required),'original_guard':preflight}))
    if active_media_jobs(): raise ValueError('Existing heavy process preserved')
    if not 1<=args.frames<=1200: raise ValueError('Small bounded native operation required')
    if args.fighter not in IDS or args.opponent not in IDS: raise ValueError('Unknown review fighter')
    memory=subprocess.check_output(['/usr/bin/memory_pressure','-Q'],text=True)
    free_percent=re.search(r'free percentage:\s*(\d+)%',memory)
    if free_percent is None or int(free_percent[1])<20: raise ValueError('Insufficient measurable RAM headroom for1.5GiB native cap')
    version=subprocess.check_output([str(args.godot),'--version'],text=True).strip()
    if args.godot.resolve()!=Path('/Applications/Godot.app/Contents/MacOS/Godot').resolve() or version!='4.7.1.stable.official.a13da4feb': raise ValueError('Exact verified Godot required')
    blender=verify_audit(ARCHIVE/'gunnchos-active-dev/evidence/BLENDER_402_AUDIT.json',Path('/Applications/Blender 2.app/Contents/MacOS/Blender'))
    preflight.update(godot_version=version,official_blender_binary_sha256=blender['binary_sha256'],memory_pressure=memory,swap=subprocess.check_output(['/usr/sbin/sysctl','vm.swapusage'],text=True).strip())
    manifest,verified=make_manifest(guard)
    if args.verify_only:
        print(json.dumps({'integrity_verified_files':len(set(verified)),'bodies':len(manifest['rows']),'moves_per_body':2,'preflight':preflight},indent=2));return 0
    if subprocess.check_output(['git','diff','HEAD'],cwd=ROOT): raise ValueError('Checkpoint source before native production')
    output.mkdir(mode=0o700)
    (output/'ASSET_BINDING.json').write_text(json.dumps(manifest,indent=2)+'\n')
    (output/'INTEGRITY.json').write_text(json.dumps({'files':verified,'count':len(set(verified)),'source_handoff_sha256':HANDOFF_SHA,'new_art_produced':False},indent=2)+'\n')
    cache=args.cache.resolve();receipt=json.loads((cache.parent/'SOURCE.json').read_text())
    if not cache.is_relative_to(ROOT/'outputs') or receipt.get('private_assets_installed') is not False: raise ValueError('Expected preserved public import cache')
    project=output/'game-godot';guard.check()
    shutil.copytree(cache,project)
    for relative in subprocess.check_output(['git','ls-files','game-godot'],cwd=ROOT,text=True).splitlines():
        guard.check();current=ROOT/relative
        if not current.is_file(): continue
        target=project/current.relative_to(ROOT/'game-godot')
        if not target.exists() or current.read_bytes()!=target.read_bytes(): target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(current,target)
    name='aa-native-'+output.name
    config=(project/'project.godot').read_text()
    config=re.sub(r'^config/(?:name|use_custom_user_dir|custom_user_dir_name)=.*\n','',config,flags=re.M)
    config=config.replace('[application]',f'[application]\nconfig/name="{name}"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="{name}"',1)
    (project/'project.godot').write_text(config)
    head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
    (project/'data/runtime/build_identity.json').write_text(json.dumps({'git_sha':head,'git_sha_short':head[:12],'git_short_sha':head[:12],'watermark':'ORIGINAL ART '+head[:12],'build_flavor':'private-native-review'}))
    before=owner_state();movie=output/'original_battle_60fps.avi'
    source={'source_head':head,'private_assets_requested':True,'private_assets_installed':'PENDING_RUNTIME_REPORT','profile':name,'preflight':preflight,'internal_forecast_bytes':required-18*2**30,'new_blender_or_GLB_files':0,'video_requested':not args.no_movie}
    (output/'SOURCE.json').write_text(json.dumps(source,indent=2)+'\n')
    command=[str(args.godot),'--path',str(project),'--rendering-method','gl_compatibility','--windowed','--resolution','1280x720','--write-movie',str(movie),'--fixed-fps','60','--quit-after',str(args.frames),'--log-file',str(output/'godot.log'),'--script','res://tests/integration/PlayableMatchReview.gd','--','--review-output='+str(output),'--review-automate','--review-fighter='+args.fighter,'--review-opponent='+args.opponent,'--private-art-manifest='+str(output/'ASSET_BINDING.json')]
    if args.no_movie:
        index=command.index('--write-movie');del command[index:index+2]
    if args.female: command.append('--review-female')
    old_tmp=os.environ.get('TMPDIR');os.environ['TMPDIR']=str(tmpdir)
    try:
        result=run_owned_recording(command,ROOT,movie,output,{'PASS':True,'free_bytes':shutil.disk_usage(ROOT).free,'required_free_bytes':max(19*2**30,required),'private_forecast':preflight,'native_movie_budget':storage},error_log=output/'godot.log',max_seconds=240,max_rss_bytes=1536*2**20,environment_check=guard)
    finally:
        if old_tmp is None: os.environ.pop('TMPDIR',None)
        else: os.environ['TMPDIR']=old_tmp
    source['owner_saves_unchanged']=before==owner_state();source['native_exit']=result
    report=output/'PLAYABLE_REVIEW.json'
    if report.exists():
        traces=json.loads(report.read_text()).get('trace',[])
        source['private_assets_installed']=bool(traces) and all(a['model']=='PRIVATE_ORIGINAL_ART_CANDIDATE' and len(a['private_art']['moves'])==4 and not a['private_art']['failures'] for t in traces for a in t['actors'])
    (output/'SOURCE.json').write_text(json.dumps(source,indent=2)+'\n')
    if not source['owner_saves_unchanged']: raise ValueError('Owner save preservation failed')
    return result


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--qualification',required=True,type=Path)
    parser.add_argument('--output',required=True,type=Path)
    parser.add_argument('--cache',type=Path,default=ROOT/'outputs/native_public_counterplay_female_v3/game-godot')
    parser.add_argument('--godot',type=Path,default=Path('/Applications/Godot.app/Contents/MacOS/Godot'))
    parser.add_argument('--verify-only',action='store_true')
    parser.add_argument('--no-movie',action='store_true',help='Native game import/playback/screenshots, with NO video capture or invented footage claim')
    parser.add_argument('--frames',type=int,default=720)
    parser.add_argument('--female',action='store_true')
    parser.add_argument('--fighter',default='ember-vale')
    parser.add_argument('--opponent',default='juno-spark')
    raise SystemExit(execute(parser.parse_args()))
