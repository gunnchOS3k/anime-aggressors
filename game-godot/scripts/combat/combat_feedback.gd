extends Node
class_name CombatFeedback

## Data-driven hit feedback: hitstop, camera, VFX, Path A procedural SFX.

const _ProceduralAudio = preload("res://scripts/audio/procedural_audio_bank.gd")

signal feedback_triggered(info: Dictionary)

var _profiles: Dictionary = {}
var _camera: Camera2D = null
var _shake_remaining: float = 0.0
var _shake_intensity: float = 0.0
var fighter_id: String = ""

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
	_play_procedural_sfx(result.sfx_event, tier, attacker)
	_trigger_camera(tier, fb.get("camera_event", ""))
	feedback_triggered.emit(result)
	return result

func _default_hitstop(tier: String) -> int:
	var range: Dictionary = TIER_HITSTOP.get(tier, TIER_HITSTOP.light)
	return int((range.min + range.max) / 2.0)

func _trigger_camera(tier: String, event: String) -> void:
	var intensity_scale := 1.0
	var role = Engine.get_main_loop().root.get_node_or_null("/root/DeviceRoleRuntime") if Engine.get_main_loop() else null
	if role != null:
		if role.has_method("fx_allows_camera_shake") and not role.fx_allows_camera_shake():
			return
		if role.has_method("fx_intensity"):
			intensity_scale = float(role.fx_intensity())
	_shake_intensity = TIER_SHAKE.get(tier, 2.0) * intensity_scale
	_shake_remaining = 0.12 * intensity_scale
	if event != "" and intensity_scale > 0.01:
		print("[CombatFeedback] camera_event: %s tier:%s" % [event, tier])

func _play_procedural_sfx(event: String, tier: String, attacker: Node) -> void:
	if event == "":
		return
	var fid := fighter_id
	if fid == "" and attacker != null and "fighter_id" in attacker:
		fid = str(attacker.fighter_id)
	elif fid == "" and attacker != null and attacker.has_method("get") and attacker.get("data") is Dictionary:
		fid = str((attacker.get("data") as Dictionary).get("id", ""))
	var cat := _ProceduralAudio.map_sfx_event_to_category(event)
	var played: Dictionary
	if fid != "":
		played = _ProceduralAudio.play_fighter(fid, cat, self)
	else:
		played = _ProceduralAudio.play_shared(cat, self)
	if not bool(played.get("ok", false)):
		print("[CombatFeedback] sfx_miss: %s tier:%s cat:%s" % [event, tier, cat])

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
	var role = Engine.get_main_loop().root.get_node_or_null("/root/DeviceRoleRuntime") if Engine.get_main_loop() else null
	if role != null and role.has_method("fx_allows_hit_sparks") and not role.fx_allows_hit_sparks():
		return
	var spark := ColorRect.new()
	spark.size = Vector2(12, 12)
	spark.position = pos - spark.size / 2.0
	spark.color = _element_color(element)
	parent.add_child(spark)
	var tween := spark.create_tween()
	tween.tween_property(spark, "modulate:a", 0.0, 0.15)
	tween.tween_callback(spark.queue_free)
	# GAME-RC-003: secondary ring for heavy/aura readability.
	var ring := ColorRect.new()
	ring.size = Vector2(22, 22)
	ring.position = pos - ring.size / 2.0
	ring.color = Color(_element_color(element).r, _element_color(element).g, _element_color(element).b, 0.35)
	parent.add_child(ring)
	var rt := ring.create_tween()
	rt.tween_property(ring, "scale", Vector2(1.8, 1.8), 0.18)
	rt.parallel().tween_property(ring, "modulate:a", 0.0, 0.18)
	rt.tween_callback(ring.queue_free)

## Grab release / recovery cue — short flash so throws are readable.
func spawn_grab_recovery_flash(parent: Node2D, pos: Vector2, direction: String) -> void:
	var role = Engine.get_main_loop().root.get_node_or_null("/root/DeviceRoleRuntime") if Engine.get_main_loop() else null
	if role != null and role.has_method("fx_allows_hit_sparks") and not role.fx_allows_hit_sparks():
		return
	var flash := ColorRect.new()
	flash.size = Vector2(28, 18)
	flash.position = pos - flash.size / 2.0
	match direction:
		"up":
			flash.color = Color(0.95, 0.95, 1.0, 0.8)
		"down":
			flash.color = Color(0.9, 0.55, 0.2, 0.8)
		"back":
			flash.color = Color(0.6, 0.8, 1.0, 0.8)
		_:
			flash.color = Color(1.0, 0.75, 0.35, 0.8)
	parent.add_child(flash)
	var tw := flash.create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.22)
	tw.tween_callback(flash.queue_free)

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
