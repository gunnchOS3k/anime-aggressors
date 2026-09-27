extends SceneTree

const _Harness = preload("res://scripts/combat/move_execution_harness.gd")
const _Catalog = preload("res://scripts/combat/move_content_catalog.gd")
const _AnimStates = preload("res://scripts/fighters/fighter_states.gd")

const OUT := "res://../artifacts/combat/v3/MOVE_EXECUTION_HARNESS.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var manifest := _Catalog.audit_manifests()
	var harness: Dictionary = _Harness.run()
	var non_move := _non_move_coverage()
	var payload := {
		"REQUIRED_MOVE_TOTAL": 161,
		"MOVE_MANIFEST_PASS": "%d/161" % int(manifest.get("present", 0)),
		"MOVE_EXECUTION_PASS": harness.get("MOVE_EXECUTION_PASS"),
		"MOVE_ANIMATION_PASS": harness.get("MOVE_ANIMATION_PASS"),
		"MOVE_VFX_PASS": harness.get("MOVE_VFX_PASS"),
		"MOVE_PARTICLE_PASS": harness.get("MOVE_PARTICLE_PASS"),
		"MOVE_SFX_PASS": harness.get("MOVE_SFX_PASS"),
		"DIRECTIONAL_THROW_CONTENT": harness.get("DIRECTIONAL_THROW_CONTENT"),
		"NON_MOVE_ANIMATION_STATE_COVERAGE": non_move.get("coverage"),
		"OWNER_MOVESET_COMPLETENESS_PASS": false,
		"OWNER_ANIMATION_QUALITY_PASS": false,
		"OWNER_VFX_QUALITY_PASS": false,
		"OWNER_AUDIO_QUALITY_PASS": false,
		"OWNER_COMBAT_FEEL_PASS": false,
		"HUMAN_ORIGINALITY_REVIEW_PASS": false,
		"MERGE_AUTHORIZED": false,
		"manifest": manifest,
		"harness_failures": harness.get("failures", []),
		"non_move": non_move,
		"CURSOR_MERGED_NOTHING": true,
	}
	var abs_out := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(abs_out.get_base_dir())
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
	var ok: bool = bool(manifest.get("pass", false)) and bool(harness.get("execution_ok", false))
	print("V3_HARNESS %s %s" % ["PASS" if ok else "PARTIAL", JSON.stringify({
		"exec": harness.get("MOVE_EXECUTION_PASS"),
		"anim": harness.get("MOVE_ANIMATION_PASS"),
		"vfx": harness.get("MOVE_VFX_PASS"),
		"part": harness.get("MOVE_PARTICLE_PASS"),
		"sfx": harness.get("MOVE_SFX_PASS"),
		"throws": harness.get("DIRECTIONAL_THROW_CONTENT"),
	})])
	quit(0 if ok else 1)


func _non_move_coverage() -> Dictionary:
	var required := [
		"idle", "idle_variant", "walk", "run", "turn", "jump_start", "jump_rise", "jump_apex",
		"fall", "land", "crouch", "shield_start", "shield_hold", "shield_release",
		"dodge_forward", "dodge_back", "air_dodge", "grab_hold", "grab_break",
		"hurt_light", "hurt_medium", "hurt_heavy", "launched", "tumble", "critical_launch",
		"ledge_grab", "ledge_hang", "ledge_getup", "ledge_jump", "ledge_drop",
		"ko", "respawn", "victory", "defeat", "aura_charge", "aura_level_1", "aura_level_2",
		"aura_level_3", "aura_ready", "aura_burst",
	]
	var covered := 0
	var missing: Array = []
	for fid in _Catalog.FIGHTERS:
		var loaded := _Harness._list_clips(fid)
		var fighter_ok := true
		for state in required:
			if not loaded.has(state):
				fighter_ok = false
				missing.append("%s:%s" % [fid, state])
		if fighter_ok:
			covered += 1
	return {
		"coverage": "%d/7" % covered,
		"missing": missing,
		"states_checked": _AnimStates.all_states().size(),
	}
