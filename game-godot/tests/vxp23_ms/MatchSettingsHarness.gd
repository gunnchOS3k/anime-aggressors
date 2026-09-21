extends SceneTree
## VXP-2.3 Match Settings pixel progression harness.

var _failures: PackedStringArray = []
var _results: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_failures.append(msg)
		push_error("VXP23 FAIL: %s" % msg)
	else:
		print("VXP23 OK: %s" % msg)


func _run() -> void:
	print("=== VXP23 Match Settings Harness ===")
	_results["started_at"] = Time.get_datetime_string_from_system(true)
	await process_frame
	await process_frame
	await _test_match_settings()
	await _test_fighter_select_truthful_cta()
	_test_cpu_labels_source()
	var all_ok: bool = _failures.is_empty()
	_results["ok"] = all_ok
	_results["failures"] = Array(_failures)
	_results["failure_count"] = _failures.size()
	_results["finished_at"] = Time.get_datetime_string_from_system(true)
	_write(_results)
	print("VXP23_MATCH_SETTINGS_HARNESS ok=", all_ok, " failures=", _failures.size())
	quit(0 if all_ok else 1)


func _test_match_settings() -> void:
	var err := change_scene_to_file("res://scenes/menus/RulesetScene.tscn")
	_ok(err == OK, "ruleset scene loads")
	await process_frame
	await process_frame
	await process_frame
	var scene = current_scene
	_ok(scene != null, "ruleset current")
	if scene == null:
		return
	var cta: Dictionary = {}
	if scene.has_method("assert_match_settings_cta"):
		cta = scene.assert_match_settings_cta()
	_results["match_settings_cta"] = cta
	_ok(bool(cta.get("MATCH_SETTINGS_CTA_PRESENT", false)), "MATCH_SETTINGS_CTA_PRESENT")
	_ok(bool(cta.get("MATCH_SETTINGS_CTA_SAFE_AREA", false)), "MATCH_SETTINGS_CTA_SAFE_AREA")
	_ok(bool(cta.get("MATCH_SETTINGS_CTA_VISIBLE_WITH_ALL_DYNAMIC_ROWS", false)), "MATCH_SETTINGS_CTA_VISIBLE_WITH_ALL_DYNAMIC_ROWS")
	_ok(bool(cta.get("MATCH_SETTINGS_SCROLL_BODY_PRESENT", false)), "MATCH_SETTINGS_SCROLL_BODY_PRESENT")
	_ok(bool(cta.get("MATCH_SETTINGS_ALL_CONTROLS_REACHABLE", false)), "MATCH_SETTINGS_ALL_CONTROLS_REACHABLE")
	_ok(bool(cta.get("MATCH_SETTINGS_CTA_TRUTHFUL", false)), "MATCH_SETTINGS_CTA_TRUTHFUL")
	var short: Dictionary = {}
	if scene.has_method("assert_pixel_short_viewport"):
		short = scene.assert_pixel_short_viewport(720.0)
	_results["match_settings_short_viewport"] = short
	_ok(bool(short.get("MATCH_SETTINGS_PIXEL_SHORT_VIEWPORT_PASS", false)), "MATCH_SETTINGS_PIXEL_SHORT_VIEWPORT_PASS")

	# Exercise controls so labels/state mutate without crashing.
	for method_name in [
		"_on_stock_plus", "_on_stock_minus",
		"_on_cpu_plus", "_on_cpu_minus",
		"_on_timer_plus", "_on_timer_minus",
		"_on_toggle_p2", "_on_damage_plus", "_on_toggle_team",
		"_on_cycle_preset",
	]:
		if scene.has_method(method_name):
			scene.call(method_name)
			await process_frame
	if scene.has_method("cpu_tier_display_name"):
		var names: Array = []
		for lv in range(1, 6):
			names.append(scene.cpu_tier_display_name(lv))
		_results["cpu_display_names"] = names
		_ok(str(names[0]).contains("Novice"), "CPU Lv1 Novice")
		_ok(str(names[4]).contains("Master"), "CPU Lv5 Master")

	# Confirm routes to fighter_select (real confirm path).
	if scene.has_method("_on_confirm_pressed"):
		scene._on_confirm_pressed()
		await process_frame
		await process_frame
		var after = current_scene
		var routed := after != null and str(after.name).contains("FighterSelect")
		if not routed and after != null:
			# Fallback: path check via scene file if name differs.
			routed = after.get_script() != null and str(after.get_script().resource_path).contains("fighter_select")
		_ok(routed, "MATCH_SETTINGS_CONTINUE_ROUTES_TO_FIGHTER_SELECT")
		_results["continue_route"] = {
			"scene": str(after.name) if after else "",
			"script": str(after.get_script().resource_path) if after and after.get_script() else "",
			"routed": routed,
		}


func _test_fighter_select_truthful_cta() -> void:
	var err := change_scene_to_file("res://scenes/menus/FighterSelectScene.tscn")
	_ok(err == OK, "fighter select loads")
	await process_frame
	await process_frame
	var scene = current_scene
	if scene == null:
		_ok(false, "fighter select current")
		return
	if scene.has_method("_on_lock_in_pressed"):
		scene._on_lock_in_pressed()
		await process_frame
		scene._on_lock_in_pressed()
		await process_frame
	var cta: Dictionary = {}
	if scene.has_method("assert_start_match_cta"):
		cta = scene.assert_start_match_cta()
	_results["fighter_select_cta"] = cta
	var text := str(cta.get("FIGHTER_SELECT_CTA_TEXT", ""))
	_ok(text.contains("CONTINUE TO STAGE") or text.contains("CHOOSE STAGE"), "FIGHTER_SELECT_CTA_TEXT")
	_ok(bool(cta.get("FIGHTER_SELECT_CTA_TRUTHFUL", false)), "FIGHTER_SELECT_CTA_TRUTHFUL")
	_ok(not text.contains("START MATCH"), "no START MATCH while routing to stage")
	_ok(bool(cta.get("START_MATCH_IN_SAFE_AREA", false)), "fighter select CTA safe area")
	# Route check: handler goes to stage_select.
	var src := ""
	if scene.get_script():
		var path := str(scene.get_script().resource_path)
		if FileAccess.file_exists(path):
			var f := FileAccess.open(path, FileAccess.READ)
			if f:
				src = f.get_as_text()
	_ok(src.contains('SceneRouter.go("stage_select")'), "FIGHTER_SELECT_CTA_ROUTES_TO_STAGE_SELECT")
	_ok(not src.contains('start_match_btn.text = "START MATCH"'), "source no longer labels START MATCH")


func _test_cpu_labels_source() -> void:
	var cpu_src := FileAccess.get_file_as_string("res://scripts/fighters/cpu_controller.gd")
	var rules_src := FileAccess.get_file_as_string("res://scripts/menus/ruleset_scene.gd")
	_ok(cpu_src.contains('TIER_NAMES := ["", "novice", "standard", "skilled", "expert", "master"]'), "CpuController TIER_NAMES present")
	_ok(rules_src.contains("TIER_NAMES"), "ruleset uses TIER_NAMES source")
	_ok(rules_src.contains("CONTINUE TO FIGHTERS"), "ruleset CTA CONTINUE TO FIGHTERS")
	_ok(rules_src.contains('SceneRouter.go("fighter_select")'), "ruleset confirm → fighter_select")
	_ok(rules_src.contains("ScrollContainer") or FileAccess.file_exists("res://scenes/menus/RulesetScene.tscn"), "scroll body scene present")
	var tscn := FileAccess.get_file_as_string("res://scenes/menus/RulesetScene.tscn")
	_ok(tscn.contains("ScrollBody") or tscn.contains("ScrollContainer"), "RulesetScene has ScrollContainer")
	_ok(tscn.contains("ActionBar"), "RulesetScene has ActionBar outside scroll")
	_ok(tscn.contains("CONTINUE TO FIGHTERS"), "tscn CTA wording")


func _write(payload: Dictionary) -> void:
	var path := "res://../artifacts/vxp23/reports/MATCH_SETTINGS_HARNESS.json"
	# Prefer absolute-ish project parent write via user:// fallback then absolute.
	var out := ProjectSettings.globalize_path("res://").replace("game-godot/", "").replace("game-godot", "")
	if not out.ends_with("/"):
		out += "/"
	var dest := out + "artifacts/vxp23/reports/MATCH_SETTINGS_HARNESS.json"
	DirAccess.make_dir_recursive_absolute(out + "artifacts/vxp23/reports")
	var f := FileAccess.open(dest, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
		print("Wrote ", dest)
	else:
		push_error("Could not write harness json to %s" % dest)
		# Also try relative from cwd.
		var f2 := FileAccess.open("user://MATCH_SETTINGS_HARNESS.json", FileAccess.WRITE)
		if f2:
			f2.store_string(JSON.stringify(payload, "\t"))
			f2.close()
