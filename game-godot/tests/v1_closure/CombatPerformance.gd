extends SceneTree
const Model=preload("res://scripts/fighters/fighter_model_3d.gd")
const Data=preload("res://scripts/data/data_loader.gd")
const Reaction=preload("res://scripts/combat/directional_hit_reaction.gd")
var output:=""
var rows:Array=[]
var failures:Array=[]
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
   var controller=model.get_animation_controller();var player=controller.get_animation_player();var sk=controller.get_skeleton()
   for metadata in controller._choreography_timing.values():
    check(not metadata.has("bone_tracks") and metadata.has("contact_frame"),fid+body+":timing_keeps_authority_without_duplicate_pose_arrays")
   for damage in [3.,12.]:
    for direction in [Vector2(110,-60),Vector2(-110,-60)]:
     var reaction:=Reaction.resolve(fid,direction,{"damage":damage,"feedback_tier":"light" if damage<8 else "heavy","combat_event_id":fid+str(damage)+str(direction)})
     model.apply_hurt_reaction(reaction);controller.play_for_state("launched")
     check(player.current_animation=="combat_choreography/"+str(reaction.performance_clip),fid+body+":real_damage_selects_reaction_not_generic_launch")
     var initial:Quaternion=sk.get_bone_pose_rotation(sk.find_bone("Chest"));player.seek(.12,true)
     var later:Quaternion=sk.get_bone_pose_rotation(sk.find_bone("Chest"))
     check(initial.angle_to(later)>.005,fid+body+":articulated_reaction")
     controller.presentation_frozen=true;var before:float=player.current_animation_position;controller._process(.06)
     check(absf(player.current_animation_position-before)<.0001,fid+body+":hitstop_freezes_reaction")
     controller.presentation_frozen=false;controller.play_for_state("idle")
     check(not player.current_animation.contains("reaction_"),fid+body+":control_return_selects_neutral")
     rows.append({"fighter":fid,"body":body,"damage":damage,"incoming":[direction.x,direction.y],"reaction":reaction.performance_clip,"chest_change_rad":initial.angle_to(later),"model":model._proxy_model.scene_file_path,"scope":"live rig presentation fixture; no CPU/combo or owner visual approval"})
   model.queue_free();await process_frame
 var f=FileAccess.open(output.path_join("combat_performance.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows},"  "));f.close()
 print("COMBAT_PERFORMANCE ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures.size());quit(0 if failures.is_empty() else 1)
