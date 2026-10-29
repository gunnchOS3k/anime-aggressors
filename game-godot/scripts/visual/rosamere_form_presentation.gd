extends RefCounted
## Rosamere three-form presentation production hooks (poses / VFX / audio / transitions).
## Honest art_status: runtime hooks authored; cel-shaded GLB and human final art NOT approved.
## COMPETITIVE_SELF_LIMITED is never a fourth form presentation.

const DOC_PATH := "res://data/story/rosamere_three_form_presentation_production.json"
const Selection = preload("res://scripts/combat/rosamere_form_selection.gd")
const Sfx = preload("res://scripts/audio/v1_candidate_sfx.gd")

const FORM_FAMILIAR := "FAMILIAR_ROSE"
const FORM_FIRST_BLOOM := "FIRST_BLOOM"
const FORM_EVERLASTING := "EVERLASTING_ORIGIN"


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
	if fighter.has_method("set_meta"):
		fighter.set_meta("rosamere_presentation", presentation)
		fighter.set_meta("rosamere_presentation_production", "RUNTIME_HOOKS_AUTHORED_FINAL_ART_NOT_APPROVED")
	## Caller owns apply_form / Pink form authority; this module only presents.
	_play_transition(fighter, previous_form, resolved, presentation)
	_apply_model_presentation(fighter, presentation)
	return {
		"ok": true,
		"form_id": resolved,
		"presentation": presentation,
		"art_status": "THREE_FORM_PRESENTATION_PRODUCTION_IN_PROGRESS",
		"HUMAN_ART_APPROVED": false,
		"cel_shaded_glb": false,
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
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"manifestation_count": mans.size(),
		"cinematic_beats": int(cinematic.get("beats", []).size()) if not cinematic.is_empty() else 0,
		"HUMAN_ART_APPROVED": false,
		"cel_shaded_glb": false,
		"cinematic_final_mix": false,
	}
