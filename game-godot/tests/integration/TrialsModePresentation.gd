extends SceneTree
## Mode presentation scaffolds — honest art_status; HUMAN_ART stays false.

const Presentation = preload("res://scripts/trials/mode_presentation.gd")
const Colossus = preload("res://scripts/trials/unbound/colossus_rig.gd")
const Authority = preload("res://scripts/trials/mode_authority.gd")

var failures: Array = []
var checks := 0


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	await process_frame
	for mode_id in Authority.all_mode_ids():
		var p: Dictionary = Presentation.for_mode(mode_id, 11)
		check(Presentation.assert_no_human_art(p), "no_human_art_" + mode_id)
		check(str(p.get("art_status", "")) != "", "art_status_" + mode_id)
		check(not bool(p.get("HUMAN_ART_APPROVED", true)), "art_approved_false_" + mode_id)
		check((p.get("elements", []) as Array).size() > 0, "elements_" + mode_id)
		var entry: Dictionary = Authority.mode_entry(mode_id)
		check(not bool(entry.get("HUMAN_ART", true)), "catalog_human_art_false_" + mode_id)

	var derby: Dictionary = Presentation.derby(3)
	check(str(derby.get("elements", [])[0].get("id", "")) == "impact_dummy", "derby_dummy")
	check(str(derby.get("elements", [])[1].get("id", "")) == "kinetic_bat_launcher", "derby_bat")

	var flag: Dictionary = Presentation.flagline_territory(3, 0)
	var rooms: Array = []
	for el in flag.get("elements", []):
		if str(el.get("id", "")) == "territory_strip":
			rooms = el.get("rooms", [])
	check(rooms.size() == 5, "flagline_five_rooms")

	var prism: Dictionary = Presentation.prism_tiles(3)
	check(str(prism.get("elements", [])[0].get("kind", "")) == "tile_grid", "prism_grid")

	var rift: Dictionary = Presentation.riftline_lanes(3)
	check(str(rift.get("elements", [])[0].get("kind", "")) == "four_lanes", "rift_lanes")

	var echoes: Dictionary = Presentation.survival_echoes(3)
	check(not bool(echoes.get("elements", [])[0].get("echoes_are_real_puppets", true)), "echoes_not_puppets")

	var unbound: Dictionary = Presentation.unbound_colossus(3, "colossus_clash")
	check(str(unbound.get("label", "")) == "UNBALANCED MYTHIC", "unbound_label")
	var rigs: Array = Colossus.spawn_for_preset("colossus_clash", 3)
	check(rigs.size() >= 2, "colossus_spawn")
	var cam: Dictionary = Colossus.camera_profile_for_battle(rigs[0])
	check(cam.has("minZoom"), "camera_min_zoom")
	check(bool(cam.get("a11y_reduce_motion_respected", false)), "camera_a11y")
	check(not bool(cam.get("HUMAN_ART_APPROVED", true)), "camera_no_human_art")
	var coll: Dictionary = Colossus.collision_scaffold_summary(rigs[0])
	check(str(coll.get("mode", "")) == "scale_aware_capsule", "collision_mode")
	check(bool(coll.get("not_simple_uniform_scale_hitbox", false)), "not_uniform_scale")

	var flags: Dictionary = Authority.shipping_flags_false()
	check(not bool(flags.get("HUMAN_ART_APPROVED", true)), "ship_human_art")
	check(not bool(flags.get("RC2_READY", true)), "ship_rc2")
	check(not bool(flags.get("V1_0_0_RELEASE_AUTHORIZED", true)), "ship_v1")
	check(not bool(flags.get("SHIPPING_ROLLBACK_ENABLED", true)), "ship_rollback")

	print("TRIALS_MODE_PRESENTATION ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
