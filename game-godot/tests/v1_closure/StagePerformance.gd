extends SceneTree
const Renderer=preload("res://scripts/visual/spectral_feedback_renderer.gd")
var output:=""
var failures:Array=[]
var rows:Array=[]
func _init():call_deferred("run")
func check(value:bool,label:String):
 if not value:failures.append(label)
func count(renderer,kind:int)->int:return renderer.history.filter(func(row):return row.kind==kind).size()
func run():
 await process_frame
 for a in OS.get_cmdline_user_args():
  if a.begins_with("--ordinary-output="):output=a.get_slice("=",1)
 var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=1800
 root.get_node("SceneRouter").go("battle")
 for i in range(200):await physics_frame
 var p=current_scene.fighter1;var d=current_scene.fighter2
 p.controls_enabled=false;d.controls_enabled=false
 var renderer=Renderer.obtain(p)
 var settings=root.get_node("StoryDialogue").settings
 for fid in Renderer.IDS:
  for mode in ["Full","Balanced","Reduced"]:
   settings.vfx_intensity=mode;settings.reduced_particles=false;settings.reduced_flash=mode=="Reduced"
   for i in renderer.slots.size():renderer.stop_slot(i)
   var event:Dictionary={"confirmed_contact":true,"combat_event_id":fid+mode,"attacker_id":fid,"contact_world":Vector2(0,216),"contact_direction":Vector2.RIGHT,"contact_result":"hit","feedback_tier":"heavy","move_id":"heavy_attack"}
   var before:=count(renderer,18);var residue:=count(renderer,19)
   check(renderer.contact(event,d),fid+mode+":contact_accepted")
   check(count(renderer,18)==before+1,fid+mode+":actual_surface_response")
   check(count(renderer,19)==residue+(0 if mode=="Reduced" else 1),fid+mode+":bounded_residue_mode")
   var stage:Dictionary=renderer.history.filter(func(row):return row.kind==18).back()
   check(absf(stage.world[1]-(float(gs.load_stage(gs.stage_id).mainPlatform.y)-2.0))<.1,fid+mode+":actual_platform_surface_position")
   renderer.contact(event,d);check(count(renderer,18)==before+1,fid+mode+":dedup")
   var miss:=event.duplicate();miss.combat_event_id+="miss";miss.confirmed_contact=false
   check(not renderer.contact(miss,d),fid+mode+":whiff_rejected")
   var airborne:=event.duplicate();airborne.combat_event_id+="air";airborne.contact_world=Vector2(1100,-400)
   check(not renderer.stage_contact(airborne,d),fid+mode+":empty_space_has_no_surface")
   var shield:=event.duplicate();shield.combat_event_id+="shield";shield.contact_result="shield"
   var old_residue:=count(renderer,19);renderer.contact(shield,d)
   check(count(renderer,19)==old_residue,fid+mode+":shield_no_lingering_damage_presentation")
   rows.append({"fighter":fid,"mode":mode,"stage":stage,"scope":"explicit collision-contract fixture, queried stage surface, no CPU/combo acceptance"})
 # All decoration must expire and yield to actual contact under saturation.
 settings.vfx_intensity="Full"
 for i in renderer.slots.size():renderer.stop_slot(i)
 for i in range(96):renderer.emit_effect("kaia-windrow",18,Vector2.ZERO,Vector2.RIGHT,180,.3)
 check(renderer.emit_effect("juno-spark",0,Vector2.ZERO,Vector2.RIGHT,100,.2)>=0,"contact_evicts_stage_decoration")
 renderer._process(2)
 check(renderer.active_count()==0,"all_surface_decorations_expire")
 check(renderer.slots.size()<=96,"bounded_shared_pool")
 var f=FileAccess.open(output.path_join("stage_performance.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"pool":renderer.stats(),"gameplay_writes":false},"  "));f.close()
 print("STAGE_PERFORMANCE ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures.size());quit(0 if failures.is_empty() else 1)
