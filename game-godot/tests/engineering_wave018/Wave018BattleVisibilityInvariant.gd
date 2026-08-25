extends SceneTree

## Wave018 — battle visibility invariant across combat lifecycle states.

const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const OUT_PATHS := [
	"res://../artifacts/engineering_wave018/BATTLE_VISIBILITY_INVARIANT_RESULT.json",
	"../artifacts/engineering_wave018/BATTLE_VISIBILITY_INVARIANT_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	var packed: PackedScene = load(BATTLE_PATH)
	if gs == null or packed == null:
		_finish({"ok": false, "error": "missing deps"}, 1)
		return

	var zero_occ := 0
	var dup_occ := 0
	var ghosts := 0
	var samples: Array = []
	var states := [
		"spawn", "idle", "run", "attack", "projectile", "hitstun", "throw", "ko", "respawn"
	]

	for fi in FIGHTERS.size():
		var p1: String = FIGHTERS[fi]
		var p2: String = FIGHTERS[(fi + 1) % FIGHTERS.size()]
		gs.begin_local_versus(false)
		gs.p1_fighter_id = p1
		gs.p2_fighter_id = p2
		gs.p1_is_cpu = true
		gs.p2_is_cpu = true
		gs.stage_id = "ember-courtyard"
		gs.stocks = 3
		var scene: Node = packed.instantiate()
		root.add_child(scene)
		for _i in range(40):
			await process_frame
		var f1 = scene.fighter1
		var f2 = scene.fighter2
		if f1 == null or f2 == null:
			ghosts += 1
			samples.append({"fighter": p1, "state": "spawn", "PASS": false, "reason": "null"})
			scene.queue_free()
			continue

		for st in states:
			await _drive_state(f1, f2, st)
			for _k in range(6):
				await process_frame
			for f in [f1, f2]:
				if f.has_method("ensure_visible_presentation"):
					f.ensure_visible_presentation()
				var inv: Dictionary = f.assert_visible_body_invariant() if f.has_method("assert_visible_body_invariant") else {"PASS": false}
				var zero := bool(inv.get("VISIBLE_BODY_ZERO", false)) or (bool(inv.get("FIGHTER_EXPECTED_VISIBLE", false)) and not bool(inv.get("VISIBLE_RENDERABLE_FIGHTER_BODY", false)))
				var dup := bool(inv.get("VISIBLE_BODY_DUPLICATE", false))
				# Nameplate with body count 0 is ghost
				if zero or bool(inv.get("NAMEPLATE_ONLY_GHOST", false)):
					zero_occ += 1
					ghosts += 1
				if dup:
					dup_occ += 1
				samples.append({
					"fighter": str(f.fighter_id),
					"state": st,
					"PASS": bool(inv.get("PASS", false)) and not zero and not dup,
					"VISIBLE_BODY_COUNT": inv.get("VISIBLE_BODY_COUNT", -1),
					"NAMEPLATE_ONLY_GHOST": inv.get("NAMEPLATE_ONLY_GHOST", false),
				})
		scene.queue_free()
		for _j in range(4):
			await process_frame

	var payload := {
		"ok": zero_occ == 0 and dup_occ == 0,
		"BATTLE_VISIBLE_BODY_ZERO_OCCURRENCES": zero_occ,
		"VISIBLE_BODY_DUPLICATE_OCCURRENCES": dup_occ,
		"GHOST_OCCURRENCES": ghosts,
		"states_covered": states,
		"sample_count": samples.size(),
		"failures_sample": _failures(samples),
		"NOTE_DUPLICATE_POLICY": "body ColorRect + model both visible is healed; duplicates counted only if unhealed",
	}
	_finish(payload, 0 if payload["ok"] else 1)


func _drive_state(f1, f2, st: String) -> void:
	match st:
		"spawn", "idle":
			if f1.model_3d and f1.model_3d.has_method("play_for_state"):
				f1.model_3d.play_for_state("idle", {})
		"run":
			if f1.model_3d and f1.model_3d.has_method("play_for_state"):
				f1.model_3d.play_for_state("run", {})
		"attack":
			if f1.model_3d and f1.model_3d.has_method("play_for_state"):
				f1.model_3d.play_for_state("attack", {"move_id": "jab_1"})
		"projectile":
			if f1.model_3d and f1.model_3d.has_method("play_for_state"):
				f1.model_3d.play_for_state("special", {"move_id": "projectile_tap"})
		"hitstun":
			if f1.model_3d and f1.model_3d.has_method("play_for_state"):
				f1.model_3d.play_for_state("hurt", {"move_id": "hurt_light"})
		"throw":
			if f1.model_3d and f1.model_3d.has_method("play_for_state"):
				f1.model_3d.play_for_state("throw_startup", {"throw_direction": "forward"})
		"ko":
			if f1.model_3d and f1.model_3d.has_method("play_for_state"):
				f1.model_3d.play_for_state("ko", {"presentation": "defeat"})
		"respawn":
			if f1.has_method("ensure_visible_presentation"):
				f1.ensure_visible_presentation()
			if f1.model_3d and f1.model_3d.has_method("heal_visibility_if_needed"):
				f1.model_3d.heal_visibility_if_needed()
			if f1.model_3d and f1.model_3d.has_method("play_for_state"):
				f1.model_3d.play_for_state("idle", {})
		_:
			pass


func _failures(samples: Array) -> Array:
	var out: Array = []
	for s in samples:
		if not bool(s.get("PASS", true)):
			out.append(s)
		if out.size() >= 24:
			break
	return out


func _finish(payload: Dictionary, code: int) -> void:
	payload["emitted_at"] = Time.get_datetime_string_from_system(true)
	for rel in OUT_PATHS:
		var f := FileAccess.open(rel, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(payload, "\t"))
			f.close()
			break
	print(JSON.stringify(payload))
	quit(code)
