extends SceneTree

## Wave017 Golden Slice visual smoke — Ember + Rook on Ember Courtyard.

const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const OUT_PATH := "res://../artifacts/wave017/GOLDEN_SLICE_VISUAL_SMOKE.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		_done(false, ["GameState missing"])
		return
	gs.begin_local_versus(false)
	gs.p1_fighter_id = "ember-vale"
	gs.p2_fighter_id = "rook-ironside"
	gs.p1_is_cpu = true
	gs.p2_is_cpu = true
	gs.stage_id = "ember-courtyard"

	var packed: PackedScene = load(BATTLE_PATH)
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	for _i in range(90):
		await process_frame

	var reasons: Array = []
	var f1 = scene.fighter1
	var f2 = scene.fighter2
	if f1 == null or f2 == null:
		_done(false, ["fighters missing"])
		return

	if not f1.is_model_loaded():
		reasons.append("ember_model_not_loaded")
	if not f2.is_model_loaded():
		reasons.append("rook_model_not_loaded")

	var cam = scene.get_node_or_null("Camera2D")
	var bcc = scene.get_node_or_null("BattleCameraController")
	if cam == null:
		reasons.append("camera_missing")
	if bcc == null:
		reasons.append("battle_camera_controller_missing")

	var stage = scene.stage_root
	var golden_layers := 0
	if stage:
		for c in stage.get_children():
			if str(c.name).begins_with("Wave017GoldenSlice") or str(c.name).begins_with("Ember"):
				golden_layers += 1
	if golden_layers < 1:
		reasons.append("ember_courtyard_golden_layers_missing")

	# Name labels should be short tags
	for f in [f1, f2]:
		var lab = f.get_node_or_null("NameLabel")
		if lab and lab.visible:
			var txt: String = str(lab.text)
			if txt.length() > 4 and ("Ember" in txt or "Rook" in txt or "Vale" in txt):
				reasons.append("full_name_label_over_body:%s" % txt)

	# Separation zoom sample
	if f1 and f2 and bcc:
		f2.global_position = f1.global_position + Vector2(520, 0)
		for _i in range(30):
			await process_frame

	var ok := reasons.is_empty()
	var payload := {
		"GOLDEN_SLICE_VISUAL_SMOKE": "PASS" if ok else "FAIL",
		"ember_model_loaded": f1.is_model_loaded(),
		"opponent_model_loaded": f2.is_model_loaded(),
		"camera_controller": bcc != null,
		"golden_layers": golden_layers,
		"reasons": reasons,
		"HUMAN_Q3_APPROVAL": false,
		"HUMAN_ART_DIRECTION_APPROVAL": false,
	}
	_write(payload)
	print("GOLDEN_SLICE_VISUAL_SMOKE=", payload["GOLDEN_SLICE_VISUAL_SMOKE"])
	quit(0 if ok else 1)


func _done(ok: bool, reasons: Array) -> void:
	_write({"GOLDEN_SLICE_VISUAL_SMOKE": "FAIL" if not ok else "PASS", "reasons": reasons})
	quit(0 if ok else 1)


func _write(payload: Dictionary) -> void:
	var path := ProjectSettings.globalize_path(OUT_PATH)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
