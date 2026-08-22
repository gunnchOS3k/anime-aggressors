extends RefCounted
class_name CompetitiveRules

## Canonical competitive ruleset for Anime Aggressors (stock platform fighter).
## Not a parallel combat engine — configuration applied to GameState + BattleScene.

const STOCKS := 3
const TIMER_SECONDS := 180
const MATCH_TYPE := "stock"
const ITEMS_ENABLED := false
const HAZARDS_ENABLED := false
const HIDDEN_RUBBER_BANDING := false
const FORCED_FINISH_ORDER := false
const TEAM_ATTACK := false
const DAMAGE_RATIO := 1.0
const RULESET_ID := "competitive-stock-3"

## Debug / training overlays must not appear on a clean competitive HUD.
const COMPETITIVE_DEBUG_HUD := false
const TRAINING_DEBUG_HUD := true


static func is_competitive_mode(mode: String) -> bool:
	return mode in ["versus", "arcade", "online_unranked", "online_ranked", "tournament", "cpu_eval", ""]


static func apply_to_gamestate(gs: Object) -> void:
	if gs == null:
		return
	gs.stocks = STOCKS
	gs.match_timer_seconds = TIMER_SECONDS
	gs.match_type = MATCH_TYPE
	gs.items_enabled = ITEMS_ENABLED
	gs.hazards_enabled = HAZARDS_ENABLED
	gs.team_attack = TEAM_ATTACK
	gs.damage_ratio = DAMAGE_RATIO
	gs.ruleset_id = RULESET_ID
	if "debug_combat_hud" in gs:
		gs.debug_combat_hud = COMPETITIVE_DEBUG_HUD


static func summary() -> Dictionary:
	return {
		"stocks": STOCKS,
		"timer_seconds": TIMER_SECONDS,
		"match_type": MATCH_TYPE,
		"items_enabled": ITEMS_ENABLED,
		"hazards_enabled": HAZARDS_ENABLED,
		"HIDDEN_RUBBER_BANDING": HIDDEN_RUBBER_BANDING,
		"FORCED_FINISH_ORDER": FORCED_FINISH_ORDER,
		"team_attack": TEAM_ATTACK,
		"damage_ratio": DAMAGE_RATIO,
		"ruleset_id": RULESET_ID,
		"competitive_debug_hud": COMPETITIVE_DEBUG_HUD,
	}


static func show_debug_hud(gs: Object) -> bool:
	if gs == null:
		return false
	if str(gs.mode) == "training":
		return TRAINING_DEBUG_HUD
	if "debug_combat_hud" in gs and bool(gs.debug_combat_hud):
		return true
	return false
