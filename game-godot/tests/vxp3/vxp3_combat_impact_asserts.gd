extends SceneTree

## Headless VXP-3 impact stack asserts. No Pixel / human PASS claims.

const _Impact = preload("res://scripts/combat/impact_profile_resolver.gd")
const _Reaction = preload("res://scripts/combat/hit_reaction_resolver.gd")
const _Pose = preload("res://scripts/visual/animation_pose_contract.gd")
const _Juice = preload("res://scripts/juice/juice_event_bus.gd")
const _Training = preload("res://scripts/training/training_impact_debug.gd")
const _Cinematic = preload("res://scripts/combat/combat_cinematic_director.gd")
const _Charged = preload("res://scripts/visual/charged_animation_layer.gd")
const _Clash = preload("res://scripts/combat/aura_clash_director.gd")
const _Provenance = preload("res://scripts/visual/animation_provenance.gd")
const _Secondary = preload("res://scripts/visual/secondary_motion_layer.gd")

var _failures: Array = []


func _initialize() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	_failures.append(msg)
	push_error("VXP3_FAIL: " + msg)


func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail(msg)
	else:
		print("VXP3_OK: ", msg)


func _run() -> void:
	_ok(_Impact.schema_ok(), "impact profile schema")
	_ok(_Reaction.library_ok(), "hurt reaction library")
	var light: Dictionary = _Impact.resolve({"impact_profile": "light", "move_id": "jab_1"}, {})
	var heavy: Dictionary = _Impact.resolve({"impact_profile": "heavy", "move_id": "heavy_attack"}, {})
	_ok(str(light.get("tier")) == "light", "light tier")
	_ok(str(heavy.get("tier")) == "heavy", "heavy tier")
	_ok(int(light.get("attacker_hitstop_frames")) == int(light.get("defender_hitstop_frames")), "light hitstop sync")
	_ok(int(heavy.get("attacker_hitstop_frames")) == int(heavy.get("defender_hitstop_frames")), "heavy hitstop sync")
	_ok(int(light.get("hitstop_frames")) != int(heavy.get("hitstop_frames")), "nix/rook hit tier distinction")
	_ok(not bool(light.get("warranted_camera")), "light camera not warranted")
	_ok(bool(heavy.get("warranted_camera")), "heavy camera warranted")
	var ko: Dictionary = _Impact.resolve({"move_id": "heavy_attack"}, {"is_ko": true})
	_ok(str(ko.get("tier")) == "ko", "ko upgrade")
	var special: Dictionary = _Impact.resolve({"move_id": "special"}, {})
	_ok(str(special.get("tier")) != "special", "no generic special tier")
	_ok(str(special.get("silent_special_fallback")) == "false" or not bool(special.get("silent_special_fallback")), "no silent special flag")

	var move := {
		"move_id": "jab_1",
		"startup_frames": 4,
		"active_frames": 3,
		"choreography": {"contact_frame": 5, "contact_socket": "hand_l", "victim_reaction_family": "flinch"},
	}
	_ok(_Pose.contact_aligned(move), "contact pose inside hitbox")
	_ok(_Pose.contact_pose_clip(move, "light") != "special", "contact pose not special")

	var react: Dictionary = _Reaction.resolve(null, {"launch": Vector2(4, -2), "damage": 2.0, "element": "frost"}, move, {})
	_ok(str(react.get("family")) != "", "reaction family present")
	_ok(_Reaction.clip_for("nix-calder", "freeze_stiffness") == "hurt_freeze_stiffness", "nix freeze clip")
	_ok(_Reaction.clip_for("rook-ironside", "body_snap") == "hurt_body_snap", "rook snap clip")

	var bus := _Juice.new()
	root.add_child(bus)
	bus.set_accessibility(true, true, true)
	bus.emit_event("camera_shake", {"intensity": 8.0, "duration_s": 0.2})
	var last: Dictionary = bus.get_last_event()
	_ok(float(last.get("intensity", 9.0)) == 0.0, "a11y reduces shake")
	bus.emit_event("hit_spark", {"element": "frost"})
	_ok(bool(bus.get_last_event().get("suppressed", false)), "a11y reduces flash/spark")
	bus.emit_event("impact_class", {"class": "heavy", "hud_hidden": true})
	_ok(str(bus.get_last_impact_class().get("class")) == "heavy", "hud-hidden impact class")

	_ok(_Cinematic.should_direct("heavy", true), "cinematic hook heavy")
	_ok(not _Cinematic.should_direct("light", true), "cinematic hook skips light")
	_ok(not _Cinematic.should_direct("heavy", false), "cinematic respects a11y")
	_ok(_Charged.should_apply("nix-calder", {"choreography": {"charged_layer": "hold"}, "attacker_aura": 75.0}), "charged layer live")
	_ok(_Charged.band_for(100.0) == 100, "charge full band")
	_ok(_Charged.overlay_clip("idle", {}, 80.0, {"charged_idle": true}) == "charged_idle", "charged idle remap")
	_ok(_Training.controls_present_in("F11 freeze F12 step replay"), "training debug tokens")

	_ok(_Cinematic.CLASS_CLASH == "CLASH", "cinematic class CLASH")
	_ok(_Cinematic.class_for("ko") == _Cinematic.CLASS_KO, "cinematic class KO")
	_ok(_Cinematic.class_for("heavy", true) == _Cinematic.CLASS_CLASH, "clash overrides heavy")
	_ok(not _Clash.is_clashable({"move_id": "jab_1", "move_type": "jab"}), "jabs never clash")
	_ok(_Clash.is_clashable({"move_id": "aura_burst", "move_type": "aura"}), "aura clashes")
	var clash_dbg: Dictionary = _Clash.debug_force(
		{"move_id": "aura_burst", "move_type": "aura", "startup_frames": 8, "active_frames": 6, "choreography": {"clashable": true}},
		{"move_id": "super", "move_type": "super", "startup_frames": 14, "active_frames": 8, "choreography": {"clashable": true}},
		{"fighter_id": "ember-vale", "aura": 100.0},
		{"fighter_id": "rook-ironside", "aura": 40.0}
	)
	_ok(bool(clash_dbg.get("clash")), "debug clash fires")
	_ok(not bool(clash_dbg.get("mash_used")), "clash has no mash")
	_ok(_Provenance.automation_may_write(_Provenance.AUTHORED_WIP), "automation may write WIP")
	_ok(not _Provenance.automation_may_write(_Provenance.AUTHORED_APPROVED), "automation must not write APPROVED")
	_ok(_Secondary.provenance() == "PROCEDURAL_FALLBACK", "secondary is fallback")
	_ok(not _Secondary.should_apply(true), "secondary respects reduce-motion")
	var proof := "res://assets/characters/authored/ember-vale/pipeline_proof.glb"
	_ok(ResourceLoader.exists(proof) or FileAccess.file_exists(proof), "ember authored GLB exists")

	var payload := {
		"ok": _failures.is_empty(),
		"failures": _failures,
		"emitted_at": Time.get_datetime_string_from_system(true),
	}
	_write(payload)
	if _failures.is_empty():
		print("VXP3 combat impact asserts PASS")
		quit(0)
	else:
		print("VXP3 combat impact asserts FAIL")
		quit(1)


func _write(payload: Dictionary) -> void:
	var text := JSON.stringify(payload, "  ")
	for path in [
		"res://../artifacts/vxp3/reports/VXP3_GODOT_ASSERTS.json",
		"user://VXP3_GODOT_ASSERTS.json",
	]:
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_string(text)
			f.close()
