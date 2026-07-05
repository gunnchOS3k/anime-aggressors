extends Node
class_name CombatFeedback

## Data-driven hit feedback: hitstop, camera, VFX, SFX proxy hooks.

signal feedback_triggered(info: Dictionary)

var _profiles: Dictionary = {}
var _camera: Camera2D = null
var _shake_remaining: float = 0.0
var _shake_intensity: float = 0.0

const TIER_HITSTOP := {
	"light": {"min": 2, "max": 3},
	"medium": {"min": 4, "max": 6},
	"heavy": {"min": 7, "max": 10},
	"aura": {"min": 10, "max": 13},
	"super": {"min": 13, "max": 16},
}

const TIER_SHAKE := {
	"light": 2.0,
	"medium": 4.0,
	"heavy": 8.0,
	"aura": 10.0,
	"super": 14.0,
}

func _ready() -> void:
	_load_profiles()

func _load_profiles() -> void:
	var path := "res://data/combat/feedback_profiles.json"
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	_profiles = JSON.parse_string(f.get_as_text())

func bind_camera(cam: Camera2D) -> void:
	_camera = cam

func apply_hit(attacker: Node, defender: Node, move: Dictionary, info: Dictionary) -> Dictionary:
	var fb: Dictionary = move.get("feedback", {})
	var tier: String = fb.get("tier", "light")
	var hitstop: int = int(fb.get("hitstop_frames", info.get("hitstop_frames", 3)))
	if hitstop <= 0:
		hitstop = _default_hitstop(tier)
	var result := info.duplicate(true)
	result["hitstop_frames"] = hitstop
	result["feedback_tier"] = tier
	result["vfx_event"] = fb.get("vfx_event", "")
	result["sfx_event"] = fb.get("sfx_event", "")
	result["camera_event"] = fb.get("camera_event", "")
	result["screen_flash"] = fb.get("screen_flash", false)
	result["element"] = move.get("element_effect", {}).get("type", "")
	_log_proxy_sfx(result.sfx_event, tier)
	_trigger_camera(tier, fb.get("camera_event", ""))
	feedback_triggered.emit(result)
	return result

func _default_hitstop(tier: String) -> int:
	var range: Dictionary = TIER_HITSTOP.get(tier, TIER_HITSTOP.light)
	return int((range.min + range.max) / 2.0)

func _trigger_camera(tier: String, event: String) -> void:
	_shake_intensity = TIER_SHAKE.get(tier, 2.0)
	_shake_remaining = 0.12
	if event != "":
		print("[CombatFeedback] camera_event: %s tier:%s" % [event, tier])

func _log_proxy_sfx(event: String, tier: String) -> void:
	if event != "":
		print("[CombatFeedback] sfx_event: %s tier:%s" % [event, tier])

func _process(delta: float) -> void:
	if _camera == null or _shake_remaining <= 0.0:
		return
	_shake_remaining -= delta
	var offset := Vector2(
		randf_range(-_shake_intensity, _shake_intensity),
		randf_range(-_shake_intensity, _shake_intensity)
	)
	_camera.offset = offset if _shake_remaining > 0.0 else Vector2.ZERO

func spawn_hit_spark(parent: Node2D, pos: Vector2, element: String) -> void:
	var spark := ColorRect.new()
	spark.size = Vector2(12, 12)
	spark.position = pos - spark.size / 2.0
	spark.color = _element_color(element)
	parent.add_child(spark)
	var tween := spark.create_tween()
	tween.tween_property(spark, "modulate:a", 0.0, 0.15)
	tween.tween_callback(spark.queue_free)

func _element_color(element: String) -> Color:
	match element:
		"flame": return Color(1.0, 0.4, 0.1)
		"impact": return Color(0.9, 0.7, 0.2)
		"volt": return Color(1.0, 0.95, 0.2)
		"gale": return Color(0.3, 0.85, 0.5)
		"frost": return Color(0.4, 0.7, 1.0)
		"gravity": return Color(0.5, 0.4, 0.8)
		"void": return Color(0.6, 0.2, 0.8)
		_: return Color(1.0, 1.0, 1.0)
