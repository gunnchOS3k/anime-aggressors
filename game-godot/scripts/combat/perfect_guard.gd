extends RefCounted
class_name PerfectGuard
## Owner-directed tuning candidate. Fixed simulation frames, identical for every
## fighter/form. No reflection, invulnerability, damage or grab interception.
const WINDOW_FRAMES := 4
const REARM_FRAMES := 24
var clock := 0
var opened := -1000
var next_attempt := 0
var consumed := true
var history: Array = []
var fighter
func setup(actor) -> void: fighter = actor
func reset() -> void:
	opened = -1000; next_attempt = clock; consumed = true
func tick() -> void: clock += 1
func begin() -> bool:
	if clock < next_attempt: return false
	opened = clock + 1
	next_attempt = opened + REARM_FRAMES
	consumed = false
	return true
func try_contact(attacker, move: Dictionary) -> Dictionary:
	var age := clock - opened
	if consumed or age < 0 or age >= WINDOW_FRAMES: return {}
	if not fighter.shielding or not fighter.is_on_floor() or fighter.grabbed_by != null: return {}
	var kind := str(move.get("move_type", ""))
	var mid := str(move.get("move_id", ""))
	if kind in ["grab", "throw"] or mid == "grab" or mid.begins_with("throw_") or bool(move.get("unblockable", false)): return {}
	consumed = true
	var info := {"damage":0.0,"launch":Vector2.ZERO,"shield_damage":0.0,"blocked":true,
		"perfect_guard":true,"guard_age_frames":age,"guard_window_frames":WINDOW_FRAMES,
		"move_id":mid,"hitstop_frames":2,"element":move.get("element_effect",{}).get("type","")}
	fighter._hitstop = 2.0 / 60.0
	if not bool(move.get("_from_projectile",false)): attacker._hitstop = maxf(attacker._hitstop,6.0/60.0)
	history.append({"clock":clock,"age":age,"move":mid,"projectile":bool(move.get("_from_projectile",false))})
	if history.size()>64: history.pop_front()
	return info
func snapshot() -> Dictionary:
	return {"clock":clock,"opened":opened,"consumed":consumed,"next_attempt":next_attempt,"window_frames":WINDOW_FRAMES,"status":"TUNING_CANDIDATE"}
