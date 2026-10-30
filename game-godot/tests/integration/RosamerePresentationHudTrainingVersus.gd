extends "res://tests/integration/TrainingLifecycle.gd"
## Rosamere presentation-card HUD on training + versus — presentation-only.
## ≠ HUMAN_ART. Does not edit HitResolver / Codex combat.

const Hud = preload("res://scripts/ui/rosamere_presentation_hud.gd")


func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):
			output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated profile required")
		quit(2)
		return

	OS.set_environment("AA_ROSAMERE_DEV_OVERRIDE", "1")
	var gs = root.get_node("GameState")
	var router = root.get_node("SceneRouter")

	## Training surface.
	gs.begin_training()
	gs.p1_fighter_id = "rosamere"
	gs.p2_fighter_id = "kaia-windrow"
	gs.p1_body_variant = "female"
	gs.p2_body_variant = "female"
	gs.p1_form_id = "FAMILIAR_ROSE"
	gs.training_dummy_mode = "idle"
	gs.stage_id = "training-grid"
	router.go("training_battle")
	check(await wait_route("TrainingBattleScene.tscn"), "training_loads")
	if not route_is("TrainingBattleScene.tscn"):
		_finish()
		return
	var training = current_scene
	await frames(60)
	check(training.fighter1 != null and training.fighter1.fighter_id == "rosamere", "training_rosamere")
	var train_hud = training.hud
	check(train_hud != null, "training_hud")
	var train_labels: Array = Hud.find_mounted_labels(train_hud)
	check(train_labels.size() >= 1, "training_card_mounted")
	if train_labels.size() >= 1:
		var ttxt := str(train_labels[0].text)
		check(ttxt.find("FAMILIAR_ROSE") >= 0 or ttxt.find("Familiar") >= 0, "training_form_text")
		check(ttxt.find("≠ HUMAN_ART") >= 0 or ttxt.find("HUMAN_ART") >= 0, "training_art_honesty")
		check(ttxt.find("HitResolver") >= 0, "training_hr_honesty")
		check(ttxt.find("Yin") >= 0 or ttxt.find("Puppet") >= 0 or ttxt.find("Pink") >= 0, "training_cosmology")
	## Remount API honesty.
	var remount: Dictionary = training._mount_rosamere_presentation_hud()
	check(bool(remount.get("ok", false)), "training_remount_ok")
	check(not bool(remount.get("HUMAN_ART_APPROVED", true)), "training_remount_art_false")
	check(bool(remount.get("HitResolver_untouched", false)), "training_remount_hr")
	check(bool(remount.get("presentation_only", false)), "training_presentation_only")

	## Versus surface (BattleScene).
	gs.begin_local_versus(true)
	gs.p1_fighter_id = "rosamere"
	gs.p2_fighter_id = "ember-vale"
	gs.p1_form_id = "FIRST_BLOOM"
	gs.stage_id = "skyline-arena"
	gs.stocks = 2
	router.go("battle")
	check(await wait_route("BattleScene.tscn"), "versus_loads")
	if not route_is("BattleScene.tscn"):
		_finish()
		return
	var battle = current_scene
	## Skip intro dialogue if busy.
	var dialogue = root.get_node_or_null("StoryDialogue")
	if dialogue != null and dialogue.has_method("skip_all"):
		dialogue.skip_all()
	await frames(90)
	check(battle.fighter1 != null and str(battle.fighter1.fighter_id) == "rosamere", "versus_rosamere")
	var versus_labels: Array = Hud.find_mounted_labels(battle.hud)
	check(versus_labels.size() >= 1, "versus_card_mounted")
	if versus_labels.size() >= 1:
		var vtxt := str(versus_labels[0].text)
		check(vtxt.find("FIRST_BLOOM") >= 0 or vtxt.find("First Bloom") >= 0 or vtxt.find("bloom") >= 0, "versus_form_text")
		check(vtxt.find("HUMAN_ART") >= 0, "versus_art_honesty")
		check(vtxt.find("HitResolver") >= 0, "versus_hr_honesty")
	var versus_mount: Dictionary = battle._mount_rosamere_presentation_hud()
	check(bool(versus_mount.get("ok", false)), "versus_remount_ok")
	check(bool(versus_mount.get("Codex_combat_data_untouched", false)), "versus_codex_untouched")

	## Non-Rosamere matchup must not claim a card.
	gs.begin_local_versus(true)
	gs.p1_fighter_id = "kaia-windrow"
	gs.p2_fighter_id = "ember-vale"
	gs.p1_form_id = ""
	router.go("battle")
	check(await wait_route("BattleScene.tscn"), "non_rosa_loads")
	await frames(40)
	if dialogue != null and dialogue.has_method("skip_all"):
		dialogue.skip_all()
	await frames(40)
	var non = current_scene
	var non_labels: Array = Hud.find_mounted_labels(non.hud)
	check(non_labels.is_empty(), "non_rosamere_no_card")

	_finish()


func _finish() -> void:
	keys([])
	paused = false
	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"scope": "Rosamere presentation-card HUD on training + versus; ≠ HUMAN_ART; HitResolver untouched",
		"HUMAN_ART_APPROVED": false,
		"choreography_is_human_art": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("ROSAMERE_PRESENTATION_HUD_TRAINING_VERSUS.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(result, "\t"))
	print("ROSAMERE_PRESENTATION_HUD_TRAINING_VERSUS ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks.size())
	quit(0 if failures.is_empty() else 1)
