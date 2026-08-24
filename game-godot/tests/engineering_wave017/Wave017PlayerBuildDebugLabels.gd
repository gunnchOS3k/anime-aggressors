extends SceneTree

## Wave017 — player build must not show proxy/debug labels.

const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const OUT_PATH := "res://../artifacts/wave017/PLAYER_BUILD_DEBUG_LABELS.json"
const FORBIDDEN := [
	"PROCEDURAL PRODUCTION PROXY",
	"PROXY — NOT FINAL ART",
	"STYLIZED FALLBACK",
	"MODEL_PENDING",
	"PLACEHOLDER",
	"DEBUG",
]


func _init() -> void:
	call_deferred("_run")


func _init_wait() -> void:
	pass


func _run() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		_done(false, ["GameState missing"], 0)
		return
	# Ensure competitive (non-training) so debug HUD stays off.
	gs.begin_local_versus(false)
	gs.p1_fighter_id = "ember-vale"
	gs.p2_fighter_id = "rook-ironside"
	gs.p1_is_cpu = true
	gs.p2_is_cpu = true
	gs.stage_id = "ember-courtyard"
	if "debug_combat_hud" in gs:
		gs.debug_combat_hud = false
	if "mode" in gs:
		gs.mode = "versus"

	var packed: PackedScene = load(BATTLE_PATH)
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	for _i in range(45):
		await process_frame

	var hits: Array = []
	_scan(scene, hits)
	# Also scan fighter model tier labels explicitly
	for f in [scene.fighter1, scene.fighter2]:
		if f == null:
			continue
		if f.model_3d:
			var tier = f.model_3d.get_node_or_null("ModelTierLabel")
			if tier and tier.visible:
				hits.append({"path": str(tier.get_path()), "text": str(tier.text), "reason": "ModelTierLabel visible"})
		if f.animator:
			# proxy label child
			for c in f.animator.get_children():
				if c is Label and c.visible:
					var txt: String = str(c.text).to_upper()
					for bad in FORBIDDEN:
						if bad.to_upper() in txt or (bad == "PROXY" and "PROXY" in txt):
							hits.append({"path": str(c.get_path()), "text": str(c.text)})

	var count := hits.size()
	_done(count == 0, hits, count)


func _scan(node: Node, hits: Array) -> void:
	if node is Label:
		var lab := node as Label
		if lab.visible:
			var txt: String = str(lab.text).to_upper()
			for bad in FORBIDDEN:
				var b: String = str(bad).to_upper()
				if b == "DEBUG":
					# Avoid matching unrelated words; require standalone debug markers
					if txt == "DEBUG" or txt.begins_with("DEBUG ") or " DEBUG" in txt:
						hits.append({"path": str(lab.get_path()), "text": lab.text})
				elif b in txt:
					hits.append({"path": str(lab.get_path()), "text": lab.text})
	for c in node.get_children():
		_scan(c, hits)


func _done(ok: bool, hits: Array, count: int) -> void:
	var payload := {
		"PLAYER_BUILD_VISIBLE_DEBUG_LABELS": count,
		"PASS": ok,
		"hits": hits,
	}
	var path := ProjectSettings.globalize_path(OUT_PATH)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
	print("PLAYER_BUILD_VISIBLE_DEBUG_LABELS=", count)
	quit(0 if ok else 1)
