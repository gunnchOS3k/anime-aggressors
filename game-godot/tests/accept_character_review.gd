extends SceneTree

## Visible character review — SubViewport presenters only (own_world_3d).
## Do not pass --headless.
##
## Usage:
##   Godot --path game-godot -s res://tests/accept_character_review.gd

const OUT := "user://character_review"
const FIGHTER_MODEL := preload("res://scripts/fighters/fighter_model_3d.gd")

const FIGHTERS := [
	"ember-vale",
	"rook-ironside",
	"juno-spark",
	"kaia-windrow",
	"nix-calder",
	"orion-vell",
	"vesper-nyx",
]

const EXPRESSIONS := [
	"neutral",
	"focused",
	"confident",
	"surprised",
	"charging",
	"hurt",
	"victory",
	"defeat",
]

const YAWS := [
	{"name": "front", "yaw": -20.0},
	{"name": "side", "yaw": 70.0},
	{"name": "back", "yaw": 160.0},
	{"name": "three-quarter", "yaw": -45.0},
]


func _init() -> void:
	call_deferred("_run")


func _gs():
	return root.get_node_or_null("GameState")


func _log(msg: String) -> void:
	print("[character_review] %s" % msg)


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _ensure_out() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if img == null:
		_log("WARN shot failed %s" % name)
		return
	var err := img.save_png("%s/%s.png" % [OUT, name])
	_log("shot %s err=%s" % [name, str(err)])


func _run() -> void:
	_ensure_out()
	DisplayServer.window_set_title("Anime Aggressors — Character Review")
	get_root().size = Vector2i(1280, 720)

	var gs = _gs()
	if gs == null:
		_log("FAIL GameState missing")
		quit(1)
		return

	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.1, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)

	var title := Label.new()
	title.text = "Character Review Capture"
	title.position = Vector2(24, 16)
	title.add_theme_font_size_override("font_size", 28)
	host.add_child(title)

	var caption := Label.new()
	caption.position = Vector2(24, 680)
	caption.add_theme_font_size_override("font_size", 18)
	host.add_child(caption)

	# Roster row
	var slots: Array = []
	for i in FIGHTERS.size():
		var fid: String = FIGHTERS[i]
		var presenter := Node2D.new()
		presenter.set_script(FIGHTER_MODEL)
		presenter.position = Vector2(110 + i * 165, 360)
		presenter.scale = Vector2(1.55, 1.55)
		host.add_child(presenter)
		presenter.call("configure", gs.load_fighter(fid))
		presenter.call("set_select_mode", true)
		presenter.call("play_selection_focus")
		slots.append(presenter)
		await _wait(0.04)
	caption.text = "Roster — seven stylized fighters (faces + silhouettes)"
	await _wait(1.0)
	await _shot("00-roster-group")
	for p in slots:
		p.queue_free()
	await _wait(0.15)

	var stage := Node2D.new()
	stage.position = Vector2(640, 380)
	stage.scale = Vector2(3.2, 3.2)
	host.add_child(stage)

	var failed := 0
	for fid in FIGHTERS:
		var data: Dictionary = gs.load_fighter(fid)
		var display := str(data.get("displayName", fid))
		_log("capturing %s" % display)
		for c in stage.get_children():
			c.queue_free()
		await process_frame

		var presenter := Node2D.new()
		presenter.set_script(FIGHTER_MODEL)
		stage.add_child(presenter)
		if not bool(presenter.call("configure", data)):
			_log("FAIL configure %s" % fid)
			failed += 1
			continue
		presenter.call("set_select_mode", true)

		for yaw in YAWS:
			_set_model_yaw(presenter, float(yaw["yaw"]))
			caption.text = "%s — turnaround %s" % [display, str(yaw["name"])]
			await _wait(0.4)
			await _shot("%s-turnaround-%s" % [fid, str(yaw["name"])])

		_set_model_yaw(presenter, -20.0)
		presenter.call("play_selection_focus")
		caption.text = "%s — selection focus" % display
		await _wait(0.7)
		await _shot("%s-focus" % fid)

		presenter.call("play_lock_in")
		caption.text = "%s — lock-in" % display
		await _wait(0.7)
		await _shot("%s-lock-in" % fid)

		for expr in EXPRESSIONS:
			presenter.call("set_expression", expr)
			caption.text = "%s — expression %s" % [display, expr]
			await _wait(0.28)
			await _shot("%s-expression-%s" % [fid, expr])

		presenter.call("set_aura_level", 3)
		presenter.call("set_expression", "charging")
		caption.text = "%s — aura charge" % display
		await _wait(0.55)
		await _shot("%s-aura" % fid)

		presenter.call("play_victory_presentation")
		caption.text = "%s — victory" % display
		await _wait(0.85)
		await _shot("%s-victory" % fid)
		await _shot("%s-freeze" % fid)

		presenter.call("play_defeat_presentation")
		caption.text = "%s — defeat" % display
		await _wait(0.7)
		await _shot("%s-defeat" % fid)

		presenter.call("set_aura_level", 0)
		presenter.call("set_expression", "neutral")
		presenter.call("play_selection_focus")
		for frame_i in 6:
			caption.text = "%s — 3s review frame %d/6" % [display, frame_i + 1]
			await _wait(0.5)
			await _shot("%s-three-second-%02d" % [fid, frame_i + 1])

	for c in stage.get_children():
		c.queue_free()
	await process_frame
	stage.scale = Vector2(2.2, 2.2)
	var left := Node2D.new()
	left.set_script(FIGHTER_MODEL)
	left.position = Vector2(-180, 0)
	stage.add_child(left)
	left.call("configure", gs.load_fighter("ember-vale"))
	left.call("set_select_mode", true)
	left.call("set_facing", 1)
	left.call("play_lock_in")
	var right := Node2D.new()
	right.set_script(FIGHTER_MODEL)
	right.position = Vector2(180, 0)
	stage.add_child(right)
	right.call("configure", gs.load_fighter("nix-calder"))
	right.call("set_select_mode", true)
	right.call("set_facing", -1)
	right.call("play_lock_in")
	caption.text = "Faceoff — Ember Vale vs Nix Calder"
	await _wait(1.0)
	await _shot("99-faceoff-ember-nix")

	_log("DONE failed=%d out=%s" % [failed, ProjectSettings.globalize_path(OUT)])
	quit(0 if failed == 0 else 1)


func _set_model_yaw(presenter: Node, yaw_deg: float) -> void:
	var stylized = presenter.get("_stylized")
	if stylized is Node3D:
		(stylized as Node3D).rotation_degrees.y = yaw_deg
		return
	var loaded = presenter.get("_loaded_model")
	if loaded is Node3D:
		(loaded as Node3D).rotation_degrees.y = yaw_deg
