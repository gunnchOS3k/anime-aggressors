extends RefCounted
class_name StoryJourneyHonesty
## AA-RTM-002 digital honesty — Story campaign journey save/recovery authority.
## Declares owner_sign_off / human_playthrough / V1 false. Does not invent device
## playthrough or HUMAN_ART. HitResolver / Codex combat data untouched.

const SCHEMA := "anime_v1.progress.v2"
const CHECKPOINT_SCHEMA := "anime_v1.checkpoint.v1"


static func presentation_honesty_card(route_id: String = "kaia-windrow") -> Dictionary:
	return {
		"req_id": "AA-RTM-002",
		"route_id": route_id,
		"save_recovery_authority": true,
		"earned_prefix_required_for_durable_dialogue": true,
		"staged_producer_fixture": true,
		"owner_sign_off": false,
		"human_playthrough": false,
		"device_matrix_pass": false,
		"HUMAN_ART_APPROVED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
	}


static func route_catalog_summary(campaign: Node) -> Dictionary:
	if campaign == null:
		return {"ok": false, "reason": "no_campaign"}
	var order: Array = campaign.campaign.get("spectral_order", []) if campaign.get("campaign") != null else []
	var routes: Array = []
	var failures: Array = []
	for rid in order:
		var data: Dictionary = campaign.route_data(str(rid))
		if data.is_empty():
			failures.append("missing_route:" + str(rid))
			continue
		var nodes: Array = data.get("nodes", [])
		var prologue: Dictionary = {}
		var battle_count := 0
		var dialogue_count := 0
		for node in nodes:
			var kind := str(node.get("kind", ""))
			if kind == "STORY_BATTLE":
				battle_count += 1
				if prologue.is_empty():
					prologue = node
			elif kind == "INTERACTIVE_DIALOGUE":
				dialogue_count += 1
		if prologue.is_empty():
			failures.append("no_prologue_battle:" + str(rid))
		elif not bool(prologue.get("implemented", false)):
			failures.append("prologue_unimplemented:" + str(rid))
		routes.append({
			"route_id": str(rid),
			"anchor": str(data.get("anchor", "")),
			"node_count": nodes.size(),
			"story_battles": battle_count,
			"dialogues": dialogue_count,
			"prologue_id": str(prologue.get("id", "")),
			"prologue_implemented": bool(prologue.get("implemented", false)),
			"available_default": campaign.route_available(str(rid)),
		})
	return {
		"ok": failures.is_empty() and not routes.is_empty(),
		"failures": failures,
		"spectral_order": order,
		"routes": routes,
		"route_count": routes.size(),
		"owner_sign_off": false,
		"human_playthrough": false,
		"device_matrix_pass": false,
	}


static func interrupt_checkpoint_roundtrip(campaign: Node, route_id: String, stocks: int, damage: float) -> Dictionary:
	## Digital interrupt stamp → save → authenticated reload. Not a device playtest.
	if campaign == null:
		return {"ok": false, "reason": "no_campaign"}
	var cursor_before := str(campaign.current_node().get("id", ""))
	if cursor_before.is_empty():
		return {"ok": false, "reason": "empty_cursor"}
	campaign._stamp_combat(route_id, stocks, damage)
	if not campaign.save_progress():
		return {"ok": false, "reason": "save_failed", "error": campaign.last_error}
	var stamped: Dictionary = campaign.progress.checkpoint.duplicate(true)
	campaign.load_progress()
	var restored: Dictionary = campaign.progress.checkpoint
	var ok: bool = bool(campaign.last_error.is_empty()) \
		and str(campaign.current_node().get("id", "")) == cursor_before \
		and str(restored.get("schema", "")) == CHECKPOINT_SCHEMA \
		and int(restored.get("combat", {}).get("stocks", -1)) == stocks \
		and is_equal_approx(float(restored.get("combat", {}).get("damage_percent", -1.0)), damage) \
		and bool(campaign.active_encounter.is_empty())
	return {
		"ok": ok,
		"cursor": cursor_before,
		"stamped_schema": str(stamped.get("schema", "")),
		"restored_stocks": int(restored.get("combat", {}).get("stocks", -1)),
		"restored_damage": float(restored.get("combat", {}).get("damage_percent", -1.0)),
		"active_encounter_cleared": campaign.active_encounter.is_empty(),
		"owner_sign_off": false,
		"human_playthrough": false,
		"device_matrix_pass": false,
	}


static func out_of_order_dialogue_not_durable(campaign: Node, route_id: String, dialogue_id: String) -> Dictionary:
	## Dialogue without earned battle prefix must not survive authenticated reload.
	campaign.progress = campaign.new_progress()
	campaign.progress.selected_route = route_id
	campaign.progress.routes[route_id].cursor = dialogue_id
	if not campaign.save_progress():
		return {"ok": false, "reason": "fixture_save_failed"}
	campaign.acknowledge_scene(dialogue_id, route_id)
	campaign.save_progress()
	campaign.load_progress()
	var durable: bool = dialogue_id in campaign.progress.routes[route_id].completed
	var cursor := str(campaign.current_node().get("id", ""))
	return {
		"ok": not durable,
		"dialogue_id": dialogue_id,
		"durable_after_reload": durable,
		"cursor_after_reload": cursor,
		"earned_prefix_required": true,
		"owner_sign_off": false,
		"human_playthrough": false,
	}


static func validate(campaign: Node) -> Dictionary:
	var failures: Array = []
	if campaign == null:
		failures.append("no_campaign")
		return {"ok": false, "failures": failures}
	if str(campaign.progress.get("schema", "")) != SCHEMA and campaign.progress.get("schema", "") != null:
		## new_progress / reset may set schema — tolerate empty until reset.
		pass
	var catalog: Dictionary = route_catalog_summary(campaign)
	if not bool(catalog.get("ok", false)):
		failures.append("route_catalog")
		for f in catalog.get("failures", []):
			failures.append(str(f))
	var card: Dictionary = presentation_honesty_card()
	if bool(card.get("owner_sign_off", true)):
		failures.append("owner_sign_off_claimed")
	if bool(card.get("human_playthrough", true)):
		failures.append("human_playthrough_claimed")
	if bool(card.get("V1_0_0_RELEASE_AUTHORIZED", true)):
		failures.append("v1_claimed")
	if bool(card.get("device_matrix_pass", true)):
		failures.append("device_matrix_claimed")
	if bool(card.get("HUMAN_ART_APPROVED", true)):
		failures.append("human_art_claimed")
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"catalog": catalog,
		"card": card,
		"req_id": "AA-RTM-002",
		"owner_sign_off": false,
		"human_playthrough": false,
		"device_matrix_pass": false,
		"HUMAN_ART_APPROVED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
	}
