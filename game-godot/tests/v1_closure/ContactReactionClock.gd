extends SceneTree
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
 var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9
 root.get_node("SceneRouter").go("battle")
 for i in range(180):await physics_frame
 var p=current_scene.fighter1;var d=current_scene.fighter2
 for fid in preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS:
  for body in ["male","female"]:
   gs.p1_body_variant=body;gs.p2_body_variant=body
   p.configure(fid,1,false,9,Vector2(-20,240));d.configure(fid,2,false,9,Vector2(20,240))
   p.controls_enabled=false;d.controls_enabled=false;p.invincible=false;d.invincible=false;p._hitstop=0;d._hitstop=0
   p.training_play_move("jab_1")
   var c=d.model_3d.get_animation_controller();c.presentation_frozen=false
   var info:Dictionary=p.hit_resolver.resolve(p,d,p._current_move,0)
   check(info.get("confirmed_contact",false),fid+body+":resolver_contact")
   var player=c.get_animation_player();var before:float=player.current_animation_position
   check(d._hitstop>0 and c.presentation_frozen,fid+body+":contact_freezes_reaction_in_same_callback")
   c._process(1.0/60.0)
   check(absf(player.current_animation_position-before)<.000001,fid+body+":no_first_render_frame_slip")
   rows.append({"fighter":fid,"body":body,"contact_frame":info.get("gameplay_frame",-1),"hitstop_seconds":d._hitstop,"presentation_frozen":c.presentation_frozen,"before":before,"after":player.current_animation_position,"scope":"declared resolver-to-live-rig pipeline fixture, not ordinary combo acceptance"})
   p.move_runner.cancel();d.move_runner.cancel()
 var f=FileAccess.open(output.path_join("contact_reaction_clock.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures},"  "));f.close()
 print("CONTACT_REACTION_CLOCK ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures.size());quit(0 if failures.is_empty() else 1)
