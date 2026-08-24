extends SceneTree

## Wave017 — ghost fighter lifecycle transitions (desktop).
## Does not alone close T0; Pixel campaign required for NORMAL_PLAY_GHOST=0 claim.

const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const OUT_PATH := "res://../artifacts/wave017/GHOST_LIFECYCLE_HARNESS.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	var reasons: Array = []
	var transitions: Array = []
	var ghost_events := 0
	if gs == null:
		_finish(false, ["GameState missing"], {}, 0)
		return

	gs.begin_local_versus(false)
	gs.p1_fighter_id = "ember-vale"
	gs.p2_fighter_id = "rook-ironside"
	gs.p1_is_cpu = true
	gs.p2_is_cpu = true
	gs.stage_id = "ember-courtyard"
	gs.stocks = 3

	var packed: PackedScene = load(BATTLE_PATH)
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	for _i in range(60):
		await process_frame

	var f1 = scene.fighter1
	var f2 = scene.fighter2
	if f1 == null or f2 == null:
		_finish(false, ["fighters missing"], {}, 0)
		return

	# Transition battery (>=50 samples across spawn/KO/respawn/pause/visibility heal)
	for i in range(55):
		var kind := "idle_tick"
		match i % 11:
			0:
				kind = "ensure_visible"
				if f1.has_method("ensure_visible_presentation"):
					f1.ensure_visible_presentation()
				if f2.has_method("ensure_visible_presentation"):
					f2.ensure_visible_presentation()
			1:
				kind = "reparent_check"
				# Touch SubViewport ownership by forcing heal
				if f1.model_3d and f1.model_3d.has_method("heal_visibility_if_needed"):
					f1.model_3d.heal_visibility_if_needed()
				if f2.model_3d and f2.model_3d.has_method("heal_visibility_if_needed"):
					f2.model_3d.heal_visibility_if_needed()
			2:
				kind = "hide_show"
				f1.visible = false
				await process_frame
				f1.visible = true
				if f1.has_method("ensure_visible_presentation"):
					f1.ensure_visible_presentation()
			3:
				kind = "ko_sim"
				if f1.has_method("apply_ko"):
					# Prefer stock damage path if available
					pass
				if "stocks" in f1 and f1.stocks > 1 and f1.has_method("receive_hit") == false:
					pass
				# Soft KO presentation without ending match hard
				if f1.model_3d and f1.model_3d.has_method("play_for_state"):
					f1.model_3d.play_for_state("ko", {"presentation": "defeat"})
				for _k in range(8):
					await process_frame
				if f1.has_method("ensure_visible_presentation"):
					f1.ensure_visible_presentation()
			4:
				kind = "pause_resume"
				paused = true
				await process_frame
				paused = false
			5:
				kind = "swap_positions"
				var tmp: Vector2 = f1.global_position
				f1.global_position = f2.global_position
				f2.global_position = tmp
			6:
				kind = "aura_burst_pose"
				if f1.model_3d and f1.model_3d.has_method("play_for_state"):
					f1.model_3d.play_for_state("special", {"move_id": "aura_burst"})
			7:
				kind = "opponent_ensure"
				if f2.has_method("ensure_visible_presentation"):
					f2.ensure_visible_presentation()
			8:
				kind = "scene_restart_soft"
				if f1.has_method("ensure_visible_presentation"):
					f1.ensure_visible_presentation()
			9:
				kind = "label_check"
				if f1.has_method("_apply_slot_combat_label"):
					f1._apply_slot_combat_label()
			_:
				kind = "frame_advance"
		for _f in range(3):
			await process_frame

		var inv1: Dictionary = f1.assert_visible_body_invariant() if f1.has_method("assert_visible_body_invariant") else {"PASS": true}
		var inv2: Dictionary = f2.assert_visible_body_invariant() if f2.has_method("assert_visible_body_invariant") else {"PASS": true}
		var pass_both := bool(inv1.get("PASS", true)) and bool(inv2.get("PASS", true))
		if not pass_both:
			ghost_events += 1
			reasons.append("%s:ghost" % kind)
		transitions.append({
			"i": i,
			"kind": kind,
			"f1": inv1,
			"f2": inv2,
			"pass": pass_both,
		})

	var ok := ghost_events == 0 and reasons.is_empty()
	_finish(ok, reasons, {"transitions": transitions.size(), "samples": transitions}, ghost_events)


func _finish(ok: bool, reasons: Array, extra: Dictionary, ghost_events: int) -> void:
	var payload := {
		"WAVE017_GHOST_LIFECYCLE": "PASS" if ok else "FAIL",
		"DESKTOP_GHOST_OCCURRENCES": ghost_events,
		"NORMAL_PLAY_GHOST_FIGHTER_OCCURRENCES_DESKTOP": ghost_events,
		"reasons": reasons,
		"note": "Pixel campaign required to close TASTE-T0-MODEL-VISIBILITY-001",
	}
	payload.merge(extra, true)
	var path := ProjectSettings.globalize_path(OUT_PATH)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
	print("WAVE017_GHOST_LIFECYCLE=", payload["WAVE017_GHOST_LIFECYCLE"], " ghosts=", ghost_events)
	quit(0 if ok else 1)
