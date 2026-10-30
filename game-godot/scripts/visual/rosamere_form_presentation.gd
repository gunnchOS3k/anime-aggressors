extends RefCounted
## Rosamere three-form presentation production hooks (poses / VFX / audio / transitions).
## Honest art_status: runtime hooks authored; cel-shaded GLB and human final art NOT approved.
## COMPETITIVE_SELF_LIMITED is never a fourth form presentation.

const DOC_PATH := "res://data/story/rosamere_three_form_presentation_production.json"
const HOOKS_PATH := "res://data/story/rosamere_form_presentation_hooks.json"
const HONESTY_PATH := "res://data/story/rosamere_cosmology_honesty.json"
const Selection = preload("res://scripts/combat/rosamere_form_selection.gd")
const FormAuthority = preload("res://scripts/combat/form_state_authority.gd")
const Sfx = preload("res://scripts/audio/v1_candidate_sfx.gd")

const FORM_FAMILIAR := "FAMILIAR_ROSE"
const FORM_FIRST_BLOOM := "FIRST_BLOOM"
const FORM_EVERLASTING := "EVERLASTING_ORIGIN"

## Choreography stubs are runtime presentation scaffolding — never HUMAN_ART.
## Cosmology honesty surfaces (Yin/Yang/Puppet/Prismatic) are presentation-only —
## never replace Codex HitResolver / combat data.


static func load_doc() -> Dictionary:
	if not FileAccess.file_exists(DOC_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DOC_PATH))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func art_status_honest(doc: Dictionary = {}) -> bool:
	if doc.is_empty():
		doc = load_doc()
	var art: Dictionary = doc.get("art_status", {})
	if bool(art.get("HUMAN_ART_APPROVED", true)):
		return false
	if bool(art.get("cel_shaded_glb", true)):
		return false
	var status := str(art.get("status", ""))
	return status in [
		"THREE_FORM_PRESENTATION_PRODUCTION_IN_PROGRESS",
		"NOT_AUTHORED_THIS_PASS",
		"RUNTIME_HOOKS_AUTHORED_FINAL_ART_NOT_APPROVED",
	]


static func manifestation_presentation(form_id: String) -> Dictionary:
	var norm: Dictionary = Selection.normalize_selection(form_id)
	if not bool(norm.get("ok", false)):
		return {}
	var resolved := str(norm.get("form_id", FORM_FAMILIAR))
	var doc := load_doc()
	var entry: Dictionary = doc.get("manifestations", {}).get(resolved, {})
	if entry.is_empty():
		return Selection.presentation_contract(resolved)
	var out := entry.duplicate(true)
	out["form_id"] = resolved
	out["cel_shaded_glb"] = false
	out["HUMAN_ART_APPROVED"] = false
	return out


static func apply_to_fighter(fighter: Node, form_id: String, previous_form: String = "") -> Dictionary:
	var gate: Dictionary = Selection.select_for_mode(
		form_id,
		str(fighter.get_meta("rosamere_mode", "training")) if fighter != null and fighter.has_method("get_meta") else "training",
		true
	)
	## Presentation apply is permissive for already-gated forms; re-resolve presentation only.
	var norm: Dictionary = Selection.normalize_selection(form_id)
	if not bool(norm.get("ok", false)):
		return norm
	var resolved := str(norm.get("form_id", FORM_FAMILIAR))
	var presentation := manifestation_presentation(resolved)
	if fighter == null or not is_instance_valid(fighter):
		return {"ok": false, "reason": "invalid_fighter"}
	var card := presentation_card_for_form(resolved)
	if fighter.has_method("set_meta"):
		fighter.set_meta("rosamere_presentation", presentation)
		fighter.set_meta("rosamere_presentation_production", "RUNTIME_HOOKS_AUTHORED_FINAL_ART_NOT_APPROVED")
		fighter.set_meta("rosamere_presentation_card", card)
		fighter.set_meta("rosamere_cosmology_honesty", cosmology_honesty_summary())
	## Caller owns apply_form / Pink form authority; this module only presents.
	_play_transition(fighter, previous_form, resolved, presentation)
	_apply_model_presentation(fighter, presentation)
	return {
		"ok": true,
		"form_id": resolved,
		"presentation": presentation,
		"presentation_card": card,
		"art_status": "THREE_FORM_PRESENTATION_PRODUCTION_IN_PROGRESS",
		"HUMAN_ART_APPROVED": false,
		"cel_shaded_glb": false,
		"choreography_is_human_art": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
		"gate": gate,
	}


static func _play_transition(fighter: Node, from_id: String, to_id: String, presentation: Dictionary) -> void:
	if from_id.is_empty() or from_id == to_id:
		return
	var hook: Dictionary = Selection.transition_hook(from_id, to_id)
	var clip := str(hook.get("clip", presentation.get("transform_in_clip", presentation.get("pose_idle", "idle"))))
	if fighter.model_3d != null and fighter.model_3d.has_method("play_clip"):
		fighter.model_3d.play_clip(clip)
	var sfx_event := str(hook.get("sfx", presentation.get("transition_in_sfx", "transform")))
	Sfx.play_event("rosamere", "transform", fighter)
	var cinematic := cinematic_beat_for_form(to_id)
	if fighter.model_3d != null and fighter.model_3d.has_method("set_cinematic_expression"):
		fighter.model_3d.set_cinematic_expression(str(cinematic.get("expression", presentation.get("cinematic_expression", ""))))
	if fighter.has_method("set_meta"):
		fighter.set_meta("rosamere_last_transition", {
			"from": from_id,
			"to": to_id,
			"clip": clip,
			"sfx_event": sfx_event,
			"camera_beat": str(hook.get("camera_beat", presentation.get("camera_beat", cinematic.get("camera", "")))),
			"vfx_burst": str(hook.get("vfx_burst", "")),
			"deterministic": true,
			"final_art_approved": false,
			"cinematic_final_mix": false,
		})


static func _apply_model_presentation(fighter: Node, presentation: Dictionary) -> void:
	if fighter.model_3d == null:
		return
	var entry := {
		"presentation": presentation,
		"idle_clip": str(presentation.get("pose_idle", "idle")),
		"transformed_idle_clip": str(presentation.get("pose_transformed_idle", presentation.get("pose_idle", "idle"))),
		"aura_shape": str(presentation.get("aura_shape", "soft_petals")),
		"emission_strength": float(presentation.get("emission_strength", 0.18)),
		"vfx_particle_budget": int(presentation.get("vfx_particle_budget", 18)),
		"camera_beat": str(presentation.get("camera_beat", "")),
	}
	if fighter.model_3d.has_method("set_form_id"):
		fighter.model_3d.set_form_id(str(presentation.get("form_id", FORM_FAMILIAR)), entry)
	if fighter.model_3d.has_method("set_cinematic_expression"):
		fighter.model_3d.set_cinematic_expression(str(presentation.get("cinematic_expression", "")))
	if fighter.has_method("set_meta"):
		fighter.set_meta("rosamere_vfx_motif", str(presentation.get("vfx_motif", "")))
		fighter.set_meta("rosamere_vfx_particle_budget", int(presentation.get("vfx_particle_budget", 18)))
		fighter.set_meta("rosamere_camera_beat", str(presentation.get("camera_beat", "")))


static func cinematic_presentation() -> Dictionary:
	var doc := load_doc()
	return doc.get("cinematic_presentation", {})


static func cinematic_beat_for_form(form_id: String) -> Dictionary:
	var cinematic: Dictionary = cinematic_presentation()
	for beat in cinematic.get("beats", []):
		if str(beat.get("form_id", "")) == form_id:
			return beat
	return {}


static func load_hooks_doc() -> Dictionary:
	if not FileAccess.file_exists(HOOKS_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(HOOKS_PATH))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func story_hook_for_form(form_id: String) -> Dictionary:
	## Story integration presentation hook — not HitResolver / not HUMAN_ART.
	var norm: Dictionary = Selection.normalize_selection(form_id)
	if not bool(norm.get("ok", false)):
		return {}
	var resolved := str(norm.get("form_id", FORM_FAMILIAR))
	var doc := load_doc()
	var hooks: Dictionary = doc.get("story_hooks", {})
	var entry: Dictionary = hooks.get(resolved, {})
	if entry.is_empty():
		var hooks_doc := load_hooks_doc()
		var form_row: Dictionary = hooks_doc.get("forms", {}).get(resolved, {})
		entry = {
			"form_id": resolved,
			"roman": str(form_row.get("roman", "")),
			"story_modes": form_row.get("modes", []),
			"pink_revelation_node": str(hooks_doc.get("pink_revelation_node", "kaia-windrow:pink_revelation")),
			"insert_after": str(hooks_doc.get("insert_after", "")),
		}
	var out := entry.duplicate(true)
	out["form_id"] = resolved
	out["HUMAN_ART_APPROVED"] = false
	out["choreography_is_human_art"] = false
	out["status"] = str(out.get("status", "STORY_HOOK_RUNTIME_STUB"))
	return out


static func choreography_stub_for_form(form_id: String) -> Dictionary:
	## Authored choreography stub beats for Cursor presentation — honesty ≠ HUMAN_ART.
	var norm: Dictionary = Selection.normalize_selection(form_id)
	if not bool(norm.get("ok", false)):
		return {}
	var resolved := str(norm.get("form_id", FORM_FAMILIAR))
	var doc := load_doc()
	var stubs: Dictionary = doc.get("choreography_stubs", {})
	var entry: Dictionary = stubs.get(resolved, {})
	if entry.is_empty():
		var presentation := manifestation_presentation(resolved)
		entry = {
			"form_id": resolved,
			"idle_beat": str(presentation.get("pose_idle", "idle")),
			"transform_beat": str(presentation.get("transform_in_clip", presentation.get("pose_idle", "idle"))),
			"camera_beat": str(presentation.get("camera_beat", "")),
			"expression": str(presentation.get("cinematic_expression", "")),
			"vfx_motif": str(presentation.get("vfx_motif", "")),
		}
	var out := entry.duplicate(true)
	out["form_id"] = resolved
	out["HUMAN_ART_APPROVED"] = false
	out["choreography_is_human_art"] = false
	out["status"] = str(out.get("status", "CHOREOGRAPHY_STUB_NOT_HUMAN_ART"))
	out["final_mix"] = false
	return out


static func story_integration_contract(node: Dictionary = {}) -> Dictionary:
	## Forms presentation + Story hooks for campaign UI / pink revelation surface.
	var hooks_doc := load_hooks_doc()
	var node_id := str(node.get("id", ""))
	var fighter_hint := str(node.get("fighter_hint", ""))
	var is_pink := node_id == str(hooks_doc.get("pink_revelation_node", "kaia-windrow:pink_revelation")) \
		or bool(node.get("pink_working_identity", false)) \
		or fighter_hint == "rosamere"
	var forms: Array = []
	for fid in [FORM_FAMILIAR, FORM_FIRST_BLOOM, FORM_EVERLASTING]:
		forms.append({
			"form_id": fid,
			"story_hook": story_hook_for_form(fid),
			"choreography_stub": choreography_stub_for_form(fid),
			"presentation_card": presentation_card_for_form(fid),
		})
	return {
		"ok": true,
		"fighter_id": "rosamere",
		"story_surface": is_pink,
		"node_id": node_id,
		"pink_revelation_node": str(hooks_doc.get("pink_revelation_node", "kaia-windrow:pink_revelation")),
		"forms": forms,
		"cosmology_honesty": cosmology_honesty_summary(),
		"HUMAN_ART_APPROVED": false,
		"choreography_is_human_art": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
		"status": "STORY_PRESENTATION_HOOKS_AUTHORED_FINAL_ART_NOT_APPROVED",
	}


static func load_honesty_doc() -> Dictionary:
	if not FileAccess.file_exists(HONESTY_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(HONESTY_PATH))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func cosmology_honesty_summary() -> Dictionary:
	var doc := load_honesty_doc()
	if doc.is_empty():
		return {"ok": false, "reason": "missing_honesty_doc"}
	return {
		"ok": true,
		"status": str(doc.get("status", "")),
		"domains": ["yin", "yang", "puppet", "prismatic_gray"],
		"three_forms": [FORM_FAMILIAR, FORM_FIRST_BLOOM, FORM_EVERLASTING],
		"HUMAN_ART_APPROVED": false,
		"choreography_is_human_art": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
		"invariants": doc.get("invariants", []),
	}


static func domain_honesty_surface(domain_id: String) -> Dictionary:
	## Yin / Yang / Puppet / Prismatic Gray presentation honesty — not combat rewrite.
	var doc := load_honesty_doc()
	var key := domain_id.strip_edges().to_lower()
	if key in ["black_puppet", "white_puppet", "puppets"]:
		key = "puppet"
	if key in ["prismatic", "gray", "prismatic-gray", "kaia_gray"]:
		key = "prismatic_gray"
	var entry: Dictionary = doc.get("domains", {}).get(key, {})
	if entry.is_empty():
		return {"ok": false, "reason": "unknown_domain", "domain_id": domain_id}
	var out := entry.duplicate(true)
	out["ok"] = true
	out["domain_id"] = key
	out["HUMAN_ART_APPROVED"] = false
	out["choreography_is_human_art"] = false
	out["is_rosamere_form"] = false
	out["HitResolver_untouched"] = true
	out["Codex_combat_data_untouched"] = true
	## Cross-check FormStateAuthority domains without mutating combat ownership.
	match key:
		"yin", "yang":
			var desc: Dictionary = FormAuthority.describe(key, "BASE")
			out["form_authority_domain"] = str(desc.get("domain", ""))
			out["form_authority_applicable"] = bool(desc.get("applicable", false))
		"puppet":
			var black: Dictionary = FormAuthority.describe("kaia-windrow", "BLACK_PUPPET")
			out["form_authority_domain"] = str(black.get("domain", ""))
			out["form_authority_applicable"] = bool(black.get("applicable", false))
			out["states"] = entry.get("states", ["BLACK_PUPPET", "WHITE_PUPPET"])
		"prismatic_gray":
			var gray: Dictionary = FormAuthority.describe("kaia-windrow", "PRISMATIC_GRAY")
			out["form_authority_domain"] = str(gray.get("domain", ""))
			out["form_authority_applicable"] = bool(gray.get("applicable", false))
	return out


static func presentation_card_for_form(form_id: String) -> Dictionary:
	## Deepened three-form presentation card: pose/VFX/choreo + cosmology honesty.
	var norm: Dictionary = Selection.normalize_selection(form_id)
	if not bool(norm.get("ok", false)):
		return {}
	var resolved := str(norm.get("form_id", FORM_FAMILIAR))
	var presentation := manifestation_presentation(resolved)
	var choreo := choreography_stub_for_form(resolved)
	var hook := story_hook_for_form(resolved)
	var honesty := load_honesty_doc()
	var form_honesty: Dictionary = honesty.get("three_forms", {}).get(resolved, {})
	var doc := load_doc()
	var cards: Dictionary = doc.get("presentation_cards", {})
	var card: Dictionary = cards.get(resolved, {})
	var out := {
		"form_id": resolved,
		"roman": str(form_honesty.get("roman", presentation.get("roman", ""))),
		"pose_idle": str(presentation.get("pose_idle", "")),
		"aura_shape": str(presentation.get("aura_shape", "")),
		"vfx_motif": str(presentation.get("vfx_motif", "")),
		"camera_beat": str(presentation.get("camera_beat", choreo.get("camera_beat", ""))),
		"expression": str(presentation.get("cinematic_expression", choreo.get("expression", ""))),
		"transform_beat": str(choreo.get("transform_beat", "")),
		"presentation_line": str(card.get("presentation_line", form_honesty.get("presentation_line", hook.get("presentation_line", "")))),
		"cosmology_not": form_honesty.get("not", []),
		"domain": str(form_honesty.get("domain", "primordial_pink_three_form_canon")),
		"choreography_stub": choreo,
		"story_hook": hook,
		"HUMAN_ART_APPROVED": false,
		"choreography_is_human_art": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
		"status": str(card.get("status", "PRESENTATION_CARD_RUNTIME_STUB_NOT_HUMAN_ART")),
	}
	if resolved == FORM_EVERLASTING:
		out["modes"] = form_honesty.get("modes", ["story", "ova", "mythic_party"])
		out["never_ranked"] = true
	return out


static func all_presentation_cards() -> Array:
	var cards: Array = []
	for fid in [FORM_FAMILIAR, FORM_FIRST_BLOOM, FORM_EVERLASTING]:
		cards.append(presentation_card_for_form(fid))
	return cards


static func validate_cosmology_honesty() -> Dictionary:
	var doc := load_honesty_doc()
	var failures: Array = []
	if doc.is_empty():
		failures.append("missing_honesty_doc")
		return {"ok": false, "failures": failures}
	if bool(doc.get("HUMAN_ART_APPROVED", true)):
		failures.append("honesty_human_art_must_stay_false")
	if bool(doc.get("choreography_is_human_art", true)):
		failures.append("honesty_choreography_must_not_claim_art")
	if not bool(doc.get("HitResolver_untouched", false)):
		failures.append("must_declare_hitresolver_untouched")
	if not bool(doc.get("Codex_combat_data_untouched", false)):
		failures.append("must_declare_codex_combat_untouched")
	var forms: Dictionary = doc.get("three_forms", {})
	for need in [FORM_FAMILIAR, FORM_FIRST_BLOOM, FORM_EVERLASTING]:
		if not forms.has(need):
			failures.append("missing_form_honesty:" + need)
		elif str(forms[need].get("presentation_line", "")).is_empty():
			failures.append("missing_form_line:" + need)
	var domains: Dictionary = doc.get("domains", {})
	for need in ["yin", "yang", "puppet", "prismatic_gray"]:
		if not domains.has(need):
			failures.append("missing_domain:" + need)
		else:
			var row: Dictionary = domains[need]
			if bool(row.get("is_rosamere_form", true)):
				failures.append("domain_must_not_claim_rosamere_form:" + need)
			if str(row.get("presentation_line", "")).is_empty():
				failures.append("missing_domain_line:" + need)
			if bool(row.get("HUMAN_ART_APPROVED", true)):
				failures.append("domain_human_art_must_stay_false:" + need)
	## Domain surfaces must resolve and stay non-Pink.
	for need in ["yin", "yang", "puppet", "prismatic_gray"]:
		var surface: Dictionary = domain_honesty_surface(need)
		if not bool(surface.get("ok", false)):
			failures.append("surface_fail:" + need)
		elif bool(surface.get("is_rosamere_form", true)):
			failures.append("surface_claims_rosamere:" + need)
	var gray: Dictionary = domain_honesty_surface("prismatic_gray")
	if str(gray.get("relation_to_pink", "")).find("cannot_defeat_pink") < 0:
		failures.append("prismatic_must_admit_cannot_defeat_pink")
	var invariants: Array = doc.get("invariants", [])
	for need in [
		"exactly_three_pink_manifestations",
		"competitive_self_limited_not_fourth_form",
		"puppets_not_pink_forms",
		"prismatic_gray_cannot_defeat_pink",
		"presentation_does_not_replace_codex_combat_data",
	]:
		if need not in invariants:
			failures.append("missing_invariant:" + need)
	if bool(doc.get("RC2_READY", true)) or bool(doc.get("V1_0_0_RELEASE_AUTHORIZED", true)):
		failures.append("release_gates_must_stay_false")
	## Presentation cards for all three forms.
	for card in all_presentation_cards():
		var fid := str(card.get("form_id", ""))
		if str(card.get("presentation_line", "")).is_empty():
			failures.append("empty_card_line:" + fid)
		if bool(card.get("HUMAN_ART_APPROVED", true)):
			failures.append("card_human_art:" + fid)
		if bool(card.get("choreography_is_human_art", true)):
			failures.append("card_choreo_art:" + fid)
		var not_list: Array = card.get("cosmology_not", [])
		if "yin" not in not_list or "yang" not in not_list:
			failures.append("card_must_exclude_yin_yang:" + fid)
		if "PRISMATIC_GRAY" not in not_list:
			failures.append("card_must_exclude_prismatic:" + fid)
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"domain_count": domains.size(),
		"form_count": forms.size(),
		"HUMAN_ART_APPROVED": false,
		"choreography_is_human_art": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
	}


static func validate_production() -> Dictionary:
	var doc := load_doc()
	var failures: Array = []
	if doc.is_empty():
		failures.append("missing_presentation_doc")
	if not art_status_honest(doc):
		failures.append("art_status_not_honest")
	if bool(doc.get("WORKING_CANDIDATE", true)):
		failures.append("still_marked_working_candidate")
	var art: Dictionary = doc.get("art_status", {})
	if bool(art.get("cinematic_final_mix", true)):
		failures.append("cinematic_final_mix_must_stay_false")
	if bool(art.get("vfx_final_approved", true)):
		failures.append("vfx_final_must_stay_false")
	var mans: Dictionary = doc.get("manifestations", {})
	for need in [FORM_FAMILIAR, FORM_FIRST_BLOOM, FORM_EVERLASTING]:
		if not mans.has(need):
			failures.append("missing_manifestation:" + need)
		else:
			var row: Dictionary = mans[need]
			if str(row.get("pose_idle", "")).is_empty():
				failures.append("missing_pose:" + need)
			if str(row.get("aura_shape", "")).is_empty():
				failures.append("missing_aura:" + need)
			if str(row.get("vfx_motif", "")).is_empty():
				failures.append("missing_vfx:" + need)
			if str(row.get("transition_in_sfx", "")).is_empty():
				failures.append("missing_audio:" + need)
			if str(row.get("cinematic_expression", "")).is_empty():
				failures.append("missing_cinematic_expression:" + need)
			if str(row.get("camera_beat", "")).is_empty():
				failures.append("missing_camera_beat:" + need)
	if doc.get("transitions", []).size() < 3:
		failures.append("insufficient_transitions")
	var cinematic: Dictionary = doc.get("cinematic_presentation", {})
	if cinematic.is_empty():
		failures.append("missing_cinematic_presentation")
	elif bool(cinematic.get("HUMAN_ART_APPROVED", true)):
		failures.append("cinematic_human_art_must_stay_false")
	elif str(cinematic.get("status", "")).find("NOT_APPROVED") < 0:
		failures.append("cinematic_status_must_remain_honest")
	elif int(cinematic.get("beats", []).size()) < 3:
		failures.append("insufficient_cinematic_beats")
	if bool(doc.get("RC2_READY", true)) or bool(doc.get("V1_0_0_RELEASE_AUTHORIZED", true)):
		failures.append("release_gates_must_stay_false")
	var story_hooks: Dictionary = doc.get("story_hooks", {})
	var choreo: Dictionary = doc.get("choreography_stubs", {})
	for need in [FORM_FAMILIAR, FORM_FIRST_BLOOM, FORM_EVERLASTING]:
		if not story_hooks.has(need):
			failures.append("missing_story_hook:" + need)
		elif bool(story_hooks[need].get("HUMAN_ART_APPROVED", true)):
			failures.append("story_hook_human_art_must_stay_false:" + need)
		if not choreo.has(need):
			failures.append("missing_choreography_stub:" + need)
		elif bool(choreo[need].get("choreography_is_human_art", true)):
			failures.append("choreography_must_not_claim_human_art:" + need)
		elif bool(choreo[need].get("HUMAN_ART_APPROVED", true)):
			failures.append("choreography_human_art_must_stay_false:" + need)
	var hooks_doc := load_hooks_doc()
	if hooks_doc.is_empty():
		failures.append("missing_presentation_hooks_doc")
	elif str(hooks_doc.get("pink_revelation_node", "")) != "kaia-windrow:pink_revelation":
		failures.append("pink_revelation_node_mismatch")
	var cards: Dictionary = doc.get("presentation_cards", {})
	for need in [FORM_FAMILIAR, FORM_FIRST_BLOOM, FORM_EVERLASTING]:
		if not cards.has(need):
			failures.append("missing_presentation_card:" + need)
		elif bool(cards[need].get("HUMAN_ART_APPROVED", true)):
			failures.append("presentation_card_human_art_must_stay_false:" + need)
		elif bool(cards[need].get("choreography_is_human_art", true)):
			failures.append("presentation_card_choreo_must_not_claim_art:" + need)
	var honesty: Dictionary = validate_cosmology_honesty()
	if not bool(honesty.get("ok", false)):
		for f in honesty.get("failures", []):
			failures.append("honesty:" + str(f))
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"manifestation_count": mans.size(),
		"cinematic_beats": int(cinematic.get("beats", []).size()) if not cinematic.is_empty() else 0,
		"story_hooks": story_hooks.size(),
		"choreography_stubs": choreo.size(),
		"presentation_cards": cards.size(),
		"cosmology_honesty_ok": bool(honesty.get("ok", false)),
		"HUMAN_ART_APPROVED": false,
		"cel_shaded_glb": false,
		"cinematic_final_mix": false,
		"choreography_is_human_art": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
	}
