extends SceneTree
## Public input aura/movement review, both models simultaneously. No CPU/combos
## claimed here; foreground and visible barcodes verify root-render freshness.
const BodyAura=preload("res://scripts/visual/elemental_body_aura.gd")
var output := ""
var rows: Array=[]
var failures: Array=[]
var bars: Array=[]
var annotation: Label
var identity := 0
var p1: Node
var p2: Node
func _init() -> void:call_deferred("_run")
func release_inputs() -> void:
	for slot in [1,2]:
		for key in ["left","right","special","shield","jump","attack"]:Input.action_release("p%d_%s"%[slot,key])
func stamp(phase: String) -> void:
	var frame:=Engine.get_process_frames()-1
	annotation.text="%s · male LEFT / female RIGHT · %s\nPublic energy/movement fixture · no CPU/combo acceptance · frame %d"%[p1.fighter_id,phase,frame]
	var code: int=(frame & 65535)|(identity<<16)
	for bit in range(20):bars[bit].color=Color.WHITE if code & (1<<bit) else Color.BLACK
	rows.append({"fighter":p1.fighter_id,"identity":identity,"phase":phase,"expected_process_frame":frame,"physics_frame":Engine.get_physics_frames(),"p1_position":[p1.position.x,p1.position.y],"p2_position":[p2.position.x,p2.position.y],"male":p1.model_3d.get_empowerment_evidence(),"female":p2.model_3d.get_empowerment_evidence()})
func frames(count: int,phase: String) -> void:
	for i in range(count):await physics_frame;stamp(phase)
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true);DisplayServer.window_move_to_foreground()
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p1_fighter_id="ember-vale";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=1800
	root.get_node("SceneRouter").go("battle")
	for i in range(180):await physics_frame
	p1=current_scene.fighter1;p2=current_scene.fighter2
	var layer:=CanvasLayer.new();layer.layer=100;current_scene.add_child(layer)
	annotation=Label.new();annotation.position=Vector2(20,120);annotation.add_theme_font_size_override("font_size",20);layer.add_child(annotation)
	for bit in range(20):
		var rect:=ColorRect.new();rect.position=Vector2(20+bit*12,190);rect.size=Vector2(10,24);layer.add_child(rect);bars.append(rect)
	for fid in BodyAura.IDS:
		release_inputs();gs.p1_body_variant="male";gs.p2_body_variant="female"
		for p in [p1,p2]:
			p.configure(fid,p.slot,false,9,Vector2(-125 if p==p1 else 125,240));p.move_runner.cancel();p.state_machine.enter("idle");p.controls_enabled=true;p.invincible=false;p.clear_aura();p.velocity=Vector2.ZERO;p._hitstop=0
		current_scene._p1_panel.configure(p1.data.get("displayName",fid),Color(p1.data.get("color",Color.WHITE)),9,false)
		current_scene._p2_panel.configure(p2.data.get("displayName",fid),Color(p2.data.get("color",Color.WHITE)),9,false)
		await frames(35,"calm")
		for slot in [1,2]:Input.action_press("p%d_special"%slot);Input.action_press("p%d_shield"%slot)
		for i in range(235):
			await physics_frame;stamp("charging")
			if p1.aura>=100 and p2.aura>=100:break
		if p1.aura<100 or p2.aura<100:failures.append(fid+":public_charge")
		await frames(5,"maximum")
		release_inputs();await frames(20,"released_idle")
		Input.action_press("p1_left",.45);Input.action_press("p2_right",.45)
		await frames(14,"empowered_movement");release_inputs()
		Input.action_press("p1_jump");Input.action_press("p2_jump")
		await frames(9,"empowered_jump");release_inputs();await frames(31,"airborne")
		p1.clear_aura();p2.clear_aura();await frames(5,"depleted")
		identity+=1
	release_inputs()
	var f=FileAccess.open(output.path_join("native_empowerment.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"scope":"Nine fighter pairs/all18models; public charging/release/movement/jump, no CPU contact or combo acceptance"},"  "));f.close()
	print("NATIVE_EMPOWERMENT ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size());quit(0 if failures.is_empty() else 1)
