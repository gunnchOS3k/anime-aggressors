extends RefCounted
class_name PresentationContext

## Wave020 post-merge: immutable canonical asset → context-local instance → local wrapper/camera/material.

const CTX_SELECT_CARD := "SELECT_CARD"
const CTX_SELECT_PREVIEW := "SELECT_PREVIEW"
const CTX_VERSUS := "VERSUS"
const CTX_BATTLE_P1 := "BATTLE_P1"
const CTX_BATTLE_P2_CPU := "BATTLE_P2_CPU"
const CTX_BATTLE := "BATTLE"
const CTX_MOVE_PREVIEW := "MOVE_PREVIEW"
const CTX_VICTORY := "VICTORY"
const CTX_TRAINING := "TRAINING"

const BATTLE_DISPLAY_SCALE := Vector2(0.85, 0.85)
const SELECT_PREVIEW_DISPLAY_SCALE := Vector2(1.35, 1.35)
const MOVE_PREVIEW_DISPLAY_SCALE := Vector2(1.05, 1.05)
const VICTORY_DISPLAY_SCALE := Vector2(1.2, 1.2)
const SELECT_CARD_VIEWPORT := Vector2i(192, 240)
const DEFAULT_VIEWPORT := Vector2i(256, 320)
const MOVE_PREVIEW_VIEWPORT := Vector2i(240, 280)

const MAX_BATTLE_DISPLAY_SCALE := 1.05
const MAX_PREVIEW_DISPLAY_SCALE := 1.45
const MIN_MATERIAL_LUMA := 0.08


static func normalize_context(context: String) -> String:
	match context:
		"select_card":
			return CTX_SELECT_CARD
		"select_preview":
			return CTX_SELECT_PREVIEW
		"versus":
			return CTX_VERSUS
		"battle":
			return CTX_BATTLE
		"move_preview":
			return CTX_MOVE_PREVIEW
		"victory":
			return CTX_VICTORY
		"training":
			return CTX_TRAINING
		_:
			return context if not context.is_empty() else CTX_BATTLE


static func battle_context_for_slot(slot: int, is_cpu: bool) -> String:
	if is_cpu:
		return CTX_BATTLE_P2_CPU
	return CTX_BATTLE_P1 if slot == 1 else CTX_BATTLE_P2_CPU


static func cache_key(fighter_id: String, context: String) -> String:
	return "%s::%s" % [fighter_id, normalize_context(context)]


static func display_contract(context: String) -> Dictionary:
	var ctx := normalize_context(context)
	match ctx:
		CTX_SELECT_CARD:
			return {
				"context": ctx,
				"display_scale": Vector2(1.0, 1.0),
				"display_offset": Vector2.ZERO,
				"viewport_size": SELECT_CARD_VIEWPORT,
				"camera_size": 2.05,
				"allow_model_root_scale": false,
				"bake_only": true,
			}
		CTX_SELECT_PREVIEW, CTX_VERSUS:
			return {
				"context": ctx,
				"display_scale": SELECT_PREVIEW_DISPLAY_SCALE,
				"display_offset": Vector2(0, -28),
				"viewport_size": DEFAULT_VIEWPORT,
				"camera_size": 2.05,
				"allow_model_root_scale": false,
				"bake_only": false,
			}
		CTX_MOVE_PREVIEW:
			return {
				"context": ctx,
				"display_scale": MOVE_PREVIEW_DISPLAY_SCALE,
				"display_offset": Vector2(0, -20),
				"viewport_size": MOVE_PREVIEW_VIEWPORT,
				"camera_size": 2.15,
				"allow_model_root_scale": false,
				"bake_only": false,
			}
		CTX_VICTORY:
			return {
				"context": ctx,
				"display_scale": VICTORY_DISPLAY_SCALE,
				"display_offset": Vector2(0, -24),
				"viewport_size": SELECT_CARD_VIEWPORT,
				"camera_size": 2.25,
				"allow_model_root_scale": false,
				"bake_only": true,
			}
		CTX_TRAINING:
			return {
				"context": ctx,
				"display_scale": BATTLE_DISPLAY_SCALE,
				"display_offset": Vector2(0, -56),
				"viewport_size": DEFAULT_VIEWPORT,
				"camera_size": 2.55,
				"allow_model_root_scale": false,
				"bake_only": false,
			}
		_:
			return {
				"context": ctx,
				"display_scale": BATTLE_DISPLAY_SCALE,
				"display_offset": Vector2(0, -56),
				"viewport_size": DEFAULT_VIEWPORT,
				"camera_size": 2.55,
				"allow_model_root_scale": false,
				"bake_only": false,
			}


static func resolver_context(context: String) -> String:
	var ctx := normalize_context(context)
	match ctx:
		CTX_SELECT_CARD:
			return "select_card"
		CTX_SELECT_PREVIEW:
			return "select_preview"
		CTX_VERSUS:
			return "versus"
		CTX_MOVE_PREVIEW:
			return "move_preview"
		CTX_VICTORY:
			return "victory"
		CTX_TRAINING:
			return "battle"
		CTX_BATTLE_P1, CTX_BATTLE_P2_CPU, CTX_BATTLE:
			return "battle"
		_:
			return "battle"


static func contract_snapshot() -> Dictionary:
	var contexts: Array = [
		CTX_SELECT_CARD,
		CTX_SELECT_PREVIEW,
		CTX_VERSUS,
		CTX_BATTLE_P1,
		CTX_BATTLE_P2_CPU,
		CTX_MOVE_PREVIEW,
		CTX_VICTORY,
		CTX_TRAINING,
	]
	var out: Dictionary = {}
	for ctx in contexts:
		var c: Dictionary = display_contract(ctx)
		out[ctx] = {
			"display_scale": {"x": c.display_scale.x, "y": c.display_scale.y},
			"display_offset": {"x": c.display_offset.x, "y": c.display_offset.y},
			"viewport_size": {"w": c.viewport_size.x, "h": c.viewport_size.y},
			"camera_size": c.camera_size,
			"allow_model_root_scale": c.allow_model_root_scale,
			"bake_only": c.bake_only,
		}
	return out
