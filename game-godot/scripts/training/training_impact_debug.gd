extends RefCounted
class_name TrainingImpactDebug

## Extends existing training/debug HUD. Not a second debug system.

const _HitReaction = preload("res://scripts/combat/hit_reaction_resolver.gd")
const _Impact = preload("res://scripts/combat/impact_profile_resolver.gd")

const TIERS := ["light", "medium", "heavy", "aura", "super", "ko"]
const PERCENTS := [0.0, 30.0, 60.0, 90.0, 120.0, 150.0]
const AURA_STEPS := [0.0, 25.0, 50.0, 75.0, 100.0]


static func bind_game_state() -> void:
	var gs = _gs()
	if gs == null:
		return
	if not ("training_force_hit_tier" in gs):
		return
	if str(gs.training_force_hit_tier) == "":
		gs.training_force_hit_tier = ""
	if str(gs.training_force_reaction) == "":
		gs.training_force_reaction = ""


static func cycle_tier() -> String:
	var gs = _gs()
	if gs == null:
		return ""
	var cur := str(gs.training_force_hit_tier)
	var idx := TIERS.find(cur)
	idx = (idx + 1) % TIERS.size()
	gs.training_force_hit_tier = TIERS[idx]
	return TIERS[idx]


static func set_tier(tier: String) -> String:
	var gs = _gs()
	if gs == null:
		return ""
	if tier in TIERS:
		gs.training_force_hit_tier = tier
	return str(gs.training_force_hit_tier)


static func cycle_reaction() -> String:
	var gs = _gs()
	if gs == null:
		return ""
	var fams: Array = _HitReaction.families()
	if fams.is_empty():
		return ""
	var cur := str(gs.training_force_reaction)
	var idx := fams.find(cur)
	idx = (idx + 1) % fams.size()
	gs.training_force_reaction = str(fams[idx])
	return str(fams[idx])


static func cycle_percent(fighter) -> float:
	if fighter == null:
		return 0.0
	var cur := float(fighter.damage_percent)
	var idx := 0
	for i in PERCENTS.size():
		if is_equal_approx(cur, PERCENTS[i]):
			idx = i
			break
		if cur < PERCENTS[i]:
			idx = i
			break
	idx = (idx + 1) % PERCENTS.size()
	fighter.damage_percent = PERCENTS[idx]
	return PERCENTS[idx]


static func cycle_aura(fighter) -> float:
	if fighter == null:
		return 0.0
	var gs = _gs()
	var cur := float(fighter.aura)
	var idx := 0
	for i in AURA_STEPS.size():
		if is_equal_approx(cur, AURA_STEPS[i]):
			idx = i
			break
	idx = (idx + 1) % AURA_STEPS.size()
	fighter.aura = AURA_STEPS[idx]
	if gs != null:
		gs.training_aura_threshold = AURA_STEPS[idx]
	return AURA_STEPS[idx]


static func toggle_camera() -> bool:
	var gs = _gs()
	if gs == null:
		return true
	gs.training_camera_enabled = not bool(gs.training_camera_enabled)
	return bool(gs.training_camera_enabled)


static func toggle_vfx() -> bool:
	var gs = _gs()
	if gs == null:
		return true
	gs.training_vfx_enabled = not bool(gs.training_vfx_enabled)
	return bool(gs.training_vfx_enabled)


static func toggle_sfx() -> bool:
	var gs = _gs()
	if gs == null:
		return true
	gs.training_sfx_enabled = not bool(gs.training_sfx_enabled)
	return bool(gs.training_sfx_enabled)


static func toggle_hide_hud() -> bool:
	var gs = _gs()
	if gs == null:
		return false
	gs.training_hide_hud = not bool(gs.training_hide_hud)
	return bool(gs.training_hide_hud)


static func remember_hit(attacker, defender, move: Dictionary, info: Dictionary) -> void:
	var gs = _gs()
	if gs == null:
		return
	gs.training_last_hit = {
		"attacker_slot": attacker.slot if attacker != null and "slot" in attacker else 1,
		"defender_slot": defender.slot if defender != null and "slot" in defender else 2,
		"move": move.duplicate(true),
		"info": info.duplicate(true),
	}


static func replay_last_hit(fighter1, fighter2) -> bool:
	var gs = _gs()
	if gs == null:
		return false
	var last: Dictionary = gs.training_last_hit
	if last.is_empty():
		return false
	var attacker = fighter1 if int(last.get("attacker_slot", 1)) == 1 else fighter2
	var defender = fighter2 if int(last.get("defender_slot", 2)) == 2 else fighter1
	if attacker == null or defender == null or attacker.hit_resolver == null:
		return false
	var move: Dictionary = last.get("move", {})
	attacker.hit_resolver.resolve(attacker, defender, move, attacker.damage_percent)
	return true


static func help_suffix() -> String:
	return " | 1-6 tier R replay P% A aura V reaction C cam X vfx Z sfx H hideHUD"


static func controls_present_in(help: String) -> bool:
	return help.contains("F11 freeze") and help.contains("F12 step") and help.contains("replay")


static func _gs() -> Variant:
	if Engine.get_main_loop() == null:
		return null
	return Engine.get_main_loop().root.get_node_or_null("/root/GameState")
