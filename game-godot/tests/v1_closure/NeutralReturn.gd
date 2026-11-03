extends SceneTree
const Model=preload("res://scripts/fighters/fighter_model_3d.gd")
const Data=preload("res://scripts/data/data_loader.gd")
var output:=""
var failures:Array=[]
var rows:Array=[]
func _init():call_deferred("run")
func check(ok:bool,label:String):
 if not ok:failures.append(label)
func run():
 await process_frame
 for a in OS.get_cmdline_user_args():
  if a.begins_with("--ordinary-output="):output=a.get_slice("=",1)
 for fid in preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS:
  for body in ["male","female"]:
   var model=Model.new();root.add_child(model);model.configure(Data.load_fighter(fid),body);await process_frame
   var c=model.get_animation_controller();var player=c.get_animation_player();var sk=c.get_skeleton()
   for previous in ["hurt_heavy","attack_recovery"]:
    c.play_for_state(previous,Data.find_move(Data.load_moves(fid),"heavy_attack") if previous=="attack_recovery" else {})
    player.advance(.12)
    var index:int=sk.find_bone("Chest");var old:Quaternion=sk.get_bone_pose_rotation(index)
    c.play_for_state("idle")
    check(old.is_equal_approx(sk.get_bone_pose_rotation(index)),fid+body+previous+":no_first_frame_upper_body_snap")
    check(not c._neutral_return_pose.is_empty(),fid+body+previous+":return_blend_active")
    var foot:int=sk.find_bone("Foot_L")
    c.presentation_frozen=true;c._process(.1)
    check(c._neutral_return_age==0,fid+body+previous+":hitstop_freezes_return")
    c.presentation_frozen=false;player.advance(.04)
    var planted:Quaternion=sk.get_bone_pose_rotation(foot);c._blend_neutral_return(.04)
    check(planted.is_equal_approx(sk.get_bone_pose_rotation(foot)),fid+body+previous+":no_additive_foot_override")
    c._process(.05)
    check(c._neutral_return_pose.is_empty(),fid+body+previous+":bounded_return_finishes")
    # A fresh public action's timeline must immediately override continuity.
    c.play_for_state("hurt_heavy");player.advance(.12);c.play_for_state("idle")
    c.play_for_state("attack_startup",Data.find_move(Data.load_moves(fid),"jab_1"))
    check(c._neutral_return_pose.is_empty(),fid+body+previous+":next_attack_not_delayed_or_blended")
    rows.append({"fighter":fid,"body":body,"from":previous,"blend_seconds":.075,"foot_override":false,"gameplay_writes":false,"scope":"actual rig transition fixture, not human motion acceptance"})
   model.queue_free();await process_frame
 var f=FileAccess.open(output.path_join("neutral_return.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures},"  "));f.close()
 print("NEUTRAL_RETURN ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures.size());quit(0 if failures.is_empty() else 1)
