extends Node2D
class_name CriticalLaunchCue

## Unique elemental critical-launch / KO-danger presentation. No roster-wide red lightning.

const _Identity = preload("res://scripts/visual/elemental_material_contract.gd")
const _Vfx = preload("res://scripts/visual/elemental_vfx_family.gd")
const _Bank = preload("res://scripts/audio/procedural_audio_bank.gd")
const _Brand = preload("res://scripts/vxp2/vxp2_brand.gd")

const CUES := {
	"ember-vale": "furnace_flare_rupture",
	"rook-ironside": "tectonic_impact_fracture",
	"juno-spark": "voltage_fork",
	"kaia-windrow": "wind_shear_cleave",
	"nix-calder": "crystal_break_launch",
	"orion-vell": "gravity_rift_constellation",
	"vesper-nyx": "phase_tear_rupture",
	"hazard": "neutral_hazard_fracture",
}

var _family: String = ""
var _attacker_id: String = ""
var _dir: Vector2 = Vector2.RIGHT
var _life: float = 0.0
var _tier: String = "CRITICAL_RECOVERABLE"
var _reduce: bool = false
var _hc: bool = false


func _ready() -> void:
	z_index = 12
	_reduce = _Brand.reduce_motion_active()
	_hc = _Brand.high_contrast_active()


func play(attacker_id: String, origin: Vector2, launch_dir: Vector2, tier: String) -> Dictionary:
	_attacker_id = attacker_id if CUES.has(attacker_id) else "hazard"
	_family = str(CUES.get(_attacker_id, CUES.hazard))
	_dir = launch_dir.normalized() if launch_dir.length() > 0.01 else Vector2.RIGHT
	_tier = tier
	global_position = origin
	_life = 0.16 if _reduce else (0.28 if tier != "NEAR_CERTAIN_KO" else 0.34)
	_play_sound()
	queue_redraw()
	return describe()


func describe() -> Dictionary:
	return {
		"attacker_id": _attacker_id,
		"family": _family,
		"shared_grammar": ["contact_freeze", "elemental_rift", "directional_streak", "sound_hook", "body_trail"],
		"roster_wide_red_lightning": false,
		"reduce_motion": _reduce,
		"high_contrast": _hc,
		"color_only": false,
	}


static func family_for(fighter_id: String) -> String:
	return str(CUES.get(fighter_id, CUES.hazard))


static func mapping_complete() -> bool:
	for fid in ["ember-vale", "rook-ironside", "juno-spark", "kaia-windrow", "nix-calder", "orion-vell", "vesper-nyx"]:
		if not CUES.has(fid):
			return false
	return CUES.size() >= 8


func _play_sound() -> void:
	var path := "res://assets/audio/procedural/combat/launch_critical_%s.wav" % _attacker_id
	var played := _Bank.play(path, self)
	if not bool(played.get("ok", false)):
		_Bank.play("res://assets/audio/procedural/shared/launch_critical.wav", self)


func _process(delta: float) -> void:
	if _life <= 0.0:
		return
	_life -= delta
	queue_redraw()
	if _life <= 0.0:
		queue_free()


func _draw() -> void:
	if _life <= 0.0:
		return
	var colors := _Identity.identity_colors(_attacker_id if _attacker_id != "hazard" else "ember-vale")
	var core: Color = colors.get("core", Color(1, 1, 1))
	var accent: Color = colors.get("accent", Color(1, 1, 1))
	if _hc:
		core = Color(1, 1, 1)
		accent = Color(1, 1, 0.7)
	var fade := clampf(_life * 4.0, 0.0, 1.0)
	var along := _dir * (48.0 if _reduce else 86.0)
	# Shared grammar: directional streak + high-contrast rift. Family changes geometry.
	match _family:
		"furnace_flare_rupture":
			draw_circle(Vector2.ZERO, 18.0 * fade, Color(core.r, core.g, core.b, 0.45 * fade))
			draw_line(-along * 0.15, along, Color(accent.r, accent.g, accent.b, 0.9 * fade), 7.0)
			draw_arc(Vector2.ZERO, 26.0 * fade, 0.0, TAU, 18, Color(1.0, 0.7, 0.2, 0.55 * fade), 3.0)
		"tectonic_impact_fracture":
			draw_rect(Rect2(-14, -14, 28, 28), Color(core.r, core.g, core.b, 0.5 * fade), false, 3.0)
			draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 12, Color(accent.r, accent.g, accent.b, 0.7 * fade), 4.0)
			draw_line(Vector2.ZERO, along, Color(0.7, 0.55, 0.3, 0.7 * fade), 8.0)
		"voltage_fork":
			draw_line(Vector2.ZERO, along, Color(accent.r, accent.g, 0.2, 0.95 * fade), 3.0)
			draw_line(Vector2.ZERO, along.rotated(0.28) * 0.75, Color(0.4, 0.95, 1.0, 0.85 * fade), 2.0)
			draw_line(Vector2.ZERO, along.rotated(-0.28) * 0.75, Color(0.4, 0.95, 1.0, 0.85 * fade), 2.0)
		"wind_shear_cleave":
			draw_arc(Vector2.ZERO, 20.0, _dir.angle() - 1.2, _dir.angle() + 1.2, 12, Color(0.85, 1.0, 0.9, 0.7 * fade), 3.0)
			draw_line(Vector2.ZERO, along, Color(core.r, core.g, core.b, 0.8 * fade), 4.0)
		"crystal_break_launch":
			for i in 5:
				var ang := _dir.angle() + (-0.5 + 0.25 * i)
				draw_line(Vector2.ZERO, Vector2.from_angle(ang) * 34.0, Color(0.7, 0.95, 1.0, 0.8 * fade), 2.0)
			draw_circle(Vector2.ZERO, 8.0, Color(0.9, 0.98, 1.0, 0.7 * fade))
		"gravity_rift_constellation":
			draw_line(-along * 0.2, along, Color(core.r, core.g, core.b, 0.85 * fade), 3.0)
			for i in 4:
				var p := along * (0.2 + 0.2 * i)
				draw_circle(p, 3.5, Color(1, 1, 1, 0.9 * fade))
		"phase_tear_rupture":
			draw_line(Vector2(-6, -8), along + Vector2(6, 8), Color(accent.r, accent.g, accent.b, 0.55 * fade), 5.0)
			draw_line(Vector2(6, 8), along, Color(core.r, core.g, core.b, 0.8 * fade), 3.0)
		_:
			draw_line(Vector2.ZERO, along, Color(1, 1, 1, 0.8 * fade), 4.0)
	if _hc:
		draw_rect(Rect2(-3, -22, 6, 44), Color(1, 1, 1, 0.8 * fade))
