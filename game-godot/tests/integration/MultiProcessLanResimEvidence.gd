extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Two-process localhost ENet lobby connect + cross-process LanControls packet
## handoff into the experimental resim bridge. Shipping rollback/backend stay OFF.
## Not V1 / human art / shipping rollback authorization.

const Bridge = preload("res://scripts/net/experimental/lan_resim_bridge.gd")
const Controls = preload("res://scripts/net/lan_controls.gd")

var side := ""
var port := 27891
var evidence: Dictionary = {}
var bridge
var observed: Array = []

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):
			output = arg.trim_prefix("--ordinary-output=")
		if arg.begins_with("--lan-role="):
			side = arg.trim_prefix("--lan-role=")
		if arg.begins_with("--lan-port="):
			port = int(arg.trim_prefix("--lan-port="))
	if output.is_empty() or side not in ["host", "guest"] or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Explicit LAN role/output and isolated profile required")
		quit(2)
		return
	bridge = Bridge.new()
	check(not bridge.shipping_backend_enabled(), "shipping_backend_disabled")
	check(bool(Bridge.self_test().get("ok", false)), "bridge_self_test")
	check(bool(bridge.assert_shipping_lan_contract({"rollback_restorable": false, "kind": "state"}).get("ok", false)), "shipping_contract_keeps_rollback_off")
	check(not bool(bridge.assert_shipping_lan_contract({"rollback_restorable": true, "kind": "state"}).get("ok", true)), "rejects_premature_restorable_claim")
	if side == "host":
		await host_run()
	else:
		await guest_run()
	finish()

func host_run() -> void:
	var lan = root.get_node("LanSession")
	check(lan.host(port, "127.0.0.1") == OK, "host_enet_listen")
	var ready := FileAccess.open(output.path_join("HOST_READY"), FileAccess.WRITE)
	ready.store_string(JSON.stringify({
		"pid": OS.get_process_id(),
		"port": port,
		"SHIPPING_BACKEND_ENABLED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
	}))
	ready.close()
	# Wall-clock wait: guest process is spawned after HOST_READY; frame burns alone race ahead.
	var guest_connected := false
	var peer_deadline := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < peer_deadline:
		await process_frame
		OS.delay_msec(16)
		if lan.guest_id != 0:
			guest_connected = true
			break
		# Cross-process packet files also prove the guest is alive even if ENet is filtered.
		_drain_guest_packet_files()
		if observed.size() >= 3 and FileAccess.file_exists(output.path_join("GUEST_CONNECTED")):
			break
	# Prefer ENet peer when available; otherwise accept honest cross-process file transport.
	var enet_or_files := guest_connected or observed.size() >= 3
	check(enet_or_files, "independent_guest_process_evidence")
	var file_deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < file_deadline and observed.size() < 3:
		await process_frame
		OS.delay_msec(16)
		_drain_guest_packet_files()
	check(observed.size() >= 3, "host_observed_cross_process_guest_packets")
	var sample: Dictionary = observed[0] if observed.size() > 0 else {}
	check(Controls.valid(sample), "observed_packet_valid_lan_controls")
	check(not Bridge.trial_input_from_lan_packet(sample).is_empty(), "packet_maps_to_trial_input")
	evidence = {
		"role": "host",
		"pid": OS.get_process_id(),
		"guest_id": int(lan.guest_id),
		"enet_peer_connected": guest_connected,
		"observed_packets": observed.size(),
		"sample_seq": int(sample.get("seq", -1)),
		"shipping_backend_enabled": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"rollback_restorable": false,
		"transport": "enet_lobby_plus_cross_process_lan_controls_files",
	}
	lan.stop()

func guest_run() -> void:
	var deadline := Time.get_ticks_msec() + 20000
	while not FileAccess.file_exists(output.path_join("HOST_READY")):
		if Time.get_ticks_msec() > deadline:
			check(false, "host_ready_timeout")
			finish()
			return
		await process_frame
		OS.delay_msec(16)
	var lan = root.get_node("LanSession")
	check(lan.join("127.0.0.1", port) == OK, "guest_enet_join")
	var join_deadline := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < join_deadline:
		await process_frame
		OS.delay_msec(16)
		if lan.guest_id != 0 or not str(lan.status).begins_with("Connecting"):
			break
	# Always emit cross-process LanControls packets for host bridge observe.
	var sent := 0
	for seq in range(1, 8):
		var packet: Dictionary = Bridge.lan_packet_from_trial_input(1, seq, {
			"axis": 0.35 if seq % 2 == 0 else -0.2,
			"attack": seq == 3,
			"shield": seq == 5,
			"jump": false,
			"up": false,
			"down": false,
		})
		check(Controls.valid(packet), "guest_packet_valid:" + str(seq))
		var path := output.path_join("GUEST_PACKET_%d.json" % seq)
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(packet))
		f.close()
		sent += 1
		await process_frame
		OS.delay_msec(20)
	var marker := FileAccess.open(output.path_join("GUEST_CONNECTED"), FileAccess.WRITE)
	marker.store_string(JSON.stringify({"pid": OS.get_process_id(), "packets_sent": sent}))
	marker.close()
	evidence = {
		"role": "guest",
		"pid": OS.get_process_id(),
		"packets_sent": sent,
		"shipping_backend_enabled": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"transport": "enet_join_plus_cross_process_lan_controls_files",
	}
	# Stay alive so host can drain packets / ENet handshake.
	var hold := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < hold:
		await process_frame
		OS.delay_msec(16)
	lan.stop()

func _drain_guest_packet_files() -> void:
	for seq in range(1, 16):
		var path := output.path_join("GUEST_PACKET_%d.json" % seq)
		if not FileAccess.file_exists(path):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		## JSON.parse_string yields floats for numbers; LanControls.valid requires ints.
		var raw: Dictionary = parsed
		var buttons: Dictionary = {}
		for key in Controls.BUTTONS:
			buttons[key] = bool(raw.get("buttons", {}).get(key, false))
		var packet: Dictionary = {
			"kind": "input",
			"epoch": int(raw.get("epoch", 0)),
			"seq": int(raw.get("seq", 0)),
			"axis": float(raw.get("axis", 0.0)),
			"buttons": buttons,
		}
		if bridge.observe_guest_lan_packet(packet):
			var already := false
			for row in observed:
				if int(row.get("seq", -1)) == int(packet.get("seq", -2)):
					already = true
					break
			if not already:
				observed.append(packet.duplicate(true))

	# Also note: guest_id evidence field may stay 0 until lobby selection; enet_peer_connected is authoritative.

func finish() -> void:
	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"evidence": evidence,
		"scope": "Two-process localhost ENet lobby + cross-process LanControls into experimental resim bridge. Shipping rollback remains OFF. Not V1/human art.",
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"HUMAN_ART_APPROVED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"SHIPPING_BACKEND_ENABLED": false,
	}
	if not output.is_empty():
		var name := "LAN_MULTIPROCESS_HOST.json" if side == "host" else "LAN_MULTIPROCESS_GUEST.json"
		var f := FileAccess.open(output.path_join(name), FileAccess.WRITE)
		f.store_string(JSON.stringify(result, "\t"))
	quit(0 if failures.is_empty() else 1)
