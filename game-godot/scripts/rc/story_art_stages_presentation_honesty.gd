extends RefCounted
class_name StoryArtStagesPresentationHonesty
## Cross-surface Story / Rosamere art / Trials / stages presentation honesty.
## Digital deepen only — ≠ HUMAN_ART / device / owner sign-off / RC2 / V1.
## Does not rewrite Codex HitResolver / combat data / rollback trees.

const StagePresentation = preload("res://scripts/battle/stage_presentation.gd")
const RosamerePresentation = preload("res://scripts/visual/rosamere_form_presentation.gd")
const RosamerePolish = preload("res://scripts/rc/rosamere_surface_polish.gd")
const TrialsPresentation = preload("res://scripts/trials/mode_presentation.gd")
const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")
const StoryHonesty = preload("res://scripts/story/story_journey_honesty.gd")
const CursorComplete = preload("res://scripts/rc/cursor_complete_honesty.gd")


static func presentation_honesty_card() -> Dictionary:
	return {
		"req_ids": ["AA-RTM-002", "AA-RTM-003", "AA-RTM-004"],
		"surfaces": ["story", "rosamere_art", "trials", "stages"],
		"story_presentation_hooks": true,
		"rosamere_three_form_only": true,
		"trials_six_mode_scaffold_presentation": true,
		"stages_30_layout_playable": true,
		"layout_playable_neq_human_art": true,
		"choreography_is_human_art": false,
		"HUMAN_ART_APPROVED": false,
		"device_matrix_pass": false,
		"owner_sign_off": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
	}


static func story_surface_contract() -> Dictionary:
	var failures: Array = []
	var story_card: Dictionary = StoryHonesty.presentation_honesty_card()
	if bool(story_card.get("HUMAN_ART_APPROVED", true)):
		failures.append("story_art_claimed")
	if bool(story_card.get("owner_sign_off", true)):
		failures.append("story_owner_claimed")
	var pink: Dictionary = RosamerePresentation.story_integration_contract({
		"id": "kaia-windrow:pink_revelation",
		"fighter_hint": "rosamere",
	})
	if not bool(pink.get("ok", false)):
		failures.append("pink_story_contract")
	if bool(pink.get("HUMAN_ART_APPROVED", true)):
		failures.append("pink_art_claimed")
	if bool(pink.get("choreography_is_human_art", true)):
		failures.append("pink_choreo_claimed")
	if (pink.get("forms", []) as Array).size() != 3:
		failures.append("pink_not_three_forms")
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"story_card": story_card,
		"pink_revelation": pink,
		"HUMAN_ART_APPROVED": false,
		"owner_sign_off": false,
	}


static func rosamere_art_surface_contract() -> Dictionary:
	var failures: Array = []
	if not RosamerePresentation.art_status_honest():
		failures.append("art_status_dishonest")
	var three: Dictionary = RosamerePolish.three_form_contract()
	if not bool(three.get("ok", false)):
		failures.append("three_form")
		for f in three.get("failures", []):
			failures.append("3:" + str(f))
	## Cross-check production JSON honesty without claiming final art.
	var doc: Dictionary = RosamerePresentation.load_doc()
	var art: Dictionary = doc.get("art_status", {})
	if bool(art.get("HUMAN_ART_APPROVED", true)):
		failures.append("prod_art_claimed")
	if bool(art.get("cel_shaded_glb", true)):
		failures.append("cel_shaded_claimed")
	if bool(art.get("cinematic_final_mix", true)):
		failures.append("cinematic_final_claimed")
	if bool(art.get("vfx_final_approved", true)):
		failures.append("vfx_final_claimed")
	var status := str(art.get("status", ""))
	if status != "THREE_FORM_PRESENTATION_PRODUCTION_IN_PROGRESS":
		failures.append("unexpected_art_status:" + status)
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"three_form": three,
		"art_status": status,
		"HUMAN_ART_APPROVED": false,
		"cel_shaded_glb": false,
	}


static func trials_surface_contract() -> Dictionary:
	var failures: Array = []
	var modes: Array = Bridge.LIVE_SHARED_COMBAT_MODES
	if modes.size() != 6:
		failures.append("not_six_modes")
	var cards: Array = []
	for mode_id in modes:
		var payload: Dictionary = TrialsPresentation.for_mode(str(mode_id), 7)
		cards.append(payload)
		if not TrialsPresentation.assert_no_human_art(payload):
			failures.append("human_art_leak:" + str(mode_id))
		if bool(payload.get("RC2_READY", true)):
			failures.append("rc2_claimed:" + str(mode_id))
		if bool(payload.get("V1_0_0_RELEASE_AUTHORIZED", true)):
			failures.append("v1_claimed:" + str(mode_id))
		## Stage backdrop binding honesty — presentation scaffold only.
		var bound: Dictionary = TrialsPresentation.stage_backdrop_honesty(str(mode_id))
		if not bool(bound.get("ok", false)):
			failures.append("backdrop:" + str(mode_id))
		if bool(bound.get("HUMAN_ART_APPROVED", true)):
			failures.append("backdrop_art:" + str(mode_id))
	var spoiler: Dictionary = RosamerePolish.trials_spoiler_safe_contract()
	if not bool(spoiler.get("ok", false)):
		failures.append("spoiler")
		for f in spoiler.get("failures", []):
			failures.append("t:" + str(f))
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"mode_count": modes.size(),
		"cards": cards,
		"spoiler": spoiler,
		"HUMAN_ART_APPROVED": false,
		"feeds_ranked_mmr": false,
		"device_matrix_pass": false,
	}


static func stages_surface_contract() -> Dictionary:
	return StagePresentation.registry_presentation_contract()


static func cross_surface_bindings() -> Dictionary:
	## Story pink revelation may foreshadow stages; Trials may mount stage backdrops;
	## neither may claim HUMAN_ART or invent device evidence.
	var failures: Array = []
	var stages: Dictionary = stages_surface_contract()
	if not bool(stages.get("ok", false)):
		failures.append("stages_registry")
	var foreshadow_count := 0
	for card in stages.get("cards", []):
		if typeof(card) != TYPE_DICTIONARY:
			continue
		var pink: Variant = card.get("pink_foreshadow", {})
		if typeof(pink) == TYPE_DICTIONARY and not (pink as Dictionary).is_empty():
			foreshadow_count += 1
			if bool((pink as Dictionary).get("HUMAN_ART_APPROVED", false)):
				failures.append("pink_foreshadow_art:" + str(card.get("stage_id", "")))
	## At least some expanded stages carry pink foreshadow presentation metadata.
	if foreshadow_count < 1:
		failures.append("no_pink_foreshadow_surfaces")
	## Deepen: every Trials mode backdrop keeps layout≠HUMAN_ART + RC2/V1 false.
	var backdrop_ok_count := 0
	for mode_id in Bridge.LIVE_SHARED_COMBAT_MODES:
		var bound: Dictionary = TrialsPresentation.stage_backdrop_honesty(str(mode_id))
		if bool(bound.get("ok", false)) and bool(bound.get("layout_playable_neq_human_art", false)):
			if not bool(bound.get("RC2_READY", true)) and not bool(bound.get("V1_0_0_RELEASE_AUTHORIZED", true)):
				backdrop_ok_count += 1
			else:
				failures.append("backdrop_gate:" + str(mode_id))
		else:
			failures.append("backdrop_deepen:" + str(mode_id))
	if backdrop_ok_count != Bridge.LIVE_SHARED_COMBAT_MODES.size():
		failures.append("backdrop_deepen_incomplete")
	var complete: Dictionary = CursorComplete.presentation_honesty_card()
	if bool(complete.get("CURSOR_COMPLETE", true)):
		failures.append("cursor_complete_claimed")
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"pink_foreshadow_stage_count": foreshadow_count,
		"playable_stage_count": int(stages.get("playable_count", 0)),
		"trials_backdrop_layout_neq_art_count": backdrop_ok_count,
		"CURSOR_COMPLETE": false,
		"HUMAN_ART_APPROVED": false,
	}


static func validate() -> Dictionary:
	var failures: Array = []
	var story: Dictionary = story_surface_contract()
	if not bool(story.get("ok", false)):
		failures.append("story")
		for f in story.get("failures", []):
			failures.append("s:" + str(f))
	var rosa: Dictionary = rosamere_art_surface_contract()
	if not bool(rosa.get("ok", false)):
		failures.append("rosamere_art")
		for f in rosa.get("failures", []):
			failures.append("r:" + str(f))
	var trials: Dictionary = trials_surface_contract()
	if not bool(trials.get("ok", false)):
		failures.append("trials")
		for f in trials.get("failures", []):
			failures.append("t:" + str(f))
	var stages: Dictionary = stages_surface_contract()
	if not bool(stages.get("ok", false)):
		failures.append("stages")
		for f in stages.get("failures", []):
			failures.append("g:" + str(f))
	var cross: Dictionary = cross_surface_bindings()
	if not bool(cross.get("ok", false)):
		failures.append("cross")
		for f in cross.get("failures", []):
			failures.append("x:" + str(f))
	var card: Dictionary = presentation_honesty_card()
	if bool(card.get("HUMAN_ART_APPROVED", true)):
		failures.append("card_art")
	if bool(card.get("RC2_READY", true)):
		failures.append("card_rc2")
	if bool(card.get("V1_0_0_RELEASE_AUTHORIZED", true)):
		failures.append("card_v1")
	if bool(card.get("CURSOR_COMPLETE", true)):
		failures.append("card_complete")
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"story": story,
		"rosamere_art": rosa,
		"trials": trials,
		"stages": {
			"ok": stages.get("ok", false),
			"failures": stages.get("failures", []),
			"expanded_count": stages.get("expanded_count", 0),
			"playable_count": stages.get("playable_count", 0),
			"pending_count": stages.get("pending_count", 0),
			"canonical_launch_preserved": stages.get("canonical_launch_preserved", false),
		},
		"cross": cross,
		"card": card,
		"HUMAN_ART_APPROVED": false,
		"device_matrix_pass": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
		"req_ids": card.get("req_ids", []),
	}
