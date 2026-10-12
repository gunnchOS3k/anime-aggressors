extends SceneTree
## Bounded recording-clock/foreground diagnostic only; no competitive acceptance.
var output := ""
var rows: Array=[]
var bars: Array=[]
var annotation: Label
func _init() -> void:call_deferred("_run")
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
	DisplayServer.window_move_to_foreground()
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p1_fighter_id="ember-vale";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=1800
	root.get_node("SceneRouter").go("battle")
	for i in range(220):await physics_frame
	var p=current_scene.fighter1;current_scene.fighter2.controls_enabled=false;current_scene.fighter2.position.x=440
	var layer:=CanvasLayer.new();layer.layer=100;current_scene.add_child(layer)
	annotation=Label.new();annotation.position=Vector2(20,120);annotation.add_theme_font_size_override("font_size",22);layer.add_child(annotation)
	for bit in range(20):
		var rect:=ColorRect.new();rect.position=Vector2(20+bit*12,190);rect.size=Vector2(10,24);layer.add_child(rect);bars.append(rect)
	for entry in [{"fighter":"ember-vale","body":"male"},{"fighter":"rook-ironside","body":"female"},{"fighter":"juno-spark","body":"male"}]:
		gs.p1_body_variant=entry.body;p.configure(entry.fighter,1,false,9,Vector2(-100,240));current_scene._p1_panel.configure(p.data.get("displayName",entry.fighter),Color(p.data.get("color",Color.WHITE)),9,false)
		var identity:=rows.size()/80
		for key in ["left","right"]:Input.action_release("p1_"+key)
		for frame in range(80):
			if frame==12:Input.action_press("p1_right",.65)
			if frame==35:Input.action_release("p1_right");Input.action_press("p1_left",.65)
			if frame==58:Input.action_release("p1_left")
			await physics_frame
			var index:=Engine.get_process_frames()-1
			annotation.text="%s · %s · process %d / drawn %d\nForeground clock diagnostic · public movement · idle target"%[entry.fighter,entry.body,index,Engine.get_frames_drawn()]
			var code: int=(index & 65535)|(int(identity)<<16)
			for bit in range(20):bars[bit].color=Color.WHITE if (code & (1<<bit)) else Color.BLACK
			rows.append({"fighter":entry.fighter,"body":entry.body,"expected_process_frame":index,"frames_drawn":Engine.get_frames_drawn(),"encoded_identity":int(identity),"position":[p.position.x,p.position.y],"motion":p.model_3d.get_animation_controller().get_locomotion_transition_evidence()})
	var f=FileAccess.open(output.path_join("native_presentation_clock.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"rows":rows,"scope":"3models80publicmovementframes each; foregroundrecordingclockdiagnostic, notfullroster/CPU/performanceacceptance"},"  "));f.close()
	print("NATIVE_PRESENTATION_CLOCK rows=",rows.size());quit()
