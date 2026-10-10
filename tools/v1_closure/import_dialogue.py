#!/usr/bin/env python3
"""Compile the owner-supplied screenplay into stable, event-bound runtime cues."""
import argparse, collections, csv, hashlib, json, shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'game-godot/data/story/dialogue/v1'
REPORT = ROOT / 'artifacts/v1_closure/dialogue_performance'
SPEAKERS = dict(zip(['Ember','Rook','Juno','Kaia','Nix','Orion','Vesper','Yin','Yang'],
 ['ember-vale','rook-ironside','juno-spark','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang']))
MID = {'STOCK_WIN':['combat_contact'], 'COSMIC_SURVIVAL':['cosmic_engaged'],
 'FIRST_LOSS':['decision_made','first_loss_signal'], 'PUPPET_IMBALANCE':['puppet_contact'],
 'FIRST_RELEASE':['release_ready','puppet_released'], 'PUPPET_EQUILIBRIUM':['center_guard'],
 'PAIRED_RELEASE':['release_ready','puppet_released'],
 'PRISMATIC_TRANSFORMATION':['gray_signals_collected','transformation_started'],
 'GRAY_DEMONSTRATION':['gray_combat_action'], 'SEVENFOLD_REUNION':['reunion_signal'],
 'SEVENFOLD_EQUILIBRIUM':['equilibrium_signal'], 'UI_ACKNOWLEDGMENT':['scene_turn']}

def write(path, data):
 path.parent.mkdir(parents=True, exist_ok=True)
 path.write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n')

def main():
 ap=argparse.ArgumentParser(); ap.add_argument('--pack', type=Path, default=Path('/Users/gunnchos/Downloads/ANIME_AGGRESSORS_V1_STORY_DIALOGUE_TTS_PRODUCTION_PACK')); args=ap.parse_args()
 pack=args.pack; script=json.loads((pack/'ANIME_V1_DIALOGUE_PRODUCTION_DRAFT.json').read_text())
 graph=json.loads((ROOT/'game-godot/data/story/v1_campaign.json').read_text())
 nodes={n['id']:(r,n) for r in graph['routes'] for n in r['nodes']}
 assert len(nodes)==145 and {n['node_id'] for n in script['nodes']}==set(nodes)
 assert script['first_loss_selected']==graph['first_loss_selected'] and len(set(script['first_loss_selected'].values()))==7
 csv_rows={r['cue_id']:r for r in csv.DictReader((pack/'ANIME_V1_TTS_CUE_MANIFEST.csv').open())}
 assert len(csv_rows)==1025
 source=ROOT/'docs/anime-aggressors/v1_closure/dialogue_production/source'; source.mkdir(parents=True,exist_ok=True)
 hashes={}
 for file in sorted(pack.iterdir()):
  if file.is_file():
   data=file.read_bytes(); hashes[file.name]=hashlib.sha256(data).hexdigest(); shutil.copyfile(file,source/file.name)
 cues={}; runtime_nodes={}; coverage=[]
 for node in script['nodes']:
  route,game=nodes[node['node_id']]; contract=game.get('objective_contract','STOCK_WIN' if game['kind']=='STORY_BATTLE' else 'UI_ACKNOWLEDGMENT')
  events=collections.defaultdict(list); mids=[l for l in node['lines'] if l['phase']=='mid']; mid_index=0
  for line in node['lines']:
   cue_id=line['id']; assert cue_id not in cues
   manifest=csv_rows[cue_id]; assert manifest['node_id']==node['node_id'] and manifest['speaker']==line['speaker'] and manifest['line']==line['text'] and manifest['phase']==line['phase']
   assert line['speaker'] in SPEAKERS and line['subtitle'] and line['phase'] in ['pre','mid','post']
   if line['phase']=='pre': event='scene_start' if game['kind']=='INTERACTIVE_DIALOGUE' else 'encounter_intro'
   elif line['phase']=='post':
    event='scene_resolution' if game['kind']=='INTERACTIVE_DIALOGUE' else 'first_loss_resolved' if contract=='FIRST_LOSS' else 'essence_earned' if contract in ['FIRST_RELEASE','PAIRED_RELEASE'] else 'gray_manifested' if contract=='PRISMATIC_TRANSFORMATION' else 'encounter_success'
   else:
    if contract=='SEVENFOLD_TRIAL': event='trial_identity:'+SPEAKERS[line['speaker']]
    else:
     choices=MID[contract]; event=choices[min(len(choices)-1,mid_index*len(choices)//max(1,len(mids)))]
    mid_index+=1
   lost=route.get('first_loss',{}).get('fighter',''); route_nodes=[n['id'] for n in route['nodes']]
   is_memory=bool(lost and SPEAKERS[line['speaker']]==lost and route_nodes.index(game['id'])>10)
   cue={**line,'cue_id':cue_id,'node_id':node['node_id'],'speaker_id':SPEAKERS[line['speaker']], 'event':event,
    'representation':'memory_echo' if is_memory else 'scene_speaker', 'language_key':'story.v1.'+cue_id,
    'voice_profile':SPEAKERS[line['speaker']], 'voice_asset':'res://assets/audio/story_temp/'+cue_id+'.wav',
    'status':'DRAFT_OWNER_REVIEW_DEVELOPMENT_AUTHORIZED','final_dialogue_approved':False,
    'minimum_read_seconds':round(max(2.0,len(line['subtitle'].split())/3.0+0.6),2),
    'voice_replacement_contract':'Stable cue ID, separate asset/license metadata; no campaign logic changes.'}
   cues[cue_id]=cue; events[event].append(cue_id)
   coverage.append({'cue_id':cue_id,'node_id':game['id'],'speaker':line['speaker'],'phase':line['phase'],'event':event,'subtitle':line['subtitle'],'status':'INTEGRATED_EVENT_BINDING','temporary_voice':'PENDING_GENERATION','final_approved':False})
  runtime_nodes[game['id']]={'title':node['title'],'scene_notes':node['scene_notes'],'contract':contract,'events':dict(events),'ordered_cues':[l['id'] for l in node['lines']], 'watch_role':route.get('watch_role','SHARED_FINALE')}
 assert len(cues)==1025 and set(cues)==set(csv_rows)
 write(OUT/'cues.json',{'schema':'story_dialogue_cues.v1','status':'DEVELOPMENT_AUTHORIZED_NOT_FINAL','cues':cues})
 write(OUT/'nodes.json',{'schema':'story_dialogue_events.v1','nodes':runtime_nodes})
 write(REPORT/'dialogue_coverage.json',{'nodes':145,'cue_count':1025,'node_coverage':[{ 'node_id':k,'cue_count':len(v['ordered_cues']),'events':list(v['events']),'status':'INTEGRATED_EVENT_BINDING'} for k,v in runtime_nodes.items()], 'cues':coverage,'source_hashes':hashes,'first_loss_selected':script['first_loss_selected'],'development_authorized':True,'final_dialogue_approved':False,'all_human_gates':False,'V1_AUTOMATED_READY':False})
 print(json.dumps({'nodes':len(runtime_nodes),'cues':len(cues),'contracts':dict(collections.Counter(n['contract'] for n in runtime_nodes.values()))}))

if __name__=='__main__': main()
