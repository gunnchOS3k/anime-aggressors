extends SceneTree

## Structural visual regression assertions for VXP-2 (no Pixel claim).

var _failures: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _fail(msg: String) -> void:
	_failures.append(msg)
	push_error("VXP2_FAIL: " + msg)

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail(msg)
	else:
		print("VXP2_OK: ", msg)

func _run() -> void:
	_ok(ResourceLoader.exists("res://assets/ui/themes/aa_vxp2_theme.tres"), "vxp2 theme present")
	_ok(ResourceLoader.exists("res://assets/placeholder/aa_theme.tres"), "legacy theme preserved")
	_ok(ResourceLoader.exists("res://assets/branding/vxp2/aa_seal.png"), "seal present")
	_ok(ResourceLoader.exists("res://assets/branding/vxp2/aa_wordmark.png"), "wordmark present")
	_ok(ResourceLoader.exists("res://assets/branding/vxp2/BRAND_PROVENANCE.json"), "brand provenance present")
	_ok(ResourceLoader.exists("res://assets/branding/vxp2/glyphs/glyph_confirm.png"), "confirm glyph")
	_ok(ResourceLoader.exists("res://scripts/vxp2/vxp2_brand.gd"), "brand script")

	var menu := load("res://scenes/menus/MainMenuScene.tscn") as PackedScene
	_ok(menu != null, "main menu loads")
	if menu:
		var n := menu.instantiate()
		root.add_child(n)
		for _i in 6:
			await process_frame
		var fight := n.get_node_or_null("%Fight")
		_ok(fight != null, "FIGHT CTA present")
		if fight:
			_ok(str(fight.text).to_upper().contains("FIGHT"), "FIGHT label")
		var labs := n.find_child("Labs", true, false)
		_ok(labs != null, "Labs still reachable")
		if labs:
			_ok(str(labs.text).to_lower().contains("dev") or str(labs.text).to_lower().contains("lab"), "Labs demoted labeling")
		# Theme path
		_ok(n.theme != null, "main menu has theme")
		n.queue_free()
		await process_frame

	var select := load("res://scenes/menus/FighterSelectScene.tscn") as PackedScene
	_ok(select != null, "fighter select loads")
	if select:
		var s := select.instantiate()
		root.add_child(s)
		for _i in 12:
			await process_frame
		_ok(s.has_method("assert_preview_visibility_invariant"), "preview invariant preserved")
		if s.has_method("assert_preview_visibility_invariant"):
			var inv: Dictionary = s.call("assert_preview_visibility_invariant")
			_ok(inv.has("PASS"), "invariant returns PASS key")
		# No PROCEDURAL_FINAL in player detail if present
		var detail := s.get_node_or_null("%Detail") as Label
		if detail:
			_ok(not str(detail.text).contains("PROCEDURAL_FINAL"), "fighter detail free of PROCEDURAL_FINAL")
		s.queue_free()
		await process_frame

	var stage := load("res://scenes/menus/StageSelectScene.tscn") as PackedScene
	if stage:
		var st := stage.instantiate()
		root.add_child(st)
		for _i in 8:
			await process_frame
		var preview := st.get_node_or_null("%Preview") as Label
		if preview:
			_ok(not str(preview.text).contains("PROCEDURAL_FINAL"), "stage preview free of PROCEDURAL_FINAL")
			_ok(not str(preview.text).to_lower().begins_with("art:"), "stage preview not artStatus dump")
		st.queue_free()

	# Theme migration: key scenes should reference vxp2 theme
	var theme_scenes: Array[String] = [
		"scenes/menus/MainMenuScene.tscn",
		"scenes/menus/ModeSelectScene.tscn",
		"scenes/menus/FighterSelectScene.tscn",
		"scenes/ui/ResultsScene.tscn",
	]
	for rel in theme_scenes:
		var p: String = "res://" + rel
		var txt: String = FileAccess.get_file_as_string(p)
		_ok(txt.contains("aa_vxp2_theme.tres"), "%s uses vxp2 theme" % rel)

	if _failures.is_empty():
		print("VXP2_STRUCTURAL_PASS")
		quit(0)
	else:
		print("VXP2_STRUCTURAL_FAIL count=%d" % _failures.size())
		quit(1)
