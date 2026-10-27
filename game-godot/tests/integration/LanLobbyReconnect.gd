extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Two actual ENet processes. Human-duration lobby wait and replacement join,
## NOT recovery of a running match or an Internet invitation entitlement test.
var lan
var side := ""
var port := 27834
var received_lobbies: Array = []
var campaign_before := ""

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
		if arg.begins_with("--lan-role="): side = arg.trim_prefix("--lan-role=")
		if arg.begins_with("--lan-port="): port = int(arg.trim_prefix("--lan-port="))
	if output.is_empty() or side not in ["host", "guest"] or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Explicit isolated LAN lobby check required"); quit(2); return
	lan = root.get_node("LanSession")
	campaign_before = JSON.stringify(root.get_node("CampaignRuntime").progress)
	lan.changed.connect(func():
		if not lan.lobby_state.is_empty(): received_lobbies.append(lan.lobby_state.duplicate(true)))
	if side == "host": await host_run()
	else: await guest_run()
	check(campaign_before == JSON.stringify(root.get_node("CampaignRuntime").progress), "lobby_selection_never_writes_Story_unlocks")
	finish()

func host_run() -> void:
	var gs = root.get_node("GameState")
	gs.p1_fighter_id = "ember-vale"; gs.p1_body_variant = "male"
	gs.p2_fighter_id = "rook-ironside"; gs.p2_body_variant = "male"
	check(lan.host(port, "127.0.0.1") == OK, "actual_ENet_lobby_host")
	var ready = FileAccess.open(output.path_join("HOST_READY"), FileAccess.WRITE); ready.store_string("ready"); ready.close()
	for i in range(600):
		await physics_frame
		if lan.guest_pick_ready and gs.p2_fighter_id == "nix-calder" and lan._remote_pick_revision >= 2: break
	check(lan.guest_pick_ready and gs.p2_fighter_id == "nix-calder" and gs.p2_body_variant == "female", "first_guest_revision_two_selection_accepted")
	var first_lobby: String = lan._lobby_id
	var departed := false
	for i in range(1500):
		await physics_frame
		if lan.guest_id == 0: departed = true
		if departed and lan.guest_pick_ready: break
	check(departed and lan.guest_pick_ready, "real_disconnect_then_replacement_guest_accepted")
	check(lan._lobby_id != first_lobby and lan._remote_pick_revision == 1, "replacement_handshake_has_new_nonce_and_fresh_revision_ownership")
	check(gs.p2_fighter_id == "kaia-windrow" and gs.p2_body_variant == "female" and gs.p1_fighter_id == "ember-vale", "new_guest_owns_only_its_canonical_fighter_body")
	await frames(15)
	check(lan.rejected_inputs > 0 and gs.p2_fighter_id == "kaia-windrow", "old_lobby_selection_rejected_over_new_socket")
	check(lan._battle == null and not lan._bound_once, "lobby_checks_do_not_invent_match_or_results")

func guest_run() -> void:
	var gs = root.get_node("GameState")
	gs.p1_fighter_id = "juno-spark"; gs.p1_body_variant = "male"
	check(lan.join("127.0.0.1", port) == OK, "actual_first_ENet_guest")
	for i in range(600):
		await physics_frame
		if not lan._lobby_id.is_empty(): break
	check(lan.select_local_fighter("nix-calder", "female"), "own_public_lobby_selection_submitted")
	for i in range(120):
		await physics_frame
		if lan.lobby_state.get("revision", -1) >= 2: break
	check(lan.lobby_state.get("guest_ready", false) and lan.lobby_state.get("p2", {}).get("fighter", "") == "nix-calder", "host_acknowledges_actual_requested_selection")
	var first_lobby: String = lan._lobby_id
	var began := Time.get_ticks_msec()
	await frames(720) #12real seconds at --max-fps60, past old10s timeout.
	check(Time.get_ticks_msec() - began > 10000 and lan.peer != null and lan.peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and lan.latest.is_empty(), "connected_human_lobby_survives_without_BattleScene_snapshot_past_handshake_deadline")
	lan.stop(); await frames(30)
	gs.p1_fighter_id = "kaia-windrow"; gs.p1_body_variant = "female"
	check(lan.join("127.0.0.1", port) == OK, "actual_replacement_ENet_guest")
	for i in range(600):
		await physics_frame
		if lan.lobby_state.get("guest_ready", false): break
	check(lan._lobby_id != first_lobby and lan.lobby_state.get("revision", -1) == 1 and lan.lobby_state.get("p2", {}).get("fighter", "") == "kaia-windrow", "first_revision_of_new_connection_is_host_acknowledged")
	lan._send(1, {"kind":"selection", "lobby":first_lobby, "revision":1000, "fighter":"juno-spark", "body":"male"})
	await frames(12)
	check(lan.lobby_state.get("p2", {}).get("fighter", "") == "kaia-windrow", "stale_lobby_cannot_change_acknowledged_replacement_selection")

func finish() -> void:
	var result := {"PASS":failures.is_empty(), "role":side, "checks":checks, "failures":failures, "received_host_lobbies":received_lobbies,
		"scope":"Actual two-process ENet lobby wait beyond10s, peer replacement/revision reset, stale-handshake rejection and unchanged Story. NOT midmatch reconnect, authenticated invitations, physicalLAN, native visuals or combat rollback.",
		"HUMAN_ART_APPROVED":false, "RC2_READY":false, "V1_0_0_RELEASE_AUTHORIZED":false}
	var file = FileAccess.open(output.path_join("LAN_" + side.to_upper() + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ")); file.close()
	lan.stop()
	print("LAN_LOBBY ", side, " ", "PASS" if failures.is_empty() else "FAIL", " failures=", failures)
	quit(0 if failures.is_empty() else 1)
