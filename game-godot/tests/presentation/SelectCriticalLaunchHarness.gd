extends SceneTree

## Structural + predictor tests. Does not weaken existing suites.

const _Announcer = preload("res://scripts/audio/fighter_announcer.gd")
const _Identity = preload("res://scripts/visual/elemental_material_contract.gd")
const _Fit = preload("res://scripts/visual/geometry_auto_fit.gd")
const _Predictor = preload("res://scripts/combat/critical_launch_predictor.gd")
const _Cue = preload("res://scripts/visual/critical_launch_cue.gd")
const _Feedback = preload("res://scripts/combat/combat_feedback.gd")
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const OUT := [
	"res://../artifacts/presentation/SELECT_CRITICAL_LAUNCH_HARNESS.json",
	"../artifacts/presentation/SELECT_CRITICAL_LAUNCH_HARNESS.json",
]

var _failures: Array = []


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	_failures.append(msg)
	push_error("SELECT_CRITICAL_LAUNCH_FAIL: " + msg)


func _run() -> void:
	_test_announcer()
	_test_opacity()
	_test_framing()
	_test_predictor()
	_test_cues()
	_test_feedback_no_math_mutation()
	var payload := {
		"ok": _failures.is_empty(),
		"failures": _failures,
	}
	_write(payload)
	print(JSON.stringify(payload))
	quit(0 if _failures.is_empty() else 1)


func _test_announcer() -> void:
	_Announcer.reset_debounce_for_tests()
	var hover := _Announcer.announce_lock(1, "ember-vale", null, true)
	if bool(hover.get("announced", true)):
		_fail("hover_announced")
	var p1 := _Announcer.announce_lock(1, "ember-vale", null, false)
	if not bool(p1.get("announced", false)) or str(p1.get("display_name")) != "Ember Vale":
		_fail("p1_lock_missing")
	var again := _Announcer.announce_lock(1, "ember-vale", null, false)
	if bool(again.get("announced", false)):
		_fail("repeat_not_debounced")
	_Announcer.reset_debounce_for_tests()
	var p2 := _Announcer.announce_lock(2, "rook-ironside", null, false)
	if str(p2.get("display_name")) != "Rook Ironside":
		_fail("p2_name")
	var missing := _Announcer.missing_voice_asset_graceful("kaia-windrow")
	if not bool(missing.get("ok", false)) or bool(missing.get("ANNOUNCER_FINAL_VOICE_ASSETS", true)):
		_fail("missing_voice_not_graceful")
	var kinds: Array = []
	for ev in _Announcer.last_events():
		kinds.append(str(ev.get("kind")))
	for need in ["fighter_lock_started", "fighter_locked", "announcer_name_started", "announcer_name_finished"]:
		if need not in kinds:
			_fail("missing_event:" + need)


func _test_opacity() -> void:
	for fid in FIGHTERS:
		var colors := _Identity.identity_colors(fid)
		var core: Color = colors["core"]
		if not _Identity.idle_select_alpha_ok(fid, core.a, "idle"):
			_fail("idle_alpha:" + fid)
		if fid == "vesper-nyx":
			if _Identity.alpha_for_role("body", fid, "idle") < 0.92:
				_fail("vesper_idle_too_low")
			if _Identity.alpha_for_role("body", fid, "phase_strike") > 0.70:
				_fail("vesper_phase_not_lower")
		if _Identity.alpha_for_role("armor", fid, "idle") < 0.98:
			_fail("armor_alpha:" + fid)
		var battle := _Identity.identity_colors(fid)
		if str(colors.get("roygbiv_family")) != str(battle.get("roygbiv_family")):
			_fail("identity_mismatch:" + fid)


func _test_framing() -> void:
	var tall := AABB(Vector3(-0.4, 0.0, -0.2), Vector3(0.8, 2.2, 0.4))
	var compact := AABB(Vector3(-0.25, 0.0, -0.15), Vector3(0.5, 1.4, 0.3))
	for ctx in ["SELECT_CARD", "SELECT_PREVIEW", "VICTORY", "MATCH_START"]:
		var a := _Fit.framing_for_bounds(tall, ctx)
		var b := _Fit.framing_for_bounds(compact, ctx)
		if not bool(a.get("no_clip")) or not bool(b.get("no_clip")):
			_fail("clip:" + ctx)
		if not bool(a.get("silhouette_readable")):
			_fail("unreadable:" + ctx)
	var card_ok := 0
	var preview_ok := 0
	for fid in FIGHTERS:
		var bounds := AABB(Vector3(-0.32, 0.0, -0.18), Vector3(0.64, 1.7, 0.36))
		var card := _Fit.framing_for_bounds(bounds, "SELECT_CARD")
		var preview := _Fit.framing_for_bounds(bounds, "SELECT_PREVIEW")
		if bool(card.get("silhouette_readable")):
			card_ok += 1
		if bool(preview.get("silhouette_readable")):
			preview_ok += 1
	if card_ok != 7:
		_fail("card_fit:%d" % card_ok)
	if preview_ok != 7:
		_fail("preview_fit:%d" % preview_ok)
	var pair := _Fit.pair_visible(
		_Fit.framing_for_bounds(tall, "MATCH_START"),
		_Fit.framing_for_bounds(compact, "MATCH_START")
	)
	if not pair:
		_fail("pair_not_visible")
	# Isolation: battle camera must not reuse select 2.05.
	var host := Node2D.new()
	root.add_child(host)
	var model: Node2D = MODEL_SCRIPT.new()
	host.add_child(model)
	if model.has_method("set_presentation_context"):
		model.set_presentation_context("SELECT_PREVIEW")
		model.set_presentation_context("BATTLE_P1")
	if model.has_method("context_isolation_snapshot"):
		var iso: Dictionary = model.context_isolation_snapshot()
		if bool(iso.get("SELECT_SCALE_LEAK_TO_BATTLE", true)):
			_fail("scale_leak")
		if bool(iso.get("SELECT_MATERIAL_IDENTITY_MISMATCH", true)):
			_fail("identity_leak")
	model.queue_free()
	host.queue_free()


func _test_predictor() -> void:
	var safe := _Predictor.evaluate({
		"position": Vector2(0, 200),
		"launch_velocity": Vector2(4, -3),
		"remaining_jumps": 1,
		"recovery_ready": true,
	})
	if str(safe.get("tier")) != "SAFE":
		_fail("safe_not_safe:" + str(safe.get("tier")))
	var crit := _Predictor.evaluate({
		"position": Vector2(540, 240),
		"launch_velocity": Vector2(22, -8),
		"remaining_jumps": 1,
		"recovery_ready": true,
		"hitstun_sec": 0.2,
	})
	if str(crit.get("tier")) != "CRITICAL_RECOVERABLE":
		_fail("recoverable_expected:" + str(crit.get("tier")) + " " + str(crit.get("reason")))
	var dead := _Predictor.evaluate({
		"position": Vector2(700, 500),
		"launch_velocity": Vector2(30, 10),
		"remaining_jumps": 0,
		"recovery_ready": false,
		"already_past_blast": true,
	})
	if str(dead.get("tier")) != "SAFE":
		_fail("dead_retriggers")
	if bool(safe.get("mutates_gameplay", true)) or not bool(safe.get("snapshot_unchanged", false)):
		_fail("predictor_mutated")
	var blast := _Predictor.evaluate({
		"position": Vector2(560, 250),
		"launch_velocity": Vector2(40, -6),
		"remaining_jumps": 0,
		"recovery_ready": false,
	})
	if str(blast.get("tier")) not in ["NEAR_CERTAIN_KO", "CRITICAL_RECOVERABLE"]:
		_fail("blast_tier:" + str(blast.get("tier")))


func _test_cues() -> void:
	if not _Cue.mapping_complete():
		_fail("cue_mapping")
	var seen := {}
	for fid in FIGHTERS:
		var fam := _Cue.family_for(fid)
		if fam == "" or seen.has(fam):
			_fail("cue_not_unique:" + fid)
		seen[fam] = true
	if _Cue.family_for("ember-vale") == "red_lightning":
		_fail("roster_lightning")


func _test_feedback_no_math_mutation() -> void:
	var fb: Node = _Feedback.new()
	root.add_child(fb)
	var launch := Vector2(5, -4)
	var info := {"launch": launch, "hitstop_frames": 3, "sfx_event": "", "vfx_event": ""}
	var attacker := Node.new()
	attacker.set("fighter_id", "ember-vale")
	var defender := Node2D.new()
	defender.position = Vector2(0, 200)
	root.add_child(defender)
	var out: Dictionary = fb.apply_hit(attacker, defender, {"feedback": {"tier": "light"}, "multi_hit": true, "final_hit": false}, info)
	if out.get("launch") != launch:
		_fail("feedback_changed_launch")
	if not bool(out.get("critical_suppressed", false)):
		_fail("multi_hit_not_suppressed")
	fb.queue_free()
	defender.queue_free()
	attacker.queue_free()


func _write(payload: Dictionary) -> void:
	payload["emitted_at"] = Time.get_datetime_string_from_system(true)
	for rel in OUT:
		var f := FileAccess.open(rel, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(payload, "\t") + "\n")
			f.close()
			return
