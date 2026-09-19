extends SceneTree

## VXP-2 visual evidence harness (desktop/headless fixture).
## Never claims physical Pixel or human validation.

const THEME_PATH := "res://assets/ui/themes/aa_vxp2_theme.tres"

const SURFACES := [
	{"id": "main_menu", "path": "res://scenes/menus/MainMenuScene.tscn"},
	{"id": "mode_select", "path": "res://scenes/menus/ModeSelectScene.tscn"},
	{"id": "fighter_select", "path": "res://scenes/menus/FighterSelectScene.tscn"},
	{"id": "stage_select", "path": "res://scenes/menus/StageSelectScene.tscn"},
	{"id": "results", "path": "res://scenes/ui/ResultsScene.tscn"},
]

const VIEWPORTS := [
	{"id": "desktop-1440x900", "size": Vector2i(1440, 900)},
	{"id": "laptop-1366x768", "size": Vector2i(1366, 768)},
	{"id": "handheld-landscape-960x540", "size": Vector2i(960, 540)},
]

var _manifest: Dictionary = {
	"program": "VXP-2",
	"capture_class": "desktop_headless_fixture",
	"physical_pixel": false,
	"human_validation": false,
	"shots": [],
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var project_root := ProjectSettings.globalize_path("res://")
	var after_dir := project_root.path_join("../artifacts/vxp2/after")
	var man_dir := project_root.path_join("../artifacts/vxp2/manifests")
	DirAccess.make_dir_recursive_absolute(after_dir)
	DirAccess.make_dir_recursive_absolute(man_dir)

	if not ResourceLoader.exists(THEME_PATH):
		push_error("VXP2 theme missing")
		quit(2)
		return

	var gs = root.get_node_or_null("/root/GameState")
	if gs:
		gs.p1_fighter_id = "ember-vale"
		gs.p2_fighter_id = "rook-ironside"
		gs.stage_id = "skyline-arena"
		gs.p2_is_cpu = true
		gs.last_winner_slot = 1
		gs.mode = "versus"

	for surface in SURFACES:
		for vp in VIEWPORTS:
			var ok := await _capture_one(str(surface.id), str(surface.path), vp, after_dir, {})
			_manifest["shots"].append({
				"surface": surface.id,
				"viewport": vp.id,
				"ok": ok,
				"file": "after_%s_%s.png" % [surface.id, vp.id],
			})

	# Accessibility variants (main menu desktop only)
	if gs:
		gs.high_contrast = true
	await _capture_one("main_menu", "res://scenes/menus/MainMenuScene.tscn", VIEWPORTS[0], after_dir, {"suffix": "high-contrast"})
	if gs:
		gs.high_contrast = false
	var role = root.get_node_or_null("/root/DeviceRoleRuntime")
	if role and role.has_method("set_reduce_motion"):
		role.set_reduce_motion(true)
	await _capture_one("main_menu", "res://scenes/menus/MainMenuScene.tscn", VIEWPORTS[0], after_dir, {"suffix": "reduce-motion"})
	if role and role.has_method("set_reduce_motion"):
		role.set_reduce_motion(false)

	var man_path := man_dir.path_join("VXP2_SCREENSHOT_MANIFEST.json")
	var f := FileAccess.open(man_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_manifest, "\t"))
		f.close()
	print("VXP2_CAPTURE_COMPLETE shots=%d" % int(_manifest["shots"].size()))
	quit(0)


func _capture_one(surface_id: String, path: String, vp: Dictionary, after_dir: String, opts: Dictionary) -> bool:
	DisplayServer.window_set_size(vp.size)
	root.size = vp.size
	if not ResourceLoader.exists(path):
		push_warning("Missing scene %s" % path)
		return false
	var packed := load(path) as PackedScene
	if packed == null:
		return false
	var scene := packed.instantiate()
	root.add_child(scene)
	for _i in 10:
		await process_frame
	var tex := root.get_texture()
	if tex == null:
		scene.queue_free()
		return false
	var img: Image = tex.get_image()
	if img == null:
		scene.queue_free()
		return false
	var suffix := str(opts.get("suffix", ""))
	var fname := "after_%s_%s.png" % [surface_id, vp.id]
	if not suffix.is_empty():
		fname = "after_%s_%s_%s.png" % [surface_id, vp.id, suffix]
	var out_path := after_dir.path_join(fname)
	var err := img.save_png(out_path)
	scene.queue_free()
	for _j in 2:
		await process_frame
	if not suffix.is_empty():
		_manifest["shots"].append({
			"surface": surface_id,
			"viewport": vp.id,
			"ok": err == OK,
			"file": fname,
			"variant": suffix,
		})
	print("captured %s err=%s" % [fname, err])
	return err == OK
