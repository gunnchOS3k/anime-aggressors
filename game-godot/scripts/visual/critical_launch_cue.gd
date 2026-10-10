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
	"yin": "subtractive_aperture",
	"yang": "constructed_hex_radiance",
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
	var renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd").obtain(self)
	if renderer != null: renderer.emit_effect(attacker_id,6,origin,_dir,96,.22)
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
	pass # Prediction review is a directional cue, never a confirmed hit or finishing result.
