extends SceneTree
var output:=""
func _init():call_deferred("run")
func run():
 create_timer(10).timeout.connect(func():quit(2))
 await process_frame
 for a in OS.get_cmdline_user_args():
  if a.begins_with("--ordinary-output="):output=a.get_slice("=",1)
 var training=load("res://scripts/training/training_battle_scene.gd").new()
 var failures:Array=[];var rows:Array=[]
 var packets=[
  {"combat_event_id":"first","confirmed_contact":true,"contact_result":"hit","attack_activation_id":1,"defender_in_hitstun_before":false,"move_id":"jab_1","expected":1},
  {"combat_event_id":"isolated","confirmed_contact":true,"contact_result":"hit","attack_activation_id":2,"defender_in_hitstun_before":false,"move_id":"jab_2","expected":1},
  {"combat_event_id":"linked","confirmed_contact":true,"contact_result":"hit","attack_activation_id":3,"defender_in_hitstun_before":true,"move_id":"jab_finisher","expected":2},
  {"combat_event_id":"linked","confirmed_contact":true,"contact_result":"hit","attack_activation_id":3,"defender_in_hitstun_before":true,"move_id":"jab_finisher","expected":2},
  {"combat_event_id":"block","confirmed_contact":true,"contact_result":"shield","blocked":true,"move_id":"jab_1","expected":0},
  {"combat_event_id":"armor","confirmed_contact":true,"contact_result":"armor","armor_block":true,"move_id":"jab_1","expected":0},
  {"combat_event_id":"unconfirmed","confirmed_contact":false,"contact_result":"hit","move_id":"jab_1","expected":0}]
 for packet in packets:
  training._on_dummy_hit(packet)
  if training._combo_p1!=int(packet.expected):failures.append(str(packet.combat_event_id)+":expected"+str(packet.expected)+":actual"+str(training._combo_p1))
  rows.append({"event":packet.combat_event_id,"expected":packet.expected,"actual":training._combo_p1})
 training._on_dummy_hit({"combat_event_id":"recovery","confirmed_contact":true,"contact_result":"hit","attack_activation_id":4,"defender_in_hitstun_before":false,"move_id":"jab_1"})
 training._on_dummy_control_state("land","idle")
 if training._combo_p1!=0:failures.append("actual_control_return_ends_string")
 for fid in preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS:
  var actor=load("res://scenes/fighters/Fighter.tscn").instantiate()
  actor.move_runner=preload("res://scripts/combat/move_runner.gd").new();actor.add_child(actor.move_runner)
  actor.move_manifest=preload("res://scripts/data/data_loader.gd").load_moves(fid)
  actor.move_runner.start_move(preload("res://scripts/data/data_loader.gd").find_move(actor.move_manifest,"jab_1"),actor)
  training.fighter1=actor
  var hint:String=training._authored_link_hint({"contact_owner":"melee","attack_activation_id":actor.move_runner.activation_id})
  if hint!="On-hit link: Attack":failures.append(fid+":existing_jab_link_hint")
  actor.free()
 training.free()
 var f=FileAccess.open(output.path_join("training_combo_truth.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"scope":"training UI packet-policy regression; distinct from ordinary CPU combo proof"},"  "));f.close()
 print("TRAINING_COMBO_TRUTH ","PASS" if failures.is_empty() else "FAIL"," failures=",failures.size());quit(0 if failures.is_empty() else 1)
