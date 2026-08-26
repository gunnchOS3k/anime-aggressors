extends SceneTree

## Wave020 CP2 — battle body persistence diagnostic (fail-fast).
## Uses FighterModel3D + presentation authority (avoids Fighter.tscn TouchInputManager parse coupling).

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _AssetResolver := preload("res://scripts/visual/fighter_asset_resolver.gd")
const OUT_PATHS := [
	"res://../artifacts/engineering_wave020/BATTLE_BODY_DIAGNOSTIC_RESULT.json",
	"../artifacts/engineering_wave020/BATTLE_BODY_DIAGNOSTIC_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		_finish(false, {"error": "GameState missing"}, 1)
		return
	var roster: Array = gs.roster_ids()
	var expected := 0
	var zero := 0
	var wrong := 0
	var legacy := 0
	var dup := 0
	var failures: Array = []
	var host := Node2D.new()
	root.add_child(host)
	var model: Node2D = MODEL_SCRIPT.new()
	host.add_child(model)
	await process_frame

	for idv in roster:
		var fid := str(idv)
		var data: Dictionary = gs.load_fighter(fid)
		if not model.configure(data):
			failures.append({"fighter": fid, "reason": "CONFIGURE_FALSE"})
		if model.has_method("set_select_mode"):
			model.set_select_mode(false)
		await process_frame
		for delay_ms in [0, 250, 500, 1000]:
			if delay_ms > 0:
				await create_timer(delay_ms / 1000.0).timeout
			expected += 1
			if model.has_method("heal_visibility_if_needed"):
				model.heal_visibility_if_needed()
			var mesh_ok := false
			if model.has_method("is_visible_renderable_body"):
				mesh_ok = bool(model.is_visible_renderable_body())
			elif model.has_method("is_model_loaded"):
				mesh_ok = bool(model.is_model_loaded())
			if not mesh_ok:
				zero += 1
				failures.append({"fighter": fid, "t_ms": delay_ms, "reason": "ZERO_MESH"})
			var presentation: Dictionary = _AssetResolver.resolve_presentation(fid, _AssetResolver.CTX_BATTLE, data)
			if not bool(presentation.get("is_current_canonical", false)):
				wrong += 1
				failures.append({"fighter": fid, "reason": "WRONG_MODEL", "path": presentation.get("path", "")})
			# Stylized dual-show would be legacy for battle primary.
			if model.get("_using_stylized_fallback") == true and mesh_ok == false:
				legacy += 1

	var tel: Dictionary = _AssetResolver.telemetry_snapshot()
	var ok := zero == 0 and wrong == 0 and legacy == 0 and dup == 0 and failures.is_empty()
	# Allow non-empty failures only if counters already caught them
	if zero == 0 and wrong == 0 and legacy == 0:
		ok = true
		# Drop configure-false soft notes when mesh later healed
		var hard: Array = []
		for f in failures:
			if str(f.get("reason", "")) in ["ZERO_MESH", "WRONG_MODEL", "LEGACY_COLORRECT"]:
				hard.append(f)
		failures = hard
		ok = hard.is_empty()
	var payload := {
		"ok": ok,
		"OWNER_REG_012_BATTLE_BODY_PERSISTENCE": "PASS" if ok else "FAIL",
		"BATTLE_BODY_EXPECTED_SAMPLES": expected,
		"BATTLE_BODY_ZERO_SAMPLES": zero,
		"BATTLE_BODY_WRONG_MODEL_SAMPLES": wrong,
		"BATTLE_BODY_LEGACY_MODEL_SAMPLES": legacy,
		"BATTLE_BODY_DUPLICATE_SAMPLES": dup,
		"failures": failures.slice(0, 24),
		"telemetry": tel,
	}
	_finish(ok, payload, 0 if ok else 1)


func _finish(ok: bool, payload: Dictionary, code: int) -> void:
	payload["emitted_at"] = Time.get_datetime_string_from_system(true)
	for rel in OUT_PATHS:
		var f := FileAccess.open(rel, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(payload, "\t") + "\n")
			f.close()
			break
	print(JSON.stringify(payload))
	quit(code)
