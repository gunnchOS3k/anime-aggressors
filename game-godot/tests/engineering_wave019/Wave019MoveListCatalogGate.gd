extends SceneTree
## Wave019 desktop gate: move-list catalog accuracy + identity profile presence.

const Catalog = preload("res://scripts/ui/move_list_catalog.gd")
const Glyphs = preload("res://scripts/ui/input_glyph_presenter.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: PackedStringArray = PackedStringArray()
	var ids := Catalog.roster_ids()
	if ids.size() != 7:
		failures.append("roster_size")
	var playable_total := 0
	var false_playable := 0
	var lab_as_playable := 0
	for fid in ids:
		var cat: Dictionary = Catalog.build_fighter_catalog(fid)
		var beginner: Dictionary = cat.get("beginner", {})
		if str(beginner.get("playstyle", "")).is_empty():
			failures.append("%s_missing_beginner" % fid)
		for e in cat.get("entries", []):
			if bool(e.get("playable", false)):
				playable_total += 1
				var enriched: Dictionary = Glyphs.enrich_entry(e, Glyphs.DEVICE_KEYBOARD)
				if str(enriched.get("input_glyphs", {}).get("compact", "")).is_empty():
					failures.append("%s_%s_glyph" % [fid, str(e.get("move_id", ""))])
				if str(e.get("animation_clip", "")).is_empty():
					failures.append("%s_%s_clip" % [fid, str(e.get("move_id", ""))])
				if str(e.get("display_name", "")) == str(e.get("move_id", "")):
					failures.append("%s_%s_raw_id_name" % [fid, str(e.get("move_id", ""))])
			elif str(e.get("reachability", "")) == "LAB_ONLY":
				if bool(e.get("playable", false)):
					lab_as_playable += 1
					false_playable += 1
	if playable_total < 7 * 20:
		failures.append("playable_too_low_%d" % playable_total)
	if false_playable != 0:
		failures.append("false_playable_%d" % false_playable)
	if lab_as_playable != 0:
		failures.append("lab_as_playable_%d" % lab_as_playable)

	var out := {
		"WAVE019_MOVE_LIST_DESKTOP_GATE": "PASS" if failures.is_empty() else "FAIL",
		"playable_total": playable_total,
		"false_playable": false_playable,
		"lab_as_playable": lab_as_playable,
		"failures": failures,
	}
	var path := "res://../artifacts/engineering_wave019/MOVE_LIST_DESKTOP_GATE.json"
	# Prefer absolute via user:// fallback then project-relative open
	var f := FileAccess.open("user://WAVE019_MOVE_LIST_DESKTOP_GATE.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(out, "\t"))
		f.close()
	print("WAVE019_MOVE_LIST_DESKTOP_GATE=", out["WAVE019_MOVE_LIST_DESKTOP_GATE"])
	print(JSON.stringify(out))
	if not failures.is_empty():
		print("FAIL failures=", failures)
		quit(1)
	else:
		quit(0)
