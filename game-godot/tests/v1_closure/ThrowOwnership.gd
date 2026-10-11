extends SceneTree
## Reconfigured source fixture. Grabs/throws use public controls; never combo/KO proof.
const Renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd")
var output := ""
var failures: Array = []
var rows: Array = []
var contacts: Array = []
var feedback: Array = []
var damages: Array = []
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func release_inputs() -> void:
	for key in ["attack","grab","up","down","left","right","shield"]: Input.action_release("p1_"+key)
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.get_slice("=",1)
	var gs = root.get_node("GameState")
	gs.mode="versus"; gs.stage_id="training-grid"; gs.p1_fighter_id="ember-vale"; gs.p2_fighter_id="juno-spark"; gs.p2_is_cpu=false; gs.stocks=9
	root.get_node("SceneRouter").go("battle")
	for i in range(220): await physics_frame
	var p = current_scene.fighter1
	var d = current_scene.fighter2
	p.hit_resolver.hit_confirmed.connect(func(a,b,info): if a==p and b==d: contacts.append(info.duplicate(true)))
	p.combat_feedback.feedback_triggered.connect(func(info): feedback.append(info.duplicate(true)))
	d.damaged.connect(func(amount,_total): damages.append(amount))
	for fid in Renderer.IDS:
		for direction in ["forward","back","up","down"]:
			await run_case(p,d,fid,direction,"body")
	# Existing policy: grab bypasses shield hold; active armor gates throw damage.
	await run_case(p,d,"ember-vale","forward","shield")
	await run_case(p,d,"rook-ironside","up","armor")
	await run_case(p,d,"juno-spark","back","interrupt")
	# Invincible victims cannot be grabbed.
	release_inputs(); p.configure("juno-spark",1,false,9,Vector2(-80,240)); d.configure("ember-vale",2,false,9,Vector2(-48,240))
	reset_fixture(p,d); d.invincible=true
	Input.action_press("p1_grab")
	for i in range(25): await physics_frame
	check(p.grabbed_target==null,"invincible:grab_rejected"); release_inputs()
	if output!="":
		var f=FileAccess.open(output.path_join("throw_ownership.json"),FileAccess.WRITE)
		f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"scope":"public grab/throw controls with reconfigured idle defender; authority regression, not active-CPU combo evidence","balance_data_changed":false},"  ")); f.close()
	print("THROW_OWNERSHIP ","PASS" if failures.is_empty() else "FAIL", " rows=", rows.size())
	quit(0 if failures.is_empty() else 1)
func run_case(p,d,fid: String,direction: String,policy: String) -> void:
	release_inputs()
	p.configure(fid,1,false,9,Vector2(-80,240)); d.configure("juno-spark" if fid!="juno-spark" else "ember-vale",2,false,9,Vector2(-48,240))
	reset_fixture(p,d)
	for i in range(6): await physics_frame
	if policy=="shield": d.state_machine.enter("shield_hold")
	if policy=="armor": d.armor_frames_remaining=5.0
	contacts.clear(); feedback.clear(); damages.clear()
	var renderer=Renderer.obtain(p)
	var history_start: int=renderer.history.size()
	Input.action_press("p1_grab")
	for i in range(25):
		await physics_frame
		if p.grabbed_target==d: break
	Input.action_release("p1_grab")
	var prefix:=fid+":"+direction+":"+policy
	check(p.grabbed_target==d and d.grabbed_by==p,prefix+":genuine_grab")
	if p.grabbed_target!=d: return
	# Place the held victim inside the previous grab region. The release offset is authored.
	var input: String= "right" if direction=="forward" else "left" if direction=="back" else direction
	Input.action_press("p1_"+input)
	Input.action_press("p1_attack")
	for i in range(3): await physics_frame
	release_inputs(); p.controls_enabled=false
	check(contacts.size()==1,prefix+":one_release_contact")
	var before: float=d.damage_percent
	var throw_move: Dictionary=p._current_move.duplicate(true)
	# Repeated callbacks must not bypass ownership even if invoked explicitly.
	var duplicate: Dictionary=p.hit_resolver.resolve(p,d,throw_move,p.damage_percent)
	check(duplicate.is_empty(),prefix+":resolver_rejects_repeat")
	check(not p.hitbox.monitoring,prefix+":no_stale_hitbox_at_release")
	if policy=="interrupt":
		p.receive_hit(d,{"damage":1.0,"launch":Vector2.ZERO,"hitstop_frames":2,"move_id":"jab_1"})
		check(not p.move_runner.active and not p.hitbox.monitoring,prefix+":interruption_cleanup")
	for i in range(65): await physics_frame
	check(contacts.size()==1 and feedback.size()==1,prefix+":one_authoritative_contact_and_audio_dispatch")
	var impacts: Array=renderer.history.slice(history_start).filter(func(h):return str(h.get("event_id","")).contains("contact"))
	# Contact IDs own meshes; count the primary impact (hurt has an independent ID).
	if not contacts.is_empty():
		var event: String=contacts[0].combat_event_id
		var primary: int=renderer.history.slice(history_start).filter(func(h):return h.event_id==event).size()
		check(primary==1,prefix+":one_impact_mesh")
		if policy=="armor":
			check(damages.is_empty() and contacts[0].contact_result=="armor",prefix+":existing_armor_gate")
		else:
			check(damages.size()==1 and is_equal_approx(float(damages[0]),float(contacts[0].damage)),prefix+":one_damage_application")
			check(contacts[0].contact_result=="hit",prefix+":body_or_grab_bypasses_shield")
	check(is_equal_approx(d.damage_percent,before),prefix+":no_later_damage")
	check(not p.hitbox.monitoring and p.grabbed_target==null and d.grabbed_by==null,prefix+":release_cleanup")
	rows.append({"fighter":fid,"direction":direction,"policy":policy,"contacts":contacts.size(),"damage_applications":damages.size(),"feedback_dispatches":feedback.size(),"damage":before,"defender_state_after":d.state_machine.current_state,"release_frame":contacts[0].move_frame if not contacts.is_empty() else -1})

func reset_fixture(p,d) -> void:
	p.move_runner.cancel(); d.move_runner.cancel()
	p.grabbed_target=null; d.grabbed_by=null
	p.global_position=Vector2(-80,240); d.global_position=Vector2(-48,240)
	p.velocity=Vector2.ZERO; d.velocity=Vector2.ZERO
	p.state_machine.enter("idle"); d.state_machine.enter("idle")
	p.controls_enabled=true; d.controls_enabled=false
	p.invincible=false; d.invincible=false; p.aura=0; d.aura=0
	p._hitstop=0; d._hitstop=0; p.hitstun_remaining=0; d.hitstun_remaining=0
	p.damage_percent=0; d.damage_percent=0; d.armor_frames_remaining=0
	p.facing=1; d.facing=-1
