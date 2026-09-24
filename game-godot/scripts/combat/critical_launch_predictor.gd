extends RefCounted
class_name CriticalLaunchPredictor

## Presentation-only launch-danger predictor. Never mutates gameplay state.

const TIER_SAFE := "SAFE"
const TIER_DANGEROUS := "DANGEROUS"
const TIER_CRITICAL_RECOVERABLE := "CRITICAL_RECOVERABLE"
const TIER_NEAR_CERTAIN_KO := "NEAR_CERTAIN_KO"

const GRAVITY := 1800.0
const DT := 1.0 / 60.0
const MAX_STEPS := 240
const RECOVERY_JUMP_IMPULSE := 620.0
const AIR_CONTROL_BUDGET := 280.0
const LOW_KB := 8.0
const HIGH_KB := 14.0

const DEFAULT_BLAST := {
	"left": -582.0,
	"right": 582.0,
	"top": -378.0,
	"bottom": 420.0,
}


static func evaluate(inputs: Dictionary) -> Dictionary:
	var pos: Vector2 = inputs.get("position", Vector2.ZERO)
	var vel: Vector2 = inputs.get("launch_velocity", Vector2.ZERO)
	var blast: Dictionary = inputs.get("blast_zones", DEFAULT_BLAST)
	var jumps := int(inputs.get("remaining_jumps", 1))
	var recovery_ready := bool(inputs.get("recovery_ready", true))
	var hitstun := float(inputs.get("hitstun_sec", 0.2))
	var already_dead := bool(inputs.get("already_past_blast", false))
	var snapshot := {
		"position": pos,
		"launch_velocity": vel,
		"remaining_jumps": jumps,
		"recovery_ready": recovery_ready,
		"hitstun_sec": hitstun,
	}
	if already_dead:
		return _pack(TIER_SAFE, "already_dead_no_retrigger", snapshot, vel, false, false)
	var kb := vel.length()
	if kb < LOW_KB:
		return _pack(TIER_SAFE, "tiny_launch", snapshot, vel, false, false)
	var passive := _simulate(pos, vel, blast, 0, false, hitstun)
	var recovered := _simulate(pos, vel, blast, jumps, recovery_ready, hitstun)
	var tier := TIER_SAFE
	var reason := "inside_envelope"
	if not bool(passive.get("crosses_blast", false)):
		if bool(passive.get("near_blast", false)) and kb >= HIGH_KB:
			tier = TIER_DANGEROUS
			reason = "approaches_blast_but_safe"
		else:
			tier = TIER_SAFE
			reason = "passive_stays_in"
	elif bool(recovered.get("crosses_blast", false)) and (jumps <= 0 and not recovery_ready):
		tier = TIER_NEAR_CERTAIN_KO
		reason = "blast_and_no_recovery"
	elif bool(recovered.get("saved", false)) or jumps > 0 or recovery_ready:
		tier = TIER_CRITICAL_RECOVERABLE
		reason = "passive_ko_recovery_plausible"
	else:
		tier = TIER_NEAR_CERTAIN_KO
		reason = "blast_recovery_implausible"
	var out := _pack(tier, reason, snapshot, vel, bool(passive.get("crosses_blast", false)), bool(recovered.get("saved", false)))
	out["passive"] = passive
	out["recovered"] = recovered
	# Invariant: output never writes back into caller gameplay fields.
	out["mutates_gameplay"] = false
	out["snapshot_unchanged"] = (
		snapshot["position"] == pos
		and snapshot["launch_velocity"] == vel
		and int(snapshot["remaining_jumps"]) == jumps
	)
	return out


static func trail_tier(pred: Dictionary, kb: float) -> String:
	var danger := str(pred.get("tier", TIER_SAFE))
	if danger == TIER_NEAR_CERTAIN_KO:
		return "CRITICAL"
	if danger == TIER_CRITICAL_RECOVERABLE:
		return "CRITICAL"
	if danger == TIER_DANGEROUS or kb >= HIGH_KB:
		return "HIGH"
	if kb >= LOW_KB:
		return "MEDIUM"
	return "LOW"


static func _simulate(
	start: Vector2,
	launch: Vector2,
	blast: Dictionary,
	jumps: int,
	recovery_ready: bool,
	hitstun: float
) -> Dictionary:
	var pos := start
	var vel := launch
	var jumps_left := jumps
	var crossed := false
	var near := false
	var saved := false
	var t := 0.0
	var left := float(blast.get("left", DEFAULT_BLAST.left))
	var right := float(blast.get("right", DEFAULT_BLAST.right))
	var top := float(blast.get("top", DEFAULT_BLAST.top))
	var bottom := float(blast.get("bottom", DEFAULT_BLAST.bottom))
	for _i in MAX_STEPS:
		t += DT
		vel.y += GRAVITY * DT
		if t >= hitstun:
			if jumps_left > 0 and pos.y > bottom - 80.0 and vel.y > 40.0:
				vel.y = -RECOVERY_JUMP_IMPULSE
				jumps_left -= 1
			elif recovery_ready and _outside_stage_x(pos.x, left, right) and vel.y > 20.0:
				vel.x += (-1.0 if pos.x > 0.0 else 1.0) * AIR_CONTROL_BUDGET * DT
				if jumps_left <= 0:
					vel.y -= RECOVERY_JUMP_IMPULSE * 0.35 * DT * 8.0
					recovery_ready = false
		pos += vel * DT
		if _near_blast(pos, left, right, top, bottom):
			near = true
		if _past_blast(pos, left, right, top, bottom):
			crossed = true
			break
		if pos.y >= 280.0 and absf(pos.x) < 520.0 and vel.y > 0.0 and t > hitstun:
			saved = true
			break
	if not crossed and near == false and t >= float(MAX_STEPS) * DT:
		saved = true
	return {
		"crosses_blast": crossed,
		"near_blast": near,
		"saved": saved and not crossed,
		"end": {"x": pos.x, "y": pos.y},
		"seconds": t,
	}


static func _past_blast(pos: Vector2, left: float, right: float, top: float, bottom: float) -> bool:
	return pos.x < left or pos.x > right or pos.y < top or pos.y > bottom


static func _near_blast(pos: Vector2, left: float, right: float, top: float, bottom: float) -> bool:
	return (
		pos.x < left + 64.0
		or pos.x > right - 64.0
		or pos.y < top + 64.0
		or pos.y > bottom - 48.0
	)


static func _outside_stage_x(x: float, left: float, right: float) -> bool:
	return x < left + 140.0 or x > right - 140.0


static func _pack(tier: String, reason: String, snapshot: Dictionary, vel: Vector2, blast: bool, saved: bool) -> Dictionary:
	return {
		"tier": tier,
		"reason": reason,
		"kb": vel.length(),
		"crosses_blast_passively": blast,
		"recovery_plausible": saved or tier == TIER_CRITICAL_RECOVERABLE,
		"inputs_snapshot": snapshot.duplicate(true),
	}
