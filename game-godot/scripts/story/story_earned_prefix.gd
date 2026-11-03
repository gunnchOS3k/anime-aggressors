extends RefCounted
class_name StoryEarnedPrefix
## Earn sequential Story battle receipts through a bound BattleScene producer,
## then allow INTERACTIVE_DIALOGUE acknowledgments that survive authenticated reload.
## Staged producer fixture — not a human playthrough / owner sign-off / V1 claim.
## Does not touch HitResolver ownership or shipping rollback.

static func wait_route(tree: SceneTree, suffix: String, limit: int = 240) -> bool:
	for _i in range(limit):
		await tree.process_frame
		var scene = tree.current_scene
		if scene != null and str(scene.scene_file_path).ends_with(suffix):
			await tree.process_frame
			return true
	return false


static func earn_stock_win_via_bound_battle(tree: SceneTree, campaign: Node, router: Node) -> Dictionary:
	## begin_encounter must already be active. Loads BattleScene, binds producer,
	## records STOCK_WIN while combat is closed (_active == false) — same ownership
	## boundary as StorySaveRecovery, but winner=1 with stock_win evidence.
	if campaign.active_encounter.is_empty():
		return {"ok": false, "reason": "no_active_encounter"}
	var token: String = str(campaign.active_encounter.get("token", ""))
	var node_id: String = str(campaign.active_encounter.get("node_id", ""))
	router.go("battle")
	if not await wait_route(tree, "BattleScene.tscn"):
		return {"ok": false, "reason": "battle_scene_missing", "node_id": node_id}
	var battle = tree.current_scene
	var dialogue = tree.root.get_node_or_null("StoryDialogue")
	if dialogue != null and dialogue.has_method("skip_all"):
		dialogue.skip_all()
	for _i in range(120):
		await tree.process_frame
		if campaign._battle_producer == battle:
			break
	if campaign._battle_producer != battle:
		return {"ok": false, "reason": "battle_not_bound", "node_id": node_id}
	## Closed-boundary fixture: countdown / pre-active ownership (not mid-fight forge).
	if bool(battle.get("_active")):
		battle.set("_active", false)
	if battle.get("fighter1") != null:
		battle.fighter1.stocks = 2
	if battle.get("fighter2") != null:
		battle.fighter2.stocks = 0
	var evidence := {"stock_win": true, "staged_producer_fixture": true, "human_playthrough": false}
	var ok: bool = campaign.record_battle_result(1, token, evidence, battle)
	return {
		"ok": ok,
		"node_id": node_id,
		"advanced": bool(campaign.last_result.get("advanced", false)),
		"token": token,
		"staged_producer_fixture": true,
		"human_playthrough": false,
		"error": campaign.last_error,
	}


static func advance_to_dialogue(tree: SceneTree, campaign: Node, router: Node, route_id: String = "", max_battles: int = 12) -> Dictionary:
	## Earn STOCK_WIN battles until current node is INTERACTIVE_DIALOGUE (or exhaust).
	var selected := route_id if not route_id.is_empty() else str(campaign.progress.get("selected_route", "kaia-windrow"))
	if str(campaign.progress.get("selected_route", "")) != selected and campaign.has_method("select_route"):
		campaign.select_route(selected)
	var earned: Array = []
	for _i in range(max_battles):
		var node: Dictionary = campaign.current_node()
		if node.is_empty():
			return {"ok": false, "reason": "empty_node", "earned": earned}
		var kind := str(node.get("kind", ""))
		var nid := str(node.get("id", ""))
		if kind == "INTERACTIVE_DIALOGUE":
			return {"ok": true, "dialogue_id": nid, "earned": earned, "human_playthrough": false}
		if kind != "STORY_BATTLE":
			return {"ok": false, "reason": "unexpected_kind:" + kind, "earned": earned}
		if not campaign.begin_encounter():
			return {"ok": false, "reason": "begin_failed:" + nid, "earned": earned}
		var result: Dictionary = await earn_stock_win_via_bound_battle(tree, campaign, router)
		if not bool(result.get("ok", false)) or not bool(result.get("advanced", false)):
			return {"ok": false, "reason": "earn_failed:" + nid, "detail": result, "earned": earned}
		earned.append(nid)
		## Leave Results / battle ownership for the next begin.
		if router.has_method("go"):
			router.go("story")
			await wait_route(tree, "StoryCampaignScene.tscn", 180)
		campaign.last_result.clear()
	return {"ok": false, "reason": "dialogue_not_reached", "earned": earned}


static func acknowledge_and_reload(campaign: Node, dialogue_id: String, route_id: String) -> Dictionary:
	if not campaign.acknowledge_scene(dialogue_id, route_id):
		return {"ok": false, "reason": "acknowledge_failed", "error": campaign.last_error}
	if dialogue_id not in campaign.progress.routes[route_id].completed:
		return {"ok": false, "reason": "not_in_completed"}
	if not campaign.save_progress():
		return {"ok": false, "reason": "save_failed", "error": campaign.last_error}
	campaign.load_progress()
	var durable: bool = dialogue_id in campaign.progress.routes[route_id].completed
	return {
		"ok": durable,
		"dialogue_id": dialogue_id,
		"durable_after_reload": durable,
		"earned_prefix_required": true,
		"owner_sign_off": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
	}
