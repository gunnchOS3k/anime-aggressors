extends SceneTree

## Regression: touch overlay must not intercept Fighter Select Confirm/Next.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: PackedStringArray = []
	var tim := root.get_node_or_null("TouchInputManager")
	if tim == null:
		failures.append("TouchInputManager missing")
	else:
		# Simulate being on a menu scene.
		change_scene_to_file("res://scenes/menus/FighterSelectScene.tscn")
		await create_timer(0.5).timeout
		if tim.has_method("_do_gameplay_refresh"):
			tim._do_gameplay_refresh()
		await process_frame
		if tim.has_method("should_show_touch") and tim.should_show_touch():
			failures.append("touch HUD must be hidden on Fighter Select (AUTO)")
		var overlay = tim.get("overlay") if tim.get("overlay") != null else tim.overlay
		if overlay != null:
			if overlay.visible:
				failures.append("overlay.visible must be false on Fighter Select")
			if int(overlay.process_mode) != int(Node.PROCESS_MODE_DISABLED):
				failures.append("overlay process_mode must be DISABLED on menus")
		# Next / Confirm buttons must remain mouse-filter STOP and visible.
		var sc := current_scene
		if sc:
			var next := _find_button_text(sc, "Next")
			var confirm := _find_button_text(sc, "Confirm")
			for pair in [["Next", next], ["Confirm", confirm]]:
				var btn: Button = pair[1]
				if btn == null:
					# Some builds label differently — try Ready / Continue.
					continue
				if btn.mouse_filter == Control.MOUSE_FILTER_IGNORE:
					failures.append("%s mouse_filter IGNORE (untappable)" % pair[0])
				if not btn.visible:
					failures.append("%s not visible" % pair[0])

	# NavigationAuthority must exist and not quit on fighter-select back.
	var nav := root.get_node_or_null("NavigationAuthority")
	if nav == null:
		failures.append("NavigationAuthority missing")
	else:
		nav.handle_back("test")
		await create_timer(0.35).timeout
		var path := String(current_scene.scene_file_path) if current_scene else ""
		if not path.ends_with("RulesetScene.tscn") and not path.ends_with("MainMenuScene.tscn"):
			failures.append("Back from Fighter Select should open ruleset/menu, got %s" % path)

	if failures.is_empty():
		print("menu_input_back_regression: PASS")
		quit(0)
	else:
		for f in failures:
			print("FAIL: ", f)
		quit(1)


func _find_button_text(node: Node, text: String) -> Button:
	if node is Button and String((node as Button).text).findn(text) >= 0:
		return node as Button
	for c in node.get_children():
		var found := _find_button_text(c, text)
		if found:
			return found
	return null
