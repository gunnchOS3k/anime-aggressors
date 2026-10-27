extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Two real processes; public Input actions reach host's existing Fighter.
## No direct move, damage, position, stock, winner or progression injection.
const LanControls = preload("res://scripts/net/lan_controls.gd")
var lan
var side := ""
var port := 27834
var guest_samples: Array = []
var move_starts: Array = []
var guard_events: Array = []
var grab_events: Array = []
var before_campaign := ""
var whiff_damage := -1.0
var spoof_sent := false
var batch_sent := false
var batch_observation: Dictionary = {}
var replica_rows: Array = []
var replica_contacts := 0
var guest_career := 0

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
		if arg.begins_with("--lan-role="): side = arg.trim_prefix("--lan-role=")
		if arg.begins_with("--lan-port="): port = int(arg.trim_prefix("--lan-port="))
	if output.is_empty() or side not in ["host", "guest"] or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Explicit LAN role/output and isolated profile required"); quit(2); return
	lan = root.get_node("LanSession")
	before_campaign = JSON.stringify(root.get_node("CampaignRuntime").progress)
	guest_career = int(root.get_node("GameState").career_matches)
	if side == "host": await host_run()
	else: await guest_run()
	finish()

func host_run() -> void:
	var gs = root.get_node("GameState")
	# Legal pre-match selections, never in-match modifications.
	gs.p1_fighter_id = "kaia-windrow"; gs.p2_fighter_id = "juno-spark"
	gs.p1_body_variant = "female"; gs.p2_body_variant = "male"
	gs.stage_id = "training-grid"; gs.stocks = 3; gs.match_timer_seconds = 180
	gs.match_type = "stock"; gs.ruleset_id = "stock-3"
	check(lan.host(port, "127.0.0.1") == OK, "real_ENet_server_listen")
	var ready = FileAccess.open(output.path_join("HOST_READY"), FileAccess.WRITE)
	ready.store_string(str(OS.get_process_id())); ready.close()
	for i in range(600):
		await physics_frame
		if lan.guest_id != 0 and lan.guest_pick_ready: break
	check(lan.guest_id > 1, "independent_guest_peer_connected")
	if lan.guest_id == 0: return
	await frames(6) # Bounded real lobby request/ack exchange, before any match.
	check(lan.guest_pick_ready and gs.p2_fighter_id == "juno-spark" and gs.p2_body_variant == "male", "guest_owned_lobby_selection_acknowledged")
	check(lan.rejected_inputs >= 5 and gs.p1_fighter_id == "kaia-windrow" and gs.p1_body_variant == "female", "invalid_locked_or_spoofed_lobby_choices_cannot_own_host_or_unlock_fighters")
	check(lan.start_match(), "host_starts_existing_BattleScene")
	for i in range(420):
		await physics_frame
		if active_battle(): break
	check(active_battle(), "real_BattleScene_countdown_and_combat")
	if not active_battle(): return
	battle = current_scene
	check(int(lan.latest.simulation_frame) > 0 and int(lan.latest.completed_engine_frame) <= Engine.get_physics_frames(), "snapshots_follow_completed_real_combat_steps")
	check(not battle.fighter1.is_cpu and not battle.fighter2.is_cpu, "two_player_no_CPU_substitution")
	check(battle.fighter2.remote_controls == lan.remote and battle.fighter1.remote_controls == null, "only_guest_slot_bound")
	for actor in [battle.fighter1, battle.fighter2]:
		actor.hit_resolver.hit_confirmed.connect(record_contact)
		actor.move_runner.move_started.connect(func(id): move_starts.append({"slot":actor.slot,"move":id,"frame":lan.combat_frames}))
		actor.shield_event.connect(func(info): guard_events.append({"slot":actor.slot,"info":info,"frame":lan.combat_frames}))
		actor.grab_event.connect(func(info): grab_events.append({"slot":actor.slot,"info":info,"frame":lan.combat_frames}))
	for i in range(900):
		var f: int = lan.combat_frames
		if f == 88 or f == 89: whiff_damage = battle.fighter1.damage_percent
		# Shield practice: only host's ordinary keys attack the guest.
		if f >= 270 and f < 420:
			var dx: float = battle.fighter2.position.x - battle.fighter1.position.x
			if absf(dx) > 54: keys(["right" if dx > 0 else "left"])
			else: keys(["attack"] if f % 32 < 2 else [])
		else: keys([])
		if f >= 680: break
		await physics_frame
	keys([])
	check(whiff_damage == 0.0, "remote_whiff_did_not_apply_damage")
	check(move_starts.any(func(row): return row.slot == 2 and int(row.frame) < 90), "socket_batched_public_press_release_survives_one_physics_frame")
	check(move_starts.any(func(row): return row.slot == 2), "remote_public_input_started_real_move")
	check(contacts.any(func(row): return row.attacker == "juno-spark" and float(row.damage) > 0), "remote_melee_real_confirmed_damage")
	check(contacts.any(func(row): return row.defender == "juno-spark" and row.result in ["shield", "parry"]), "remote_guard_real_contact")
	check(grab_events.any(func(row): return row.slot == 2 and row.info.get("result", "") == "success"), "remote_genuine_grab_acquired")
	check(contacts.any(func(row): return row.attacker == "juno-spark" and row.move.begins_with("throw_")), "remote_public_attack_released_real_throw")
	check(lan.rejected_inputs > 0, "spoofed_host_slot_packet_rejected")
	check(battle.fighter1.remote_controls == null, "guest_never_owned_host_slot")
	# Guest disconnects while right is held. Real ENet teardown must neutralize it.
	for i in range(180):
		await physics_frame
		if lan.guest_id == 0: break
	check(lan.guest_id == 0 and lan.remote.axis() == 0.0 and lan.remote.buttons.is_empty(), "disconnect_clears_held_remote_controls")
	check(not battle._match_finished and gs.last_winner_slot == -1, "disconnect_does_not_invent_match_result")
	var stopped_damage: Array = [battle.fighter1.damage_percent, battle.fighter2.damage_percent]
	await frames(30)
	check(battle._network_abandoned and not battle._active and battle.fighter1.combat_closed and battle.fighter2.combat_closed, "disconnect_abandons_nonterminal_combat_authority")
	check(stopped_damage == [battle.fighter1.damage_percent, battle.fighter2.damage_percent] and not battle._match_finished, "abandoned_network_match_cannot_gain_late_damage_or_result")
	var rejected: int = lan.rejected_inputs
	lan._receive(999, {"kind":"input", "epoch":lan.epoch, "seq":2147483600, "axis":1.0, "buttons":{}})
	check(lan.rejected_inputs == rejected + 1 and lan.remote.axis() == 0.0, "retired_session_rejects_late_input")
	check(before_campaign == JSON.stringify(root.get_node("CampaignRuntime").progress), "Story_save_ownership_unchanged")
	root.get_node("SceneRouter").go("main_menu")
	await frames(5)
	check(lan._battle == null and lan._closed, "scene_exit_retires_bound_battle")

func guest_run() -> void:
	root.get_node("GameState").p1_fighter_id = "juno-spark"
	root.get_node("GameState").p1_body_variant = "male"
	check(lan.join("127.0.0.1", port) == OK, "independent_ENet_client_connect")
	for i in range(600):
		await physics_frame
		if not lan._lobby_id.is_empty(): break
	var rejected_choices: Array = [
		{"fighter":"../../not-a-fighter", "body":"male"},
		{"fighter":"juno-spark", "body":"invalid"},
		{"fighter":"yin", "body":"male"},
		{"fighter":"juno-spark", "body":"male", "slot":1},
		{"fighter":"juno-spark", "body":"male", "unlocked":true}]
	for choice in rejected_choices:
		var packet: Dictionary = {"kind":"selection", "lobby":lan._lobby_id, "revision":1000, "fighter":"juno-spark", "body":"male"}
		packet.merge(choice, true); lan._send(1, packet)
	for i in range(1500):
		await physics_frame
		if lan.latest.is_empty(): continue
		var state: Dictionary = lan.latest
		if not state.get("active", false): keys([]); continue
		var f: int = int(state.combat_frame)
		var a: Dictionary = state.actors[0]
		var b: Dictionary = state.actors[1]
		if not spoof_sent:
			var spoof = LanControls.local_packet(lan.epoch, 0)
			spoof["slot"] = 1; spoof["damage"] = 999
			lan._send(1, spoof); spoof_sent = true
			lan._send(1, {"kind":"selection", "lobby":lan._lobby_id, "revision":1001, "fighter":"ember-vale", "body":"female"})
		if f < 90:
			keys([])
			# Countdown starts actors above the floor. A fresh tap during LAND
			# recovery is correctly rejected; exercise socket edge retention only
			# once the actual host reports an eligible neutral, grounded actor.
			if f >= 15 and not batch_sent and b.state == "idle" and b.grounded and not b.move_active and float(b.hitstop) <= 0.0:
				batch_observation = {"combat_frame":f, "actor":b.duplicate(true)}
				keys(["attack"])
				lan._send(1, LanControls.local_packet(lan.epoch, lan._sequence)); lan._sequence += 1
				keys([])
				lan._send(1, LanControls.local_packet(lan.epoch, lan._sequence)); lan._sequence += 1
				batch_sent = true
		elif f < 270:
			var dx: float = float(a.position[0]) - float(b.position[0])
			if absf(dx) > 54: keys(["right" if dx > 0 else "left"])
			else: keys(["attack"] if f % 32 < 3 else [])
		elif f < 420: keys(["shield"])
		elif f < 660:
			var dx: float = float(a.position[0]) - float(b.position[0])
			if b.state == "grab_hold": keys(["attack", "down"] if f % 12 < 5 else [])
			elif absf(dx) > 48: keys(["right" if dx > 0 else "left"])
			else: keys(["grab"] if f % 35 < 4 else [])
		else:
			keys(["right"])
			if f >= 690:
				await frames(5)
				lan.stop()
				break
		if f % 30 < 3:
			guest_samples.append(state.duplicate(true))
			if current_scene != null and "_lan_replica" in current_scene and current_scene._lan_replica != null:
				var replica = current_scene._lan_replica
				var p = current_scene.fighter1; var d = current_scene.fighter2
				replica_rows.append({"sequence":replica.sequence,"sample":replica.sample.sequence,
					"damage_matches":p.damage_percent == float(replica.sample.actors[0].damage) and d.damage_percent == float(replica.sample.actors[1].damage),
					"shield_matches":d.shield_health == float(replica.sample.actors[1].shield),
					"no_local_authority":p.combat_closed and d.combat_closed and not p.is_physics_processing() and not d.is_physics_processing() and not p.hitbox.monitoring and not d.hitbox.monitoring,
					"models":p.model_3d.is_model_loaded() and d.model_3d.is_model_loaded(),
					"clips":[p.model_3d.get_animation_controller().get_active_clip(),d.model_3d.get_animation_controller().get_active_clip()]})
				replica_contacts = replica.presented_contacts.size()
	keys([])
	check(spoof_sent, "spoof_probe_sent_over_actual_socket")
	check(lan.lobby_state.get("guest_ready", false) and lan.lobby_state.get("p2", {}).get("fighter", "") == "juno-spark", "guest_observes_host_acknowledged_own_selection")
	check(batch_sent and not batch_observation.is_empty(), "batched_tap_sent_from_authoritative_grounded_neutral")
	check(not replica_rows.is_empty(), "guest_real_BattleScene_presentation_loaded")
	check(replica_rows.all(func(row):return row.models and row.no_local_authority), "guest_models_loaded_without_second_combat_simulation")
	check(replica_rows.all(func(row):return row.damage_matches and row.shield_matches), "guest_HUD_uses_exact_authoritative_damage_and_shield")
	check(replica_rows.any(func(row):return row.clips[0] != "" and row.clips[1] != ""), "guest_animation_players_select_runtime_clips")
	check(replica_contacts > 0, "confirmed_host_contact_cues_presented_once_on_guest")
	check(int(root.get_node("GameState").career_matches) == guest_career and before_campaign == JSON.stringify(root.get_node("CampaignRuntime").progress), "guest_replica_cannot_award_career_or_Story_progress")
	check(not guest_samples.is_empty(), "authoritative_state_mirror_received")
	check(guest_samples.any(func(s): return s.actors[0].fighter == "kaia-windrow" and s.actors[1].fighter == "juno-spark" and s.actors[0].body == "female" and s.actors[1].body == "male"), "exact_fighter_body_identity_mirrored")
	check(guest_samples.any(func(s): return float(s.actors[0].damage) > 0), "real_host_damage_observed_by_guest")

func finish() -> void:
	keys([])
	var result = {"PASS":failures.is_empty(), "role":side, "pid":OS.get_process_id(), "checks":checks, "failures":failures,
		"replica_rows":replica_rows, "replica_contacts":replica_contacts, "contacts":contacts, "move_starts":move_starts, "guards":guard_events, "grabs":grab_events, "guest_samples":guest_samples, "batch_observation":batch_observation,
		"received_inputs":lan.received_inputs if lan != null else 0, "rejected_inputs":lan.rejected_inputs if lan != null else 0,
		"scope":"Two actual localhost ENet Godot processes, guest public input into authoritative host BattleScene; host-state guest BattleScene presentation, not physical LAN, rollback, original art or human acceptance",
		"HUMAN_ART_APPROVED":false,"RC2_READY":false,"V1_0_0_RELEASE_AUTHORIZED":false}
	var file = FileAccess.open(output.path_join("LAN_" + side.to_upper() + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ")); file.close()
	if lan != null: lan.stop()
	print("LAN_ACTUAL_BATTLE ",side," ","PASS" if failures.is_empty() else "FAIL"," checks=",checks.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
