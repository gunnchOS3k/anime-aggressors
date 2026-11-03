extends SceneTree
## Convergence Unbound ruleset — unbalanced mythic; never ranked MMR.

const Unbound = preload("res://scripts/trials/unbound/unbound_ruleset.gd")
const Colossus = preload("res://scripts/trials/unbound/colossus_rig.gd")

var failures: Array = []
var checks := 0


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	await process_frame
	check(Unbound.all_presets().size() == 5, "five_presets")
	for pid in Unbound.all_presets():
		var rules := Unbound.preset(pid)
		check(str(rules.get("label", "")) == Unbound.LABEL, "label_" + pid)
		check(not bool(rules.get("feeds_ranked_mmr", true)), "no_mmr_" + pid)
		check(bool(rules.get("full_supers", false)), "supers_" + pid)
		check(float(rules.get("cooldown_mult", 1.0)) < 0.5, "min_cooldown_" + pid)
	var session := Unbound.create_session(21, Unbound.PRESET_COLOSSUS, true, 4)
	check(Unbound.never_feeds_ranked(session), "session_never_ranked")
	check(bool(session.get("everlasting_permitted", false)), "everlasting_with_consent")
	session = Unbound.advance_journey(session)
	session = Unbound.advance_journey(session)
	check(str(session.get("phase", "")) == "play", "journey_to_play")
	check((session.get("colossus_rigs", []) as Array).size() >= 2, "colossus_rigs_spawned")
	for rig in session.get("colossus_rigs", []):
		var v := Colossus.validate_engineering(rig)
		check(bool(v.get("ok", false)), "engineering_" + str(rig.get("rig_id", "")))
		check(not bool(rig.get("avatar_ko_is_true_rosamere_defeat", true)), "avatar_ko_not_true_defeat")
	var denied := Unbound.create_session(22, Unbound.PRESET_TOTAL, false, 2)
	check(not bool(denied.get("everlasting_permitted", true)), "everlasting_denied_without_consent")
	var kaiju := Unbound.preset(Unbound.PRESET_KAIJU)
	check(bool(kaiju.get("black_white_puppet_echoes", false)), "bw_echoes")
	check(not bool(kaiju.get("black_white_are_yin_yang_rosamere_puppets", true)), "bw_not_named_puppets")
	var prism_actors: Array = Unbound.controllable_actors_for(Unbound.PRESET_PRISMATIC)
	check(prism_actors.size() >= 5, "prismatic_actors")
	check(bool(prism_actors[0].get("controllable", false)), "prismatic_controllable")
	check(not bool(prism_actors[0].get("contaminates_versus", true)), "prismatic_no_versus")
	var puppet_actors: Array = Unbound.controllable_actors_for(Unbound.PRESET_KAIJU)
	check(puppet_actors.size() >= 2, "puppet_actors")
	var runtime: Dictionary = Unbound.runtime_modifiers(Unbound.PRESET_TOTAL)
	check(float(runtime.get("cooldown_mult", 1.0)) < 0.5, "runtime_cd")
	check(bool(runtime.get("full_supers", false)), "runtime_supers")
	check(bool(runtime.get("instant_resources", false)), "runtime_resources")
	check(int(runtime.get("respawn_frames", 0)) > 0, "runtime_respawn")
	check(not bool(runtime.get("contaminates_story", true)), "runtime_no_story")
	## Colossus live deepen — step_rigs + scale-aware overlap + avatar KO honesty.
	session = Unbound.simulate_play_frames(session, 60)
	check((session.get("colossus_rigs", []) as Array).size() >= 2, "colossus_after_sim")
	var stepped: Array = Colossus.step_rigs(session.get("colossus_rigs", []), 12, 21)
	check(stepped.size() >= 2, "colossus_step_rigs")
	var ov := Colossus.overlap_summary(stepped[0], Vector2(float(stepped[0].get("position", {}).get("x", 0)), float(stepped[0].get("position", {}).get("y", 0))))
	check(bool(ov.get("inside", false)), "colossus_overlap_center")
	check(bool(ov.get("not_simple_uniform_scale_hitbox", false)), "colossus_scale_aware")
	var cam := Colossus.camera_profile_for_battle(stepped[0])
	check(bool(cam.get("a11y_reduce_motion_respected", false)), "colossus_a11y_camera")
	print("UNBOUND_RULESET_CONTRACT ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
