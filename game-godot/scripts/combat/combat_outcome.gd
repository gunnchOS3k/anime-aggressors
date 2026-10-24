extends RefCounted
class_name CombatOutcome
## Cursor-owned combat event contract. Numbers match existing source constants.
## Perfect Guard window/rearm/stun: perfect_guard.gd.
## Shield stun fallback: fighter_state_machine.gd SHIELD_STUN (0.25s).
## Shield-break baseline: shield_break_candidate_8c.json baseline.recovery_seconds.
## This does not retune frame data or label procedural clips as production art.

const PARRY_WINDOW_FRAMES := 4
const PARRY_REARM_FRAMES := 24
const PARRY_DEFENDER_STUN_FRAMES := 2
const PARRY_ATTACKER_STUN_FRAMES := 6
const SHIELD_STUN_FALLBACK_SECONDS := 0.25
const SHIELD_BREAK_BASELINE_SECONDS := 0.4
const SIM_FPS := 60

const SHIELD_STATE_IDS := [
	"shield_start",
	"shield_hold",
	"shield_hit",
	"shield_stun",
	"shield_break",
	"parry",
]

const SHIELD_EVENTS := [
	"shield_start",
	"shield_hold",
	"shield_hit",
	"shield_stun",
	"shield_break",
	"parry",
	"parry_fail",
	"hit_damage_applied",
	"hit_damage_zero",
]

## Existing aura tags from aura_identity.gd and bible paths already used by form acting.
const AURA_BIBLE := {
	"ember-vale": {"aura_tag": "burn_rushdown", "bible": "docs/bibles/fighters/ember-vale.md", "element": "flame"},
	"juno-spark": {"aura_tag": "speed_chain", "bible": "docs/bibles/fighters/juno-spark.md", "element": "spark"},
	"kaia-windrow": {"aura_tag": "wind_drift", "bible": "docs/bibles/fighters/kaia-windrow.md", "element": "wind"},
	"rook-ironside": {"aura_tag": "armor_quake", "bible": "docs/bibles/fighters/rook-ironside.md", "element": "stone"},
	"nix-calder": {"aura_tag": "freeze_control", "bible": "docs/bibles/fighters/nix-calder.md", "element": "ice"},
	"orion-vell": {"aura_tag": "gravity_pull", "bible": "docs/bibles/fighters/orion-vell.md", "element": "gravity"},
	"vesper-nyx": {"aura_tag": "phase_mark", "bible": "docs/bibles/fighters/vesper-nyx.md", "element": "phase"},
	"yin": {"aura_tag": "cosmic_reduction", "bible": "docs/bibles/fighters/yin.md", "element": "void"},
	"yang": {"aura_tag": "cosmic_definition", "bible": "docs/bibles/fighters/yang.md", "element": "radiance"},
}


static func bible_for(fighter_id: String) -> Dictionary:
	return AURA_BIBLE.get(fighter_id, {}).duplicate(true)


static func parry_window_open(age: int, consumed: bool) -> bool:
	return not consumed and age >= 0 and age < PARRY_WINDOW_FRAMES


static func guard_transition(current_state: String, shield_held: bool, just_pressed: bool, grounded: bool, guard_allowed: bool, actions_locked: bool) -> Dictionary:
	## Press enters shield_start. A later poll while the same button is held
	## enters shield_hold. Hit, stun, and break are not replaced by that input.
	var guarding := current_state == "shield_start" or current_state == "shield_hold"
	if guarding and (not shield_held or not grounded):
		return {"state": "idle" if grounded else "fall", "event": "shield_release", "begin_parry": false}
	if current_state == "shield_start" and shield_held and grounded:
		return {"state": "shield_hold", "event": "shield_hold", "begin_parry": false}
	if current_state == "shield_hold" and shield_held and grounded:
		return {"state": "shield_hold", "event": "", "begin_parry": false}
	if current_state in ["shield_hit", "shield_stun", "shield_break"]:
		return {"state": current_state, "event": "", "begin_parry": false}
	if actions_locked or not shield_held or not grounded or not guard_allowed:
		return {"state": current_state, "event": "", "begin_parry": false}
	if just_pressed:
		return {"state": "shield_start", "event": "shield_start", "begin_parry": true}
	return {"state": "shield_hold", "event": "shield_hold", "begin_parry": false}


static func confirmed_body_damage(meter_before: float, resolved_damage: float, gate: String = "hit") -> Dictionary:
	## The meter follows resolved damage on a clean hit. Authored damage is not
	## a substitute. Shield damage is a different field. Stocks stay on blast/KO.
	## Gates that must stay at zero: parry, shield, armor, invulnerable,
	## explicit_zero, rules_zero, dealt_mult_zero, resolved_zero.
	var applied := 0.0
	if gate == "hit" and resolved_damage > 0.0:
		applied = resolved_damage
	var after := meter_before + applied
	return {
		"event": "hit_damage_applied" if applied > 0.0 else "hit_damage_zero",
		"gate": gate,
		"damage_applied": applied,
		"meter_before": meter_before,
		"meter_after": after,
		"meter_changed": applied > 0.0,
		"stocks_delta": 0,
	}


static func shield_contact(shield_health: float, shield_damage: float, parry_open: bool, shield_stun_frames: int) -> Dictionary:
	if parry_open:
		return {
			"state": "parry",
			"next_state": "shield_hold",
			"event": "parry",
			"parry_result": "success",
			"damage_applied": 0.0,
			"shield_health": shield_health,
			"defender_stun_frames": PARRY_DEFENDER_STUN_FRAMES,
			"attacker_stun_frames": PARRY_ATTACKER_STUN_FRAMES,
			"shield_stun_frames": 0,
			"stocks_delta": 0,
		}
	var health := shield_health - maxf(0.0, shield_damage)
	if health <= 0.0:
		return {
			"state": "shield_break",
			"next_state": "shield_break",
			"event": "shield_break",
			"parry_result": "fail",
			"damage_applied": 0.0,
			"shield_health": 0.0,
			"defender_stun_frames": 0,
			"attacker_stun_frames": 0,
			"shield_stun_frames": 0,
			"stocks_delta": 0,
		}
	var frames := shield_stun_frames if shield_stun_frames > 0 else int(round(SHIELD_STUN_FALLBACK_SECONDS * float(SIM_FPS)))
	return {
		"state": "shield_hit",
		"next_state": "shield_stun",
		"event": "shield_hit",
		"parry_result": "fail",
		"damage_applied": 0.0,
		"shield_health": health,
		"defender_stun_frames": frames,
		"attacker_stun_frames": 0,
		"shield_stun_frames": frames,
		"stocks_delta": 0,
	}


static func stun_seconds(frames: int, fallback_seconds: float) -> float:
	if frames > 0:
		return float(frames) / float(SIM_FPS)
	return fallback_seconds
