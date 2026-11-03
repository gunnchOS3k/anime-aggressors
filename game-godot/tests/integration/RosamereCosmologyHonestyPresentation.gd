extends SceneTree
## Rosamere three-form presentation deepen + Yin/Yang/Puppet/Prismatic honesty.
## Choreography/presentation stubs ≠ HUMAN_ART. Does not replace Codex combat data.

var output := ""
var checks: Array = []
var failures: Array = []


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, label: String) -> void:
	checks.append({"check": label, "pass": value})
	if not value:
		failures.append(label)


func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):
			output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated profile required")
		quit(2)
		return

	var Presentation = load("res://scripts/visual/rosamere_form_presentation.gd")
	check(Presentation != null, "presentation_loads")

	var prod: Dictionary = Presentation.validate_production()
	check(bool(prod.get("ok", false)), "validate_production")
	for f in prod.get("failures", []):
		check(false, "prod:" + str(f))
	check(int(prod.get("presentation_cards", 0)) == 3, "three_presentation_cards")
	check(bool(prod.get("cosmology_honesty_ok", false)), "cosmology_honesty_in_production")
	check(not bool(prod.get("HUMAN_ART_APPROVED", true)), "prod_human_art_false")
	check(bool(prod.get("HitResolver_untouched", false)), "prod_hitresolver_untouched")
	check(bool(prod.get("Codex_combat_data_untouched", false)), "prod_codex_untouched")

	var honesty: Dictionary = Presentation.validate_cosmology_honesty()
	check(bool(honesty.get("ok", false)), "validate_cosmology_honesty")
	for f in honesty.get("failures", []):
		check(false, "honesty:" + str(f))

	## Three-form presentation cards.
	var cards: Array = Presentation.all_presentation_cards()
	check(cards.size() == 3, "cards_size_three")
	for card in cards:
		var fid := str(card.get("form_id", ""))
		check(str(card.get("pose_idle", "")) != "", "card_pose:" + fid)
		check(str(card.get("vfx_motif", "")) != "", "card_vfx:" + fid)
		check(str(card.get("transform_beat", "")) != "", "card_transform:" + fid)
		check(str(card.get("presentation_line", "")) != "", "card_line:" + fid)
		check(not bool(card.get("HUMAN_ART_APPROVED", true)), "card_art_false:" + fid)
		check(not bool(card.get("choreography_is_human_art", true)), "card_choreo_false:" + fid)
		check(bool(card.get("Codex_combat_data_untouched", false)), "card_codex:" + fid)
		var not_list: Array = card.get("cosmology_not", [])
		check("yin" in not_list and "yang" in not_list, "card_excludes_yin_yang:" + fid)
		check("PRISMATIC_GRAY" in not_list, "card_excludes_gray:" + fid)

	## Domain honesty surfaces.
	for domain in ["yin", "yang", "puppet", "prismatic_gray"]:
		var surface: Dictionary = Presentation.domain_honesty_surface(domain)
		check(bool(surface.get("ok", false)), "surface_ok:" + domain)
		check(not bool(surface.get("is_rosamere_form", true)), "surface_not_pink:" + domain)
		check(str(surface.get("presentation_line", "")) != "", "surface_line:" + domain)
		check(not bool(surface.get("HUMAN_ART_APPROVED", true)), "surface_art_false:" + domain)
		check(bool(surface.get("HitResolver_untouched", false)), "surface_hr:" + domain)
		check(bool(surface.get("form_authority_applicable", false)), "surface_authority:" + domain)

	var gray: Dictionary = Presentation.domain_honesty_surface("prismatic_gray")
	check(str(gray.get("relation_to_pink", "")).find("cannot_defeat_pink") >= 0, "gray_cannot_defeat_pink")
	var puppet: Dictionary = Presentation.domain_honesty_surface("BLACK_PUPPET")
	check(bool(puppet.get("ok", false)) and str(puppet.get("domain_id", "")) == "puppet", "black_puppet_aliases")

	## FormStateAuthority: Pink forms stay pink domain; puppets/gray stay story domains.
	var Authority = load("res://scripts/combat/form_state_authority.gd")
	var pink: Dictionary = Authority.describe("rosamere", "FIRST_BLOOM")
	check(str(pink.get("domain", "")) == "primordial_pink_three_form_canon", "pink_domain")
	check(int(pink.get("manifestation_count", 0)) == 3, "pink_three")
	var black: Dictionary = Authority.describe("ember-vale", "BLACK_PUPPET")
	check(str(black.get("domain", "")) == "story_visual_variant", "puppet_story_visual")
	var prig: Dictionary = Authority.describe("kaia-windrow", "PRISMATIC_GRAY")
	check(str(prig.get("domain", "")) == "story_visual_variant", "gray_story_visual")
	var yin: Dictionary = Authority.describe("yin", "BASE")
	check(bool(yin.get("applicable", false)), "yin_applicable")

	## Story campaign pink surface still shows deepened honesty.
	var campaign = root.get_node("CampaignRuntime")
	var router = root.get_node("SceneRouter")
	campaign.save_path = "user://rosamere_cosmology_honesty_presentation.json"
	check(campaign.reset_campaign(), "reset")
	campaign.progress.routes["kaia-windrow"].cursor = "kaia-windrow:pink_revelation"
	check(campaign.save_progress(), "fixture_pink")
	router.go("story")
	var landed := false
	for _i in range(180):
		await process_frame
		if current_scene != null and str(current_scene.scene_file_path).ends_with("StoryCampaignScene.tscn"):
			landed = true
			break
	check(landed, "story_scene")
	if landed:
		var scene = current_scene
		if scene.has_method("_refresh"):
			scene._refresh()
		await process_frame
		var hook_label = null
		for c in scene.find_children("*", "Label", true, false):
			if str(c.name) == "RosamereStoryPresentationHook":
				hook_label = c
				break
		check(hook_label != null and hook_label.visible, "hook_visible")
		if hook_label != null:
			check(str(hook_label.text).find("Yin/Yang/Puppet/Gray") >= 0 or str(hook_label.text).find("cannot defeat Pink") >= 0, "hook_cosmology_text")
			check(str(hook_label.text).find("HitResolver") >= 0, "hook_hr")

	_finish()


func _finish() -> void:
	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"scope": "Rosamere three-form presentation cards + Yin/Yang/Puppet/Prismatic honesty; ≠ HUMAN_ART; Codex combat untouched",
		"HUMAN_ART_APPROVED": false,
		"choreography_is_human_art": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("ROSAMERE_COSMOLOGY_HONESTY_PRESENTATION.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(result, "\t"))
	print("ROSAMERE_COSMOLOGY_HONESTY_PRESENTATION ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks.size())
	quit(0 if failures.is_empty() else 1)
