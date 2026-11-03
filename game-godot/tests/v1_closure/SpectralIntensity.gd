extends SceneTree
## Live presentation settings with persistent owners under pool pressure.
## Declared events, not combat/AI/combo or visual-quality acceptance.
const Renderer=preload("res://scripts/visual/spectral_feedback_renderer.gd")
var output := ""
var rows: Array=[]
var failures: Array=[]
func _init() -> void:call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if not ok:failures.append(label)
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9
	root.get_node("SceneRouter").go("battle")
	for i in range(200):await physics_frame
	var p=current_scene.fighter1;var d=current_scene.fighter2
	p.controls_enabled=false;d.controls_enabled=false
	var settings=root.get_node("StoryDialogue").settings;var saved=settings.duplicate(true)
	var renderer=Renderer.obtain(p)
	for fid in Renderer.IDS:
		for body in ["male","female"]:
			gs.p1_body_variant=body;p.configure(fid,1,false,9,Vector2(-150,240));p.controls_enabled=false
			for intensity in ["Full","Balanced","Reduced"]:
				for index in renderer.slots.size():renderer.stop_slot(index)
				settings.vfx_intensity="Full";settings.reduced_particles=false;settings.reduced_flash=false;settings.high_contrast_vfx=false
				var charge: int=renderer.emit_effect(fid,2,Vector2.ZERO,Vector2.RIGHT,45,-1)
				var projectile: int=renderer.emit_effect(fid,3,Vector2.ONE,Vector2.RIGHT,45,-1)
				for i in 94:renderer.emit_effect(fid,15,Vector2(i,0),Vector2.RIGHT,24,2.0)
				# Change the global UI setting while charge/projectile owners are live.
				settings.vfx_intensity=intensity
				await process_frame;await process_frame
				var label: String="%s:%s:%s"%[fid,body,intensity]
				var expected: float=.2 if intensity=="Reduced" else .6 if intensity=="Balanced" else 1.0
				var density: float=renderer.slots[charge].mesh.material.get_shader_parameter("density")
				check(is_equal_approx(density,expected),label+":global_intensity_live_density")
				check(renderer.slots[charge].active and renderer.slots[projectile].active,label+":persistent_owners_preserved")
				var limit:=32 if intensity=="Reduced" else 96
				check(renderer.active_count()<=limit,label+":live_budget")
				var before: int=renderer.history.filter(func(x):return x.kind==0).size()
				var info={"confirmed_contact":true,"combat_event_id":"intensity_fixture:"+label,"attacker_id":fid,"contact_world":Vector2.ZERO,"contact_direction":Vector2.RIGHT,"contact_result":"hit","feedback_tier":"heavy"}
				check(renderer.contact(info,d),label+":confirmed_accepted")
				check(renderer.history.filter(func(x):return x.kind==0).size()==before+1,label+":primary_confirmation")
				check(not renderer.contact(info,d),label+":dedup")
				# Independent reduced-density/flash/contrast controls remain effective.
				settings.reduced_particles=true;settings.reduced_flash=true;settings.high_contrast_vfx=true
				await process_frame;await process_frame
				check(is_equal_approx(float(renderer.slots[projectile].mesh.material.get_shader_parameter("density")),.2),label+":explicit_reduced_density")
				check(is_zero_approx(float(renderer.slots[projectile].mesh.material.get_shader_parameter("flash"))),label+":explicit_flash")
				check(renderer.slots[projectile].mesh.material.get_shader_parameter("accent").r>.9,label+":high_contrast")
				check(renderer.active_count()<=32 and renderer.slots[charge].active and renderer.slots[projectile].active,label+":toggle_keeps_owner_and_budget")
				rows.append({"fighter":fid,"body":body,"intensity":intensity,"density":density,"expected_density":expected,"limit":limit,"stats":renderer.stats()})
	root.get_node("StoryDialogue").settings=saved
	var f=FileAccess.open(output.path_join("spectral_intensity.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"scope":"54live-setting pressure cases,9fighters/18body models. Declared owned emitters and contact; no gameplay results or artistic approval."},"  "));f.close()
	print("SPECTRAL_INTENSITY ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures.size());quit(0 if failures.is_empty() else 1)
