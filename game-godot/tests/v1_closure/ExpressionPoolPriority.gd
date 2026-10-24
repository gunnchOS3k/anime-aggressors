extends SceneTree
## Declared contact fixtures under presentation pressure; no combat or combo claims.
const Renderer=preload("res://scripts/visual/spectral_feedback_renderer.gd")
var output := ""
var rows: Array=[]
var failures: Array=[]
func _init() -> void:call_deferred("_run")
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9
	root.get_node("SceneRouter").go("battle")
	for i in range(200):await physics_frame
	var p=current_scene.fighter1;var d=current_scene.fighter2
	p.controls_enabled=false;d.controls_enabled=false
	var settings=root.get_node("StoryDialogue").settings
	var saved=settings.duplicate(true)
	var renderer=Renderer.obtain(p)
	for fid in Renderer.IDS:
		for body in ["male","female"]:
			gs.p1_body_variant=body;p.configure(fid,1,false,9,Vector2(-150,240));p.controls_enabled=false
			for intensity in ["Full","Balanced","Reduced"]:
				for index in renderer.slots.size():renderer.stop_slot(index)
				settings.vfx_intensity=intensity;settings.reduced_particles=intensity=="Reduced"
				var limit:=32 if intensity=="Reduced" else 96
				for i in limit:renderer.emit_effect(fid,15,Vector2(i,0),Vector2.RIGHT,24,1.0)
				var before: int=renderer.history.filter(func(x):return x.kind==0).size()
				var event_id: String="pressure_fixture:%s:%s:%s"%[fid,body,intensity]
				var info={"confirmed_contact":true,"combat_event_id":event_id,"attacker_id":fid,"contact_world":Vector2.ZERO,"contact_direction":Vector2.RIGHT,"contact_result":"hit","feedback_tier":"heavy"}
				var accepted: bool=renderer.contact(info,d)
				var primary: int=renderer.history.filter(func(x):return x.kind==0).size()-before
				var duplicate: bool=renderer.contact(info,d)
				if not accepted or primary!=1 or duplicate:failures.append(event_id+":confirmed_contact_lost_under_smear_pressure")
				if renderer.active_count()>limit:failures.append(event_id+":pool_limit")
				rows.append({"fighter":fid,"body":body,"intensity":intensity,"limit":limit,"primary_contacts":primary,"accepted":accepted,"duplicate":duplicate,"active_meshes":renderer.active_count(),"stats":renderer.stats()})
	root.get_node("StoryDialogue").settings=saved
	var f=FileAccess.open(output.path_join("expression_pool_priority.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"scope":"54 declared contact/presentation-pressure fixtures; no direct damage, AI, combo or device acceptance"},"  "));f.close()
	print("EXPRESSION_POOL_PRIORITY ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures.size());quit(0 if failures.is_empty() else 1)
