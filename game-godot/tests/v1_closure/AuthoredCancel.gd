extends SceneTree
const Data=preload("res://scripts/data/data_loader.gd")
const Runner=preload("res://scripts/combat/move_runner.gd")
var failures:Array=[]
var rows:Array=[]
var output:=""
func _init():call_deferred("run")
func check(value:bool,label:String):
 if not value:failures.append(label)
func run():
 await process_frame
 for a in OS.get_cmdline_user_args():
  if a.begins_with("--ordinary-output="):output=a.get_slice("=",1)
 for fid in preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS:
  var moves:Dictionary=Data.load_moves(fid)
  var runner=Runner.new();root.add_child(runner)
  var move:Dictionary=Data.find_move(moves,"jab_1")
  var body:=Node2D.new();root.add_child(body)
  runner.start_move(move,body)
  var window:Dictionary={}
  for w in move.get("cancel_windows",[]):
   if w.get("to","")=="jab_2":window=w;break
  if window.is_empty():rows.append({"fighter":fid,"status":"NO_EXPLICIT_JAB2_WINDOW"});runner.queue_free();continue
  while runner.total_frame<int(window.start):runner.tick_sim_frame()
  var supported:bool=runner.has_method("can_cancel_to") and runner.has_method("record_confirmed_contact")
  check(supported,fid+":authored_cancel_runtime_connection_missing")
  if supported:
   check(not runner.can_cancel_to("jab_2"),fid+":whiff_rejected")
   runner.record_confirmed_contact({"confirmed_contact":true,"contact_result":"shield","attack_activation_id":runner.activation_id,"contact_owner":"melee"})
   check(not runner.can_cancel_to("jab_2"),fid+":shield_rejected")
   runner.record_confirmed_contact({"confirmed_contact":true,"contact_result":"hit","attack_activation_id":runner.activation_id-1,"contact_owner":"melee"})
   check(not runner.can_cancel_to("jab_2"),fid+":stale_activation_rejected")
   runner.record_confirmed_contact({"confirmed_contact":true,"contact_result":"hit","attack_activation_id":runner.activation_id,"contact_owner":"melee"})
   check(runner.can_cancel_to("jab_2"),fid+":explicit_window_connected")
   check(not runner.can_cancel_to("heavy_attack"),fid+":unauthored_target_rejected")
   while runner.active and runner.total_frame<=int(window.end):runner.tick_sim_frame()
   check(not runner.can_cancel_to("jab_2"),fid+":expired_rejected")
   runner.cancel();check(not runner.can_cancel_to("jab_2"),fid+":cancel_cleanup")
  rows.append({"fighter":fid,"window":window,"runtime_connected":supported,"scope":"declared runner policy unit fixture, not ordinary combo acceptance"})
  runner.queue_free();body.queue_free()
 var f=FileAccess.open(output.path_join("authored_cancel.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows},"  "));f.close()
 print("AUTHORED_CANCEL ","PASS" if failures.is_empty() else "FAIL"," failures=",failures.size());quit(0 if failures.is_empty() else 1)
