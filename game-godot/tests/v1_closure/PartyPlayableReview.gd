extends SceneTree
## Isolated owner selection; ordinary controls and active CPU. Initial item is a
## declared review placement. No fabricated battle result, save or Story unlock.
func _init() -> void:call_deferred("run")
func run() -> void:
	await process_frame
	var fighter:="kaia-windrow";var opponent:="juno-spark";var body:="female";var item:="prism_heart"
	var local:=false;var smoke:=false;var break_candidate:=false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--party-fighter="):fighter=arg.get_slice("=",1)
		if arg.begins_with("--party-opponent="):opponent=arg.get_slice("=",1)
		if arg.begins_with("--party-body="):body=arg.get_slice("=",1)
		if arg.begins_with("--party-item="):item=arg.get_slice("=",1)
		if arg=="--party-local":local=true
		if arg=="--shield-break-candidate":break_candidate=true
		if arg=="--party-smoke":smoke=true
	var ids=preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS
	if fighter not in ids or opponent not in ids or body not in ["male","female"] or item not in ["prism_heart","black_seal","white_seal"]:quit(2);return
	var gs=root.get_node("GameState")
	gs.mode="versus";gs.items_enabled=true;gs.hazards_enabled=false;gs.stage_id="training-grid"
	gs.p1_fighter_id=fighter;gs.p2_fighter_id=opponent;gs.p1_is_cpu=false;gs.p2_is_cpu=not local;gs.cpu_level=3
	gs.p1_body_variant=body;gs.p2_body_variant=body;gs.stocks=3;gs.match_timer_seconds=180
	root.get_node("SceneRouter").go("battle")
	for i in range(220):await physics_frame
	# Review-only keyboard convenience on the EXISTING normalized taunt channel.
	# Shipping hardware/controller adapters and PartyLink remain separately owned.
	for slot in [1,2]:
		var event:=InputEventKey.new();event.physical_keycode=KEY_T if slot==1 else KEY_F8
		InputMap.action_add_event("p%d_taunt"%slot,event)
	var p=current_scene.fighter1
	if break_candidate:
		for actor in [p,current_scene.fighter2]:actor.set_meta("shield_break_8c_candidate",true)
	var token:int=current_scene._hazard_runtime.spawn_party_item("prism_heart" if item=="prism_heart" else "puppet_seal",p.global_position+Vector2(0,-24),"WHITE" if item=="white_seal" else "BLACK")
	var label:=Label.new();label.position=Vector2(30,100);label.size=Vector2(1050,155)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.text="PARTY TUNING CANDIDATES · "+fighter+" / "+opponent+" · "+body+" · "+("local players" if local else "active CPU")+"\nA/D move · J light · J+K heavy · K special · W jump · L shield · U grab · I dodge.\nPick up the placed item. T activates; press T again after Prism activation for one ultimate. Seals alter side special for10s. P2 Taunt: F8.\nPerfect Guard: tap grounded shield within4frames of contact; grabs still work. No reflection. Original3D ultimate acting, cosmic kaiju art and final balance pending."
	label.text+="\nPermanent advancements: build aura with shield+special, then press attack while both held. Each fighter has two separate stages. Original saved acting and stage structures are WIP, not human approved."
	if break_candidate:label.text+="\nOPT-IN SHIELD BREAK CANDIDATE:66-frame recovery,45% guard restore; release guard before re-entry. Balance unapproved."
	current_scene.hud.add_child(label)
	if smoke:
		print("PARTY_REVIEW_READY ",fighter," ",opponent," ",body," CPU=",current_scene.fighter2.is_cpu," token=",token," items=",gs.items_enabled)
		quit(0 if token>0 and p.model_3d.is_model_loaded() else 1)
