extends SceneTree
var output:=""
var contacts:Array=[]
var failures:Array=[]
var cooldown:=0
func _init():call_deferred("run")
func inputs(actions:Array):
 for key in ["left","right","attack","jump"]:
  if key in actions:Input.action_press("p1_"+key,.55 if key in ["left","right"] else 1.)
  else:Input.action_release("p1_"+key)
func run():
 create_timer(30).timeout.connect(func():quit(2))
 await process_frame
 for a in OS.get_cmdline_user_args():
  if a.begins_with("--ordinary-output="):output=a.get_slice("=",1)
 var gs=root.get_node("GameState");gs.mode="training";gs.stage_id="training-grid";gs.p1_fighter_id="juno-spark";gs.p2_fighter_id="kaia-windrow";gs.training_dummy_mode="stand"
 root.get_node("SceneRouter").go("training_battle")
 for i in range(180):await physics_frame
 var training=current_scene;var p=training.fighter1;var d=training.fighter2
 d.hit_landed.connect(func(info):
  if str(info.get("contact_result",""))=="hit":
   contacts.append({"frame":Engine.get_physics_frames(),"move":info.get("move_id",""),"recovered_before":not bool(info.get("defender_in_hitstun_before",false)),"ui_combo":training._combo_p1,"text":training._hit_log.text if training._hit_log!=null else ""});cooldown=100)
 for frame in range(800):
  var actions:Array=[];var dx:float=d.position.x-p.position.x
  if cooldown>0:cooldown-=1
  elif contacts.size()<2:
   if absf(dx)>35:actions.append("right" if dx>0 else "left")
   elif p.state_machine.can_attack() and frame%4==0:actions.append("attack")
  inputs(actions);await physics_frame
  if contacts.size()>=2 and cooldown==0:break
 inputs([])
 if contacts.size()!=2:failures.append("bounded_public_training_driver_requires_two_contacts")
 for hit in contacts:
  if not hit.recovered_before or hit.ui_combo!=1:failures.append("isolated_contacts_must_not_claim_combo")
 if training._combo_p1!=0:failures.append("defender_return_to_control_clears_current_combo")
 if not contacts.any(func(hit):return str(hit.text).contains("On-hit link: Attack")):failures.append("live_authored_link_hint_not_visible")
 var f=FileAccess.open(output.path_join("training_feedback_live.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"contacts":contacts,"dummy_mode":"ordinary training stand","player_inputs_only":true,"forced_moves_or_damage":false,"strict_CPU_combo_acceptance":false,"scope":"normal training scene, two separated public-input hits and real recovery; verifies player-facing counter/link UI"},"  "));f.close()
 print("TRAINING_FEEDBACK_LIVE ","PASS" if failures.is_empty() else "FAIL"," contacts=",contacts.size()," failures=",failures);quit(0 if failures.is_empty() else 1)
