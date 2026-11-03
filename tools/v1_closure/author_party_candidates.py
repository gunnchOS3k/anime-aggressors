"""Original owner-directed Party candidates, separate from216 BASE records."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
IDS=['ember-vale','rook-ironside','juno-spark','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang']
NAMES=['Sevenfold Furnace','Worldbreaker Bastion','Spectrum Overdrive','Eye of the Seven Winds','Chromatic Citadel','Orbit of Seven','Sevenfold Mirage','The Infinite Quiet','The Absolute Radiance']
# Authored pulse schedules define different launch geometry, rhythm and field roles.
PULSES=[[(1,46,-8,0,360,4,24,35),(8,60,-8,0,400,4,22,40),(16,72,-12,0,430,7,28,45)],[],[(1,46,-8,0,720,3,16,25),(5,46,-20,-18,720,3,16,45),(14,46,-8,12,480,8,24,50)],[(1,40,-26,-32,300,4,24,80),(10,48,-42,0,300,4,26,90),(20,48,-18,32,300,6,30,75)],[(1,40,-10,0,0,4,24,75),(11,80,-10,0,0,4,24,80),(21,120,-10,0,0,4,24,85)],[(1,50,-28,-35,220,3,24,140),(11,50,-8,35,220,3,24,140),(22,64,-16,0,0,9,32,135)],[(1,-30,-14,180,330,4,22,35),(12,70,-14,0,330,4,22,35),(24,46,-30,0,450,7,26,65)],[(1,100,-12,0,0,3,34,165),(12,65,-12,0,0,4,26,165),(24,30,-12,0,0,9,18,90)],[(1,45,-12,0,220,4,20,30),(9,90,-24,-15,160,4,26,45),(17,135,-12,15,100,8,32,70)]]
def projectile(kind,speed,damage,size,life,x=46,y=-8,angle=0,limit=3):
 return dict(type=kind,offset_x=x,offset_y=y,angle_deg=angle,spawn_frame=1,speed_by_aura=[speed]*5,damage_by_aura=[damage]*5,size_by_aura=[size]*5,lifetime_frames_by_aura=[life]*5,behavior_by_aura=['straight']*5,pierce=False,max_active_per_move=limit)
def build():
 fighters={}
 for i,fid in enumerate(IDS):
  base=json.loads((ROOT/'game-godot/data/moves'/f'{fid}.json').read_text());side=next(x for x in base['moves'] if x['move_id']=='side_special')
  prism={'side_special':dict(damage=[9,11,8,7,6,8,7,9,10][i],angle_deg=[35,40,30,80,75,150,35,160,25][i],recovery_frames=int(side['recovery_frames'])+4,training_display_name=NAMES[i]+' — Echo Special')}
  if i in [0,2,3,6]:prism['side_special']['self_movement']={'x':[80,0,110,55,0,0,-90,0,0][i],'y':-100 if i==3 else 0}
  if i==1:prism['side_special']['armor_frames']=3
  if i==4:prism['side_special'].update(move_type='projectile',projectile=projectile('echo_cryolattice',0,6,22,42,limit=1))
  variants={}
  for white in [False,True]:
   variant='WHITE' if white else 'BLACK'
   if i<7:
    overlay={'side_special':{'damage':round(float(side['damage'])*(1.08 if white else 1.05),3),'angle_deg':40 if white else 135,'recovery_frames':int(side['recovery_frames'])+(4 if white else 6),'training_display_name':variant.title()+' Puppet Echo — '+str(side.get('training_display_name','Special'))}}
    variants[variant]={'state_id':('WHITE_PUPPET_ECHO' if white else 'BLACK_PUPPET_ECHO'),'asset_form':'WHITE_PUPPET' if white else 'BLACK_PUPPET','overrides':overlay}
   else:
    variants[variant]={'state_id':'NULL_CONDUCTOR' if i==7 else 'RADIANT_CONDUCTOR','asset_form':'BASE','overrides':{'side_special':{'move_type':'projectile','damage':3 if i==7 else 6,'recovery_frames':28,'projectile':projectile('null_conductor' if i==7 else 'radiant_conductor',0 if i==7 else 420,3 if i==7 else 6,20,48 if i==7 else 40,limit=1),'training_display_name':'Null Anchor' if i==7 else 'Conductor Ray'}}}
  ultimate={'move_id':'party_ultimate:'+fid,'display_name':NAMES[i],'mechanic':['combustion_chase','guarded_retaliation','rhythmic_rails','rising_spiral','finite_lattice','vector_compression','offset_echoes','collapsing_apertures','radiant_construction'][i],'startup_frames':[28,32,24,26,30,30,34,36,34][i],'active_frames':[24,20,22,26,28,28,30,28,24][i],'recovery_frames':[36,42,32,34,42,40,44,48,44][i],'visual_move_id':'aura_burst','guardable':True,'pulses':[],'source_acting_status':'EXISTING_SIGNATURE_CANDIDATE_REUSED; dedicated ultimate acting missing'}
  for frame,x,y,angle,speed,damage,size,launch in PULSES[i]:
   life=55 if i==4 else 10 if i==7 else 8 if i==5 and speed==0 else 48
   ultimate['pulses'].append({'frame':frame,'damage':damage,'launch_angle':launch,'base_knockback':4 if i==4 else 12,'projectile':projectile('party_'+ultimate['mechanic'],speed,damage,size,life,x,y,angle)})
  if i==0:ultimate['impulse']={'frame':1,'x':130,'y':0}
  if i==3:ultimate['impulse']={'frame':1,'x':45,'y':-130}
  if i==1:ultimate.update(counter_window_frames=8,retaliation_frame=13,damage=13,base_knockback=18,angle_deg=45,hitboxes=[dict(offset_x=42,offset_y=-12,width=120,height=64)])
  fighters[fid]={'bible':'docs/bibles/fighters/'+fid+'.md','prism_heart':{'state_id':'PRISMATIC_ECHO' if i<7 else 'INFINITE_QUIET_TRUE_ASPECT' if i==7 else 'ABSOLUTE_RADIANCE_TRUE_ASPECT','asset_form':'PRISMATIC_GRAY' if i<7 else 'BASE','overrides':prism},'puppet_seal':variants,'ultimate':ultimate}
 return {'schema':'party_overdrive_candidates.v1','status':'TUNING_CANDIDATE','human_approved':False,'duration_frames':600,'transform_startup_frames':36,'activation_action':'taunt','ultimate_action':'taunt','mode_policy':'Explicit items enabled in existing versus, hazards or training; never Story/OVA/online/ranked. No progression or save writes.','scaling_policy':'Temporary overlay supersedes legacy gameplay; aura/identity enhancements do not stack; BASE data unchanged.','fighters':fighters}
if __name__=='__main__':
 p=ROOT/'game-godot/data/combat/party_overdrive.json';p.write_text(json.dumps(build(),indent=2)+'\n')
