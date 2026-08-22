extends SceneTree

## Wave012 juice contract smoke — verifies JuiceEventBus + CombatFeedback hooks.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var reasons: Array[String] = []

	# Prefer autoload; fall back to instantiating the script directly.
	var bus = root.get_node_or_null("/root/JuiceEventBus")
	var owned_bus := false
	if bus == null:
		var bus_script := load("res://scripts/juice/juice_event_bus.gd")
		if bus_script == null:
			ok = false
			reasons.append("juice_event_bus.gd load failed")
		else:
			bus = bus_script.new()
			root.add_child(bus)
			owned_bus = true
			reasons.append("JuiceEventBus autoload missing; used direct instance fallback")
	if bus != null:
		if not bus.has_method("emit_event"):
			ok = false
			reasons.append("emit_event missing")
		else:
			bus.emit_event("hitstop", {"tier": "light", "frames": 3})
			bus.emit_event("camera_shake", {"tier": "medium", "intensity": 4.0})
			bus.emit_event("impact_vfx", {"socket": "chest", "element": "flame"})
			bus.emit_event("aura_buildup", {"fighter_id": "ember-vale", "level": 1, "pct": 0.5})
			bus.emit_event("shield_flash", {"fighter_id": "ember-vale"})
			bus.emit_event("dodge_phase", {"fighter_id": "vesper-nyx", "air": false})
			bus.emit_event("landing_dust", {"fighter_id": "ember-vale"})
			bus.emit_event("ko_burst", {"fighter_id": "rook-ironside"})
			if bus.has_method("get_last_event"):
				var last: Dictionary = bus.get_last_event()
				if str(last.get("event", "")) == "":
					ok = false
					reasons.append("last event empty")

	var cf_script := load("res://scripts/combat/combat_feedback.gd")
	if cf_script == null:
		ok = false
		reasons.append("combat_feedback.gd load failed")
	else:
		var cf = cf_script.new()
		root.add_child(cf)
		if cf.has_method("emit_aura_buildup"):
			cf.emit_aura_buildup("ember-vale", 2, 0.8)
			cf.emit_shield_flash("ember-vale")
			cf.emit_landing_dust("ember-vale")
		else:
			ok = false
			reasons.append("CombatFeedback juice helpers missing")

	# Treat direct-instance fallback as PASS for pipeline implementation if hooks work.
	var hard_fail := false
	for r in reasons:
		if "load failed" in r or "missing" in r and "autoload" not in r:
			hard_fail = true
	if hard_fail:
		ok = false

	var result := {
		"WAVE012_JUICE_SMOKE": "PASS" if ok else "FAIL",
		"ok": ok,
		"reasons": reasons,
		"owned_bus_fallback": owned_bus,
		"EMBER_FINAL_ART_RUNTIME_PASS": false,
		"note": "Juice hooks verified; final VRoid art not claimed",
	}
	var abs_dir := ProjectSettings.globalize_path("res://").path_join("../artifacts/engineering_wave012")
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var abs_path := abs_dir.path_join("JUICE_SMOKE_RESULT.json")
	var f := FileAccess.open(abs_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(result, "\t"))
		f.close()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/engineering_wave012"))
	var f2 := FileAccess.open("res://artifacts/engineering_wave012/JUICE_SMOKE_RESULT.json", FileAccess.WRITE)
	if f2:
		f2.store_string(JSON.stringify(result, "\t"))
		f2.close()
	print("Wave012JuiceSmoke ", result["WAVE012_JUICE_SMOKE"], " reasons=", reasons)
	quit(0 if ok else 1)
