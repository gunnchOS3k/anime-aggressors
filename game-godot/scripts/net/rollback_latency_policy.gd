extends RefCounted
class_name RollbackLatencyPolicy

## Rollback + latency policy for private online (scaffold).
## Tunables only — does not claim production netcode readiness.

const ALPHA_CLAIM := "PRIVATE_LOOPBACK_ONLY — rollback/latency policy"

## Input delay (frames) applied before local input is considered committed.
@export var input_delay_frames: int = 2
## Maximum frames the session may roll back on late remote input.
@export var max_rollback_frames: int = 8
## Frame advantage clamp (positive = local ahead).
@export var max_frame_advantage: int = 3
## Snapshot interval for checksum compares.
@export var checksum_interval_frames: int = 30
## Time sync: prefer delay increase when RTT exceeds this (ms).
@export var rtt_delay_step_ms: float = 90.0
## Hard disconnect / stall threshold.
@export var stall_timeout_ms: float = 3500.0


func configure(delay: int = 2, max_rb: int = 8, advantage: int = 3) -> void:
	input_delay_frames = clampi(delay, 0, 8)
	max_rollback_frames = clampi(max_rb, 1, 16)
	max_frame_advantage = clampi(advantage, 1, 6)


func recommend_delay_for_rtt(rtt_ms: float) -> int:
	## Simple step policy: +1 delay per rtt_delay_step_ms beyond base.
	var base := 2
	if rtt_ms <= 40.0:
		return base
	var steps: int = int(floor((rtt_ms - 40.0) / rtt_delay_step_ms))
	return clampi(base + steps, 2, 6)


func should_stall(local_frame: int, remote_confirmed: int, rtt_ms: float) -> bool:
	var advantage: int = local_frame - remote_confirmed
	if advantage > max_frame_advantage + input_delay_frames:
		return true
	if rtt_ms >= stall_timeout_ms:
		return true
	return false


func can_rollback(to_frame: int, current_frame: int) -> bool:
	if to_frame > current_frame:
		return false
	return (current_frame - to_frame) <= max_rollback_frames


func next_checksum_frame(frame: int) -> bool:
	if checksum_interval_frames <= 0:
		return false
	return frame > 0 and frame % checksum_interval_frames == 0


func as_dict() -> Dictionary:
	return {
		"input_delay_frames": input_delay_frames,
		"max_rollback_frames": max_rollback_frames,
		"max_frame_advantage": max_frame_advantage,
		"checksum_interval_frames": checksum_interval_frames,
		"rtt_delay_step_ms": rtt_delay_step_ms,
		"stall_timeout_ms": stall_timeout_ms,
		"alpha_claim": ALPHA_CLAIM,
	}


static func self_test() -> Dictionary:
	var ScriptRef = load("res://scripts/net/rollback_latency_policy.gd")
	var p = ScriptRef.new()
	p.configure(2, 8, 3)
	var d40: int = p.recommend_delay_for_rtt(40.0)
	var d200: int = p.recommend_delay_for_rtt(200.0)
	var ok: bool = d40 == 2 and d200 > d40
	ok = ok and p.can_rollback(10, 16) and not p.can_rollback(10, 20)
	ok = ok and p.should_stall(20, 10, 50.0)
	ok = ok and not p.should_stall(5, 4, 40.0)
	ok = ok and p.next_checksum_frame(30) and not p.next_checksum_frame(29)
	return {
		"ok": ok,
		"policy": p.as_dict(),
		"delay_40": d40,
		"delay_200": d200,
		"alpha_claim": ALPHA_CLAIM,
	}
