extends SceneTree
## Trials catalog + mode-authority contract smoke.

const Authority = preload("res://scripts/trials/mode_authority.gd")
const Catalog = preload("res://scripts/trials/trials_catalog.gd")

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
	var cat := Authority.load_catalog()
	check(not cat.is_empty(), "catalog_loads")
	check(int(cat.get("tick_hz", 0)) == 60, "tick_hz_60")
	check(not bool(cat.get("HUMAN_ART_APPROVED", true)), "human_art_false")
	check(not bool(cat.get("RC2_READY", true)), "rc2_false")
	check(not bool(cat.get("V1_0_0_RELEASE_AUTHORIZED", true)), "v1_false")
	check(not bool(cat.get("SHIPPING_ROLLBACK_ENABLED", true)), "shipping_rollback_false")
	var ids := Authority.all_mode_ids()
	check(ids.size() == 6, "six_modes")
	for expected in ["resonance_trial", "fractured_accord", "prism_weave", "riftline_defense", "echoes_gauntlet", "convergence_unbound"]:
		check(expected in ids, "has_" + expected)
		check(not Authority.feeds_ranked_mmr(expected), "no_ranked_" + expected)
	check(Catalog.scene_key_for("resonance_trial") == "trial_resonance", "derby_scene_key")
	check(Catalog.scene_key_for("convergence_unbound") == "trial_unbound", "unbound_scene_key")
	check(ResourceLoader.exists("res://scenes/menus/TrialsHubScene.tscn"), "hub_scene")
	for path in [
		"res://scenes/trials/ResonanceTrialScene.tscn",
		"res://scenes/trials/FracturedAccordScene.tscn",
		"res://scenes/trials/PrismWeaveScene.tscn",
		"res://scenes/trials/RiftlineDefenseScene.tscn",
		"res://scenes/trials/EchoesGauntletScene.tscn",
		"res://scenes/trials/ConvergenceUnboundScene.tscn",
	]:
		check(ResourceLoader.exists(path), "scene_" + path.get_file())
	print("TRIALS_MODE_AUTHORITY ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
