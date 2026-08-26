extends SceneTree

## Wave020 CP2 — Victory / Results canonical presentation for all 7 fighters.

const RESULTS_SCENE := "res://scenes/ui/ResultsScene.tscn"
const _AssetResolver := preload("res://scripts/visual/fighter_asset_resolver.gd")
const OUT_PATHS := [
	"res://../artifacts/engineering_wave020/VICTORY_PRESENTATION_DIAGNOSTIC_RESULT.json",
	"../artifacts/engineering_wave020/VICTORY_PRESENTATION_DIAGNOSTIC_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		_finish(false, {"error": "GameState missing"}, 1)
		return
	if gs.has_method("complete_tutorial"):
		gs.complete_tutorial()
	var roster: Array = gs.roster_ids()
	var canonical := 0
	var legacy := 0
	var wrong := 0
	var texture_ok := 0
	var details: Array = []
	for idv in roster:
		var fid := str(idv)
		gs.p1_fighter_id = fid
		gs.p2_fighter_id = "rook-ironside" if fid != "rook-ironside" else "ember-vale"
		gs.last_winner_slot = 1
		gs.mode = "versus"
		var packed: PackedScene = load(RESULTS_SCENE)
		if packed == null:
			wrong += 1
			details.append({"fighter": fid, "reason": "RESULTS_SCENE_MISSING"})
			continue
		var scene = packed.instantiate()
		root.add_child(scene)
		# Allow portrait bake frames.
		for _i in range(12):
			await process_frame
		var snap: Dictionary = {}
		if scene.has_method("victory_presentation_snapshot"):
			snap = scene.victory_presentation_snapshot()
		var presentation: Dictionary = _AssetResolver.resolve_presentation(fid, _AssetResolver.CTX_VICTORY)
		var is_canon := bool(presentation.get("is_current_canonical", false))
		var tex_present := bool(snap.get("portrait_texture_present", false))
		if scene.get("victory_portrait") != null and scene.victory_portrait.texture != null:
			tex_present = true
		if is_canon and str(snap.get("fighter_id", "")) == fid:
			canonical += 1
		else:
			wrong += 1
		if not is_canon:
			legacy += 1
		if tex_present:
			texture_ok += 1
		details.append({
			"fighter": fid,
			"is_canonical": is_canon,
			"texture_present": tex_present,
			"path": presentation.get("path", ""),
			"snap": snap,
		})
		scene.queue_free()
		await process_frame

	var tel: Dictionary = _AssetResolver.telemetry_snapshot()
	var ok := canonical == roster.size() and legacy == 0 and wrong == 0 and texture_ok == roster.size()
	var payload := {
		"ok": ok,
		"VICTORY_CANONICAL_CURRENT_COUNT": canonical,
		"VICTORY_LEGACY_REPRESENTATION_OCCURRENCES": legacy,
		"VICTORY_WRONG_FIGHTER_OCCURRENCES": wrong,
		"VICTORY_PORTRAIT_TEXTURE_COUNT": texture_ok,
		"roster_size": roster.size(),
		"details": details,
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
