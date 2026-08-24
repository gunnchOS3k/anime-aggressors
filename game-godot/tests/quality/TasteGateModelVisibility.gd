extends SceneTree

## Taste Gate — model visibility reliability harness.
## NAMEPLATE_VISIBLE_AND_MODEL_MISSING = failure.
## Desktop BattleScene only. Pixel evidence must come from physical campaign.

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	var reasons: Array[String] = []
	var fighters_out: Dictionary = {}
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		_finish(false, ["GameState missing"], {})
		return

	var packed: PackedScene = load(BATTLE_PATH)
	if packed == null:
		_finish(false, ["BattleScene missing"], {})
		return

	for fighter_id in FIGHTERS:
		gs.begin_local_versus(false)
		gs.p1_fighter_id = fighter_id
		gs.p2_fighter_id = "ember-vale" if fighter_id != "ember-vale" else "rook-ironside"
		gs.p1_is_cpu = true
		gs.p2_is_cpu = true
		gs.battle_eval_mode = false
		var scene: Node = packed.instantiate()
		root.add_child(scene)
		for _i in range(24):
			await process_frame

		var fighter = scene.fighter1 if scene != null else null
		var entry := {
			"fighter_id": fighter_id,
			"nameplate_visible": false,
			"model_loaded": false,
			"procedural_proxy_visible": false,
			"body_colorrect_visible": false,
			"NAMEPLATE_VISIBLE_AND_MODEL_MISSING": false,
			"pass": false,
		}
		if fighter == null:
			ok = false
			reasons.append("%s:fighter_null" % fighter_id)
			fighters_out[fighter_id] = entry
			scene.queue_free()
			continue

		var label = fighter.get_node_or_null("NameLabel")
		var nameplate_visible: bool = label != null and label.visible
		var model_loaded: bool = fighter.has_method("is_model_loaded") and fighter.is_model_loaded()
		var model = fighter.model_3d if "model_3d" in fighter else null
		var proxy_visible := false
		if model != null and model.has_method("is_procedural_proxy_visible"):
			proxy_visible = model.is_procedural_proxy_visible()
		var body_visible := false
		if "body" in fighter and fighter.body != null:
			body_visible = fighter.body.visible

		var failure := nameplate_visible and not model_loaded
		entry["nameplate_visible"] = nameplate_visible
		entry["model_loaded"] = model_loaded
		entry["procedural_proxy_visible"] = proxy_visible
		entry["body_colorrect_visible"] = body_visible
		entry["NAMEPLATE_VISIBLE_AND_MODEL_MISSING"] = failure
		entry["pass"] = not failure and model_loaded
		if failure:
			ok = false
			reasons.append("%s:NAMEPLATE_VISIBLE_AND_MODEL_MISSING" % fighter_id)
		elif not model_loaded:
			ok = false
			reasons.append("%s:model_not_loaded" % fighter_id)
		fighters_out[fighter_id] = entry
		scene.queue_free()
		for _j in range(4):
			await process_frame

	_finish(ok, reasons, fighters_out)


func _finish(ok: bool, reasons: Array, fighters_out: Dictionary) -> void:
	var payload := {
		"ok": ok,
		"NAMEPLATE_VISIBLE_AND_MODEL_MISSING": "failure",
		"PIXEL_EVIDENCE_INCLUDED": false,
		"PIXEL_NOTE": "Harness is desktop BattleScene only; do not invent Pixel pass.",
		"reasons": reasons,
		"fighters": fighters_out,
		"HUMAN_Q5": false,
	}
	var written := false
	for rel in [
		"artifacts/taste_gate/MODEL_VISIBILITY_HARNESS.json",
		"../artifacts/taste_gate/MODEL_VISIBILITY_HARNESS.json",
	]:
		var f := FileAccess.open(rel, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(payload, "\t"))
			f.close()
			written = true
			break
	print(JSON.stringify(payload))
	if not written:
		push_warning("TasteGateModelVisibility: could not write harness JSON")
	quit(0 if ok else 1)
