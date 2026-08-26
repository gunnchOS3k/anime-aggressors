extends SceneTree

## Desktop capture pack for restored Fighter Select (no blank shell).

const SELECT_PATH := "res://scenes/menus/FighterSelectScene.tscn"
const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const GATES := preload("res://scripts/menus/wave020_presentation_gates.gd")
const OUT_DIR := "res://../artifacts/engineering_wave020/select_restore_captures"
const OUT_DIR_ALT := "../artifacts/engineering_wave020/select_restore_captures"
const MANIFEST_PATHS := [
	"res://../artifacts/engineering_wave020/FIGHTER_SELECT_RESTORE_CAPTURES.json",
	"../artifacts/engineering_wave020/FIGHTER_SELECT_RESTORE_CAPTURES.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	GATES.freeze_revised_presentation()
	var gs = root.get_node_or_null("/root/GameState")
	var roster: Array = gs.roster_ids()
	var packed: PackedScene = load(SELECT_PATH)
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var captures: Array = []
	captures.append(_snap(scene, "00_p1_p2_initial"))
	var names := ["ember", "rook", "juno", "kaia", "nix", "orion", "vesper"]
	for i in roster.size():
		scene.call("_on_tile_focused", i)
		await process_frame
		await process_frame
		await process_frame
		captures.append(_snap(scene, "%02d_%s_preview" % [i + 1, names[i] if i < names.size() else str(i)]))
	# fighter 7 after sequential browsing already captured as 07; reaffirm
	scene.call("_on_tile_focused", 6)
	await process_frame
	await process_frame
	captures.append(_snap(scene, "08_fighter7_after_sequential"))
	gs.p1_fighter_id = str(roster[6])
	gs.p2_fighter_id = str(roster[0])
	gs.begin_local_versus(false)
	gs.p1_is_cpu = true
	gs.p2_is_cpu = true
	gs.stage_id = "skyline-arena"
	var battle: Node = load(BATTLE_PATH).instantiate()
	root.add_child(battle)
	for _i in range(36):
		await process_frame
	captures.append(_snap(battle, "09_battle_after_fighter7_confirm"))
	var blank_shell := false
	for c in captures:
		if bool(c.get("likely_blank_shell", false)):
			blank_shell = true
	var payload := {
		"ok": not blank_shell and captures.size() >= 10,
		"blank_shell_detected": blank_shell,
		"captures": captures,
		"roster_count": roster.size(),
	}
	_write(payload)
	print("FIGHTER_SELECT_RESTORE_CAPTURES ok=", payload["ok"], " n=", captures.size())
	quit(0 if payload["ok"] else 1)


func _snap(node: Node, name: String) -> Dictionary:
	var vp := node.get_viewport()
	var img: Image = null
	if vp:
		img = vp.get_texture().get_image()
	var rel := "artifacts/engineering_wave020/select_restore_captures/%s.png" % name
	var saved := false
	var mean := 0.0
	if img:
		img.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUT_DIR, name]))
		saved = true
		var w := img.get_width()
		var h := img.get_height()
		var samples := 0
		var acc := 0.0
		for y in range(0, h, max(1, h / 32)):
			for x in range(0, w, max(1, w / 32)):
				var c := img.get_pixel(x, y)
				acc += (c.r + c.g + c.b) / 3.0
				samples += 1
		mean = acc / float(maxi(samples, 1))
	return {
		"name": name,
		"path": rel,
		"saved": saved,
		"mean_luma": mean,
		"likely_blank_shell": mean < 0.02,
	}


func _write(payload: Dictionary) -> void:
	payload["emitted_at"] = Time.get_datetime_string_from_system(true)
	for rel in MANIFEST_PATHS:
		var f := FileAccess.open(rel, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(payload, "\t") + "\n")
			f.close()
			return
