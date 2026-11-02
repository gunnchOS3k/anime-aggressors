extends RefCounted
class_name StagePresentation
## Stage presentation honesty cards — layout playable ≠ HUMAN_ART / commercial art.
## Presentation-only; does not rewrite Codex HitResolver / combat data / rollback.

const StageManagerScript = preload("res://scripts/battle/stage_manager.gd")

const HONEST_ART_STATUSES := [
	"PROCEDURAL_WORKING_NOT_HUMAN_FINAL",
	"AUTHORED_LAYOUT_NOT_HUMAN_FINAL",
	"PLACEHOLDER_GEOMETRY",
	"SCAFFOLD_PROCEDURAL",
	"NOT_AUTHORED_THIS_PASS",
]


static func presentation_honesty_card(stage_id: String = "") -> Dictionary:
	return {
		"req_ids": ["AA-RTM-002", "AA-RTM-003", "AA-RTM-004"],
		"surface": "stages_presentation",
		"stage_id": stage_id,
		"layout_playable_neq_human_art": true,
		"registry_count_neq_commercial_completion": true,
		"HUMAN_ART_APPROVED": false,
		"device_matrix_pass": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
	}


static func card_for_stage(stage_id: String, stage_data: Dictionary = {}) -> Dictionary:
	var data: Dictionary = stage_data
	if data.is_empty():
		var mgr = StageManagerScript.new()
		data = mgr.load_stage_data(stage_id)
	var art := str(data.get("artStatus", data.get("art_status", "")))
	var card: Dictionary = presentation_honesty_card(stage_id)
	card["display_name"] = str(data.get("displayName", stage_id))
	card["productionStatus"] = str(data.get("productionStatus", ""))
	card["geometryStatus"] = str(data.get("geometryStatus", ""))
	card["artStatus"] = art
	card["playable"] = bool(data.get("playable", false))
	card["pink_foreshadow"] = data.get("pink_foreshadow", {})
	card["yin_yang_presence"] = data.get("yin_yang_presence", {})
	card["preview_is_human_art"] = false
	card["previewPlaceholder"] = str(data.get("previewPlaceholder", ""))
	## Explicit honesty: never promote layout playable to art approval.
	card["HUMAN_ART_APPROVED"] = false
	if bool(data.get("HUMAN_ART_APPROVED", false)):
		card["dishonest_source_art_flag"] = true
	return card


static func registry_presentation_contract() -> Dictionary:
	var mgr = StageManagerScript.new()
	var summary: Dictionary = mgr.load_registry()
	var failures: Array = []
	var cards: Array = []
	var playable: Array = summary.get("playable_expanded", [])
	if int(summary.get("expanded_count", 0)) != 30:
		failures.append("expanded_not_30")
	if playable.size() != 30:
		failures.append("playable_not_30")
	if (summary.get("registered_pending", []) as Array).size() != 0:
		failures.append("unexpected_pending")
	if bool(summary.get("HUMAN_ART_APPROVED", true)):
		failures.append("summary_art_claimed")
	if not bool(summary.get("canonical_launch_preserved", false)):
		failures.append("launch_six_not_preserved")
	for stage_id in playable:
		## Registry playable is authoritative; some batch1 JSON omit playable=true.
		var card: Dictionary = card_for_stage(str(stage_id))
		card["playable"] = true
		card["registry_playable"] = true
		cards.append(card)
		if bool(card.get("HUMAN_ART_APPROVED", true)):
			failures.append("art_claimed:" + str(stage_id))
		if bool(card.get("dishonest_source_art_flag", false)):
			failures.append("source_art_true:" + str(stage_id))
		if not mgr.is_playable(str(stage_id)):
			failures.append("not_playable:" + str(stage_id))
		var art := str(card.get("artStatus", ""))
		if art.is_empty():
			failures.append("missing_art_status:" + str(stage_id))
		elif art.find("HUMAN_FINAL") >= 0 and art.find("NOT_HUMAN") < 0:
			failures.append("art_status_implies_final:" + str(stage_id))
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"expanded_count": int(summary.get("expanded_count", 0)),
		"playable_count": playable.size(),
		"pending_count": (summary.get("registered_pending", []) as Array).size(),
		"canonical_launch_preserved": bool(summary.get("canonical_launch_preserved", false)),
		"cards": cards,
		"layout_playable_neq_human_art": true,
		"HUMAN_ART_APPROVED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
	}
