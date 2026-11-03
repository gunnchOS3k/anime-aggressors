extends RefCounted
## Shadow bridge from host-authoritative LAN input packets toward the isolated
## flat_combat_resim world. Converts LanControls packets, records late guest
## corrections, and can drive owned snapshot restore — WITHOUT mutating the
## shipping BattleSim / CharacterBody path. SHIPPING stays false until parity
## evidence exists.

const Controls = preload("res://scripts/net/lan_controls.gd")
const HumanSeats = preload("res://scripts/net/experimental/human_seat_policy.gd")
const Resim = preload("res://scripts/net/experimental/flat_combat_resim.gd")
const SHIPPING_BACKEND_ENABLED := false
const GUEST_SEAT := 1

var resim
var observed_packets: Array = []
var last_correction: Dictionary = {}
var failure := ""

func shipping_backend_enabled() -> bool:
	return SHIPPING_BACKEND_ENABLED or (resim != null and resim.shipping_backend_enabled())

func bind_resim(resim_node) -> bool:
	failure = ""
	if resim_node == null:
		failure = "resim_required"
		return false
	if shipping_backend_enabled() or resim_node.shipping_backend_enabled():
		failure = "shipping_backend_must_remain_disabled"
		return false
	resim = resim_node
	observed_packets.clear()
	last_correction = {}
	return true

static func trial_input_from_lan_packet(packet: Dictionary) -> Dictionary:
	## Public LanControls → isolated trial input. Extra LAN buttons (special,
	## grab, dodge, taunt) are intentionally ignored by the bounded jab trial.
	if not Controls.valid(packet):
		return {}
	var buttons: Dictionary = packet.buttons
	return {
		"axis": float(packet.axis),
		"attack": bool(buttons.get("attack", false)),
		"shield": bool(buttons.get("shield", false)),
		"jump": bool(buttons.get("jump", false)),
		"up": bool(buttons.get("up", false)),
		"down": bool(buttons.get("down", false)),
	}

static func lan_packet_from_trial_input(epoch: int, seq: int, trial_input: Dictionary) -> Dictionary:
	var buttons: Dictionary = {}
	for key in Controls.BUTTONS:
		buttons[key] = bool(trial_input.get(key, false)) if key in ["up", "down", "jump", "attack", "shield"] else false
	return {
		"kind": "input",
		"epoch": epoch,
		"seq": seq,
		"axis": float(trial_input.get("axis", 0.0)),
		"buttons": buttons,
	}

static func round_trip_ok(trial_input: Dictionary, epoch: int = 1, seq: int = 1) -> bool:
	var packet: Dictionary = lan_packet_from_trial_input(epoch, seq, trial_input)
	if not Controls.valid(packet):
		return false
	var back: Dictionary = trial_input_from_lan_packet(packet)
	return back == {
		"axis": float(trial_input.get("axis", 0.0)),
		"attack": bool(trial_input.get("attack", false)),
		"shield": bool(trial_input.get("shield", false)),
		"jump": bool(trial_input.get("jump", false)),
		"up": bool(trial_input.get("up", false)),
		"down": bool(trial_input.get("down", false)),
	}

func observe_guest_lan_packet(packet: Dictionary) -> bool:
	## Opt-in shadow observer for LanSession. Never applies damage or restores
	## shipping committed states (those remain rollback_restorable=false).
	if shipping_backend_enabled():
		failure = "shipping_backend_must_remain_disabled"
		return false
	if not Controls.valid(packet):
		failure = "invalid_lan_packet"
		return false
	observed_packets.append(packet.duplicate(true))
	while observed_packets.size() > 64:
		observed_packets.pop_front()
	return true

func correct_late_guest_packet(gameplay_frame: int, packet: Dictionary) -> Dictionary:
	last_correction = {}
	if resim == null:
		return _fail("bridge_not_bound")
	if shipping_backend_enabled():
		return _fail("shipping_backend_must_remain_disabled")
	var trial_input: Dictionary = trial_input_from_lan_packet(packet)
	if trial_input.is_empty():
		return _fail("invalid_lan_packet")
	var roster_ok: Dictionary = HumanSeats.validated_two_human_fighters(resim.seats if resim.seats.size() == 2 else [
		{"seat_id": 1, "role": "human", "fighter_id": "kaia-windrow", "peer_id": 1},
		{"seat_id": 2, "role": "human", "fighter_id": "juno-spark", "peer_id": 2},
	])
	if not bool(roster_ok.get("ok", false)) and resim.seats.size() != 2:
		return _fail("validated_2_human_fighting_seats_required")
	var result: Dictionary = resim.correct_remote_input(gameplay_frame, GUEST_SEAT, trial_input)
	last_correction = result.duplicate(true)
	last_correction["lan_packet_seq"] = int(packet.get("seq", -1))
	last_correction["lan_packet_epoch"] = int(packet.get("epoch", -1))
	last_correction["shipping_backend_enabled"] = shipping_backend_enabled()
	last_correction["shipping_committed_states_untouched"] = true
	return last_correction

func assert_shipping_lan_contract(lan_latest: Dictionary) -> Dictionary:
	## Host-authoritative LAN publishes rollback_restorable=false today. This
	## bridge must not claim otherwise while shipping remains disabled.
	var restorable: bool = bool(lan_latest.get("rollback_restorable", false))
	var ok: bool = not shipping_backend_enabled() and not restorable
	return {
		"ok": ok,
		"shipping_backend_enabled": shipping_backend_enabled(),
		"lan_rollback_restorable": restorable,
		"human_seats_only": true,
		"eight_player_authorized": false,
	}

static func self_test() -> Dictionary:
	var sample: Dictionary = {"axis": 0.5, "attack": true, "shield": false, "jump": false, "up": false, "down": false}
	var round_trip: bool = round_trip_ok(sample, 7, 3)
	var invalid: Dictionary = trial_input_from_lan_packet({"kind": "input"})
	var bridge = load("res://scripts/net/experimental/lan_resim_bridge.gd").new()
	var shipping_off: bool = not bridge.shipping_backend_enabled()
	var contract: Dictionary = bridge.assert_shipping_lan_contract({"rollback_restorable": false, "kind": "state"})
	var bad_contract: Dictionary = bridge.assert_shipping_lan_contract({"rollback_restorable": true, "kind": "state"})
	var ok: bool = round_trip and invalid.is_empty() and shipping_off and bool(contract.get("ok", false)) and not bool(bad_contract.get("ok", false))
	return {"ok": ok, "round_trip": round_trip, "shipping_off": shipping_off, "contract": contract}

func _fail(reason: String) -> Dictionary:
	failure = reason
	last_correction = {
		"ok": false,
		"rolled_back": false,
		"error": reason,
		"shipping_backend_enabled": shipping_backend_enabled(),
	}
	return last_correction
