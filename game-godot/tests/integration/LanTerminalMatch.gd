extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Declared ordinary walk-off terminal test, NOT attack-earned KO acceptance.
## Exercises guest results, late-input rejection and BOTH players' UI rematch.
const Controls = preload("res://scripts/net/lan_controls.gd")
var lan
var side := ""
var port := 27834
var first_terminal: Dictionary = {}
var career_before := 0
var late_sent := false

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output=arg.trim_prefix("--ordinary-output=")
		if arg.begins_with("--lan-role="): side=arg.trim_prefix("--lan-role=")
		if arg.begins_with("--lan-port="): port=int(arg.trim_prefix("--lan-port="))
	if output.is_empty() or side not in ["host","guest"] or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Explicit isolated LAN test required");quit(2);return
	lan=root.get_node("LanSession")
	career_before=int(root.get_node("GameState").career_matches)
	if side=="host":await host_run()
	else:await guest_run()
	finish()

func host_run() -> void:
	var gs=root.get_node("GameState")
	gs.p1_fighter_id="kaia-windrow";gs.p2_fighter_id="juno-spark"
	gs.p1_body_variant="female";gs.p2_body_variant="male"
	gs.stage_id="training-grid";gs.stocks=1;gs.ruleset_id="stock-1";gs.match_type="stock";gs.match_timer_seconds=180
	check(lan.host(port,"127.0.0.1")==OK,"real_ENet_server")
	var ready=FileAccess.open(output.path_join("HOST_READY"),FileAccess.WRITE);ready.store_string("ready");ready.close()
	for i in range(600):
		await physics_frame
		if lan.guest_id>1:break
	check(lan.start_match(),"host_starts_legal_one_stock_match")
	for i in range(420):
		await physics_frame
		if active_battle():break
	if not active_battle():check(false,"actual_host_battle_started");return
	battle=current_scene
	var starting_epoch:int=lan.epoch
	for i in range(600):
		await physics_frame
		if battle._match_finished:break
	check(battle._match_finished and battle.fighter2.stocks==0,"ordinary_guest_walkoff_real_terminal_stock_loss")
	first_terminal=lan.latest.duplicate(true)
	check(first_terminal.phase=="result" and not first_terminal.active and first_terminal.closed and int(first_terminal.winner)==1,"first_terminal_snapshot_has_committed_winner_and_phase")
	check(first_terminal.actors[0].state=="victory" and first_terminal.actors[1].state in ["ko","defeat"],"first_terminal_snapshot_has_real_terminal_acting")
	var accepted:int=lan.received_inputs
	var rejected:int=lan.rejected_inputs
	await frames(20)
	check(lan.received_inputs==accepted and lan.rejected_inputs>rejected,"real_socket_late_terminal_controls_rejected")
	for i in range(120):
		await physics_frame
		if route_is("ResultsScene.tscn"):break
	check(route_is("ResultsScene.tscn") and gs.last_winner_slot==1,"host_actual_results_match_winner")
	if not route_is("ResultsScene.tscn"):return
	check(gs.career_matches==career_before+1,"host_awards_real_result_once")
	current_scene.rematch_btn.grab_focus();await accept_focused()
	check(lan.local_rematch_ready or lan.epoch>starting_epoch,"host_actual_UI_requests_rematch")
	for i in range(480):
		await physics_frame
		if lan.epoch>starting_epoch and active_battle():break
	check(lan.epoch==starting_epoch+1 and active_battle(),"both_consents_start_new_epoch_BattleScene")
	if not active_battle():return
	battle=current_scene
	check(battle.fighter1.damage_percent==0 and battle.fighter2.damage_percent==0 and battle.fighter2.stocks==1,"fresh_rematch_damage_and_stocks")
	battle.fighter2.hit_resolver.hit_confirmed.connect(record_contact)
	for i in range(300):
		await physics_frame
		if not contacts.is_empty():break
	check(contacts.any(func(row):return row.attacker=="juno-spark" and row.result=="hit"),"guest_controls_remain_bound_after_real_rematch")
	var rematch_instance: int = battle.get_instance_id()
	# Actual pause UI Return; never call a fabricated result or reset damage.
	var cancel=InputEventAction.new();cancel.action="ui_cancel";cancel.pressed=true;Input.parse_input_event(cancel)
	await process_frame
	cancel=cancel.duplicate();cancel.pressed=false;Input.parse_input_event(cancel)
	for i in range(60):
		if battle._pause_panel != null and battle._paused: break
		await process_frame
	check(battle._pause_panel != null and battle._paused,"actual_rematch_pause_UI_opened")
	if battle._pause_panel == null or not battle._paused:return
	for button in battle._pause_panel.find_children("*","Button",true,false):
		if button.text.contains("Return"):
			button.grab_focus();await accept_focused();break
	await frames(5)
	check(route_is("MainMenuScene.tscn") and lan.role.is_empty(),"actual_menu_return_retires_LAN_session")
	check(preload("res://scripts/audio/procedural_audio_bank.gd").active_players().all(func(player):return int(player.get_meta("audio_scene_owner",0))!=rematch_instance),"actual_menu_return_retires_match_owned_audio_players")
	check(gs.career_matches==career_before+1,"abandoned_rematch_does_not_award_result")

func guest_run() -> void:
	check(lan.join("127.0.0.1",port)==OK,"real_guest_connect")
	for i in range(900):
		await physics_frame
		if lan.latest.is_empty():continue
		if lan.latest.get("phase","")=="result":
			first_terminal=lan.latest.duplicate(true)
			keys(["attack"])
			lan._send(1,Controls.local_packet(lan.epoch,lan._sequence));lan._sequence+=1
			late_sent=true;keys([]);break
		keys(["right"] if lan.latest.get("active",false) else [])
	check(late_sent,"late_control_probe_sent_over_actual_socket_after_terminal")
	check(not first_terminal.get("active",true) and int(first_terminal.get("winner",-1))==1,"guest_observes_same_authoritative_terminal_result")
	for i in range(120):
		await physics_frame
		if route_is("ResultsScene.tscn"):break
	check(route_is("ResultsScene.tscn"),"guest_actual_ResultsScene_loaded")
	if not route_is("ResultsScene.tscn"):return
	check(root.get_node("GameState").last_winner_slot==1 and int(root.get_node("GameState").career_matches)==career_before,"guest_result_display_does_not_award_progress")
	var old_epoch:int=lan.epoch
	await frames(30)
	current_scene.rematch_btn.grab_focus();await accept_focused()
	check(lan.local_rematch_ready or lan.epoch>old_epoch,"guest_actual_UI_requests_rematch")
	for i in range(480):
		await physics_frame
		if lan.epoch>old_epoch and lan.latest.get("active",false):break
	check(lan.epoch==old_epoch+1 and "_lan_replica" in current_scene and current_scene._lan_replica!=null,"guest_new_epoch_real_BattleScene")
	if lan.epoch<=old_epoch:return
	for i in range(240):
		await physics_frame
		var snapshot:Dictionary=lan.latest
		var dx:float=float(snapshot.actors[0].position[0])-float(snapshot.actors[1].position[0])
		keys(["right" if dx>0 else "left"] if absf(dx)>54 else (["attack"] if i%32<3 else []))
		if float(snapshot.actors[0].damage)>0:break
	keys([])
	check(float(lan.latest.actors[0].damage)>0,"guest_sees_real_rematch_contact")
	await frames(60)
	check(lan.peer == null and lan._closed,"host_menu_return_retires_inactive_guest_transport")
	check(int(root.get_node("GameState").career_matches)==career_before,"guest_never_records_host_career_result")

func finish() -> void:
	keys([])
	var result={"PASS":failures.is_empty(),"role":side,"checks":checks,"failures":failures,"first_terminal":first_terminal,"contacts":contacts,
		"scope":"Actual two-process ENet terminal snapshot, declared ordinary walk-off (not attack-earnedKO), real Results UI, both-consent rematch, fresh epoch and real rematch melee; no Story/privateart/nativevisual/rollback approval",
		"HUMAN_ART_APPROVED":false,"RC2_READY":false,"V1_0_0_RELEASE_AUTHORIZED":false}
	var file=FileAccess.open(output.path_join("LAN_"+side.to_upper()+".json"),FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
	lan.stop()
	print("LAN_TERMINAL ",side," ","PASS" if failures.is_empty() else "FAIL"," failures=",failures)
	quit(0 if failures.is_empty() else 1)
