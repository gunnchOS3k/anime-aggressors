extends Node
class_name CombatFeedback

## Data-driven hit feedback: hitstop, camera, VFX, Path A procedural SFX.

const _ProceduralAudio = preload("res://scripts/audio/procedural_audio_bank.gd")
const _ImpactResolver = preload("res://scripts/combat/impact_profile_resolver.gd")
const _PoseContract = preload("res://scripts/visual/animation_pose_contract.gd")
const _Cinematic = preload("res://scripts/combat/combat_cinematic_director.gd")

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
	"ko": {"min": 16, "max": 20},
}

const TIER_SHAKE := {
	"light": 2.0,
	"medium": 4.0,
	"heavy": 8.0,
	"aura": 10.0,
	"super": 14.0,
	"ko": 16.0,
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
	var ctx := {
		"blocked": bool(info.get("blocked", false)),
		"whiff": bool(info.get("whiff", false)),
		"is_ko": bool(info.get("is_ko", false)),
		"attacker_aura": 0.0,
		"aura_ready": false,
	}
	if attacker != null and attacker.has_method("get_aura"):
		ctx["attacker_aura"] = float(attacker.get_aura())
	if Engine.get_main_loop() != null:
		var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
		if gs != null and "training_aura_threshold" in gs:
			ctx["aura_threshold"] = float(gs.training_aura_threshold)
	var profile: Dictionary = _ImpactResolver.resolve(move, ctx)
	var tier: String = str(profile.get("tier", fb.get("tier", "light")))
	var hitstop: int = int(profile.get("hitstop_frames", fb.get("hitstop_frames", info.get("hitstop_frames", 3))))
	if hitstop <= 0:
		hitstop = _default_hitstop(tier)
	# Synchronized hitstop: attacker and defender acknowledge the same contact.
	var attacker_hs := int(profile.get("attacker_hitstop_frames", hitstop))
	var defender_hs := int(profile.get("defender_hitstop_frames", hitstop))
	if bool(profile.get("hitstop_sync", true)):
		attacker_hs = hitstop
		defender_hs = hitstop
	var result := info.duplicate(true)
	result["hitstop_frames"] = hitstop
	result["attacker_hitstop_frames"] = attacker_hs
	result["defender_hitstop_frames"] = defender_hs
	result["hitstop_sync"] = attacker_hs == defender_hs
	result["feedback_tier"] = tier
	result["impact_profile"] = profile
	result["impact_class"] = str(profile.get("contact_class", tier))
	result["vfx_event"] = fb.get("vfx_event", "")
	result["sfx_event"] = fb.get("sfx_event", "")
	result["camera_event"] = fb.get("camera_event", "")
	result["screen_flash"] = bool(profile.get("screen_flash", fb.get("screen_flash", false)))
	result["element"] = move.get("element_effect", {}).get("type", "")
	result["contact_socket"] = _PoseContract.socket_for_move(move)
	result["contact_pose_clip"] = _PoseContract.contact_pose_clip(move, tier)
	result["contact_aligned"] = _PoseContract.contact_aligned(move)
	result["launch_readability"] = float(profile.get("launch_readability", 0.5))
	if Engine.get_main_loop() != null:
		var gst = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
		if gst != null:
			gst.last_contact_class = str(result["impact_class"])
	_play_element_palette(str(result["element"]), tier, attacker)
	_play_procedural_sfx(result.sfx_event, tier, attacker)
	var camera_ok := _training_allows("training_camera_enabled")
	if camera_ok and (bool(profile.get("warranted_camera", false)) or _Cinematic.should_direct(tier, _a11y_allows_camera())):
		_trigger_camera(tier, fb.get("camera_event", ""))
	_emit_juice("hitstop", {
		"tier": tier,
		"frames": hitstop,
		"attacker_frames": attacker_hs,
		"defender_frames": defender_hs,
		"sync": attacker_hs == defender_hs,
	})
	if _training_allows("training_vfx_enabled"):
		_emit_juice("impact_vfx", {
			"socket": result["contact_socket"],
			"element": result["element"],
			"tier": tier,
			"vfx_event": result["vfx_event"],
		})
		_emit_juice("contact_pose", {
			"clip": result["contact_pose_clip"],
			"socket": result["contact_socket"],
			"aligned": result["contact_aligned"],
			"tier": tier,
		})
	_emit_juice("impact_class", {
		"class": result["impact_class"],
		"tier": tier,
		"hud_hidden": true,
		"whiff": bool(info.get("whiff", false)),
		"shield": bool(info.get("blocked", false)),
	})
	_emit_juice("sfx", {"event_id": result["sfx_event"], "category": "hit", "tier": tier})
	feedback_triggered.emit(result)
	return result

func emit_aura_buildup(fid: String, level: int, pct: float) -> void:
	_emit_juice("aura_buildup", {"fighter_id": fid, "level": level, "pct": pct})

func emit_shield_flash(fid: String) -> void:
	_emit_juice("shield_flash", {"fighter_id": fid})

func emit_dodge_phase(fid: String, air: bool) -> void:
	_emit_juice("dodge_phase", {"fighter_id": fid, "air": air})

func emit_landing_dust(fid: String) -> void:
	_emit_juice("landing_dust", {"fighter_id": fid})

func emit_recovery_trail(element: String) -> void:
	_emit_juice("recovery_trail", {"element": element})

func emit_ko_burst(fid: String) -> void:
	_emit_juice("ko_burst", {"fighter_id": fid, "tier": "heavy"})

func emit_victory_presentation(fid: String) -> void:
	_emit_juice("victory_presentation", {"fighter_id": fid})

func emit_projectile_trail(element: String, charge: String) -> void:
	_emit_juice("projectile_trail", {"element": element, "charge": charge})

func emit_optional_rumble(strength: float, duration_ms: int) -> void:
	_emit_juice("rumble", {"strength": strength, "duration_ms": duration_ms})

func _emit_juice(event_name: String, payload: Dictionary) -> void:
	var bus = Engine.get_main_loop().root.get_node_or_null("/root/JuiceEventBus") if Engine.get_main_loop() else null
	if bus != null and bus.has_method("emit_event"):
		bus.emit_event(event_name, payload)

func _default_hitstop(tier: String) -> int:
	var range: Dictionary = TIER_HITSTOP.get(tier, TIER_HITSTOP.light)
	return int((range.min + range.max) / 2.0)

func _a11y_allows_camera() -> bool:
	var role = Engine.get_main_loop().root.get_node_or_null("/root/DeviceRoleRuntime") if Engine.get_main_loop() else null
	if role != null and role.has_method("fx_allows_camera_shake") and not role.fx_allows_camera_shake():
		return false
	var bus = Engine.get_main_loop().root.get_node_or_null("/root/JuiceEventBus") if Engine.get_main_loop() else null
	if bus != null and bus.has_method("can_reduce_shake") and bus.can_reduce_shake():
		return false
	return true


func _training_allows(flag: String) -> bool:
	var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState") if Engine.get_main_loop() else null
	if gs == null or not (flag in gs):
		return true
	return bool(gs.get(flag))


func _play_element_palette(element: String, tier: String, attacker: Node) -> void:
	if not _training_allows("training_sfx_enabled"):
		return
	var path := "res://data/combat/element_sfx_palettes.json"
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var elements: Dictionary = parsed.get("elements", {})
	var pal: Dictionary = elements.get(element, {})
	var table: Dictionary = pal.get("palette", {})
	var wav := str(table.get(tier, table.get("medium", "")))
	if wav.is_empty():
		return
	_ProceduralAudio.play(wav, self)


func _trigger_camera(tier: String, event: String) -> void:
	if not _a11y_allows_camera():
		return
	var intensity_scale := 1.0
	var role = Engine.get_main_loop().root.get_node_or_null("/root/DeviceRoleRuntime") if Engine.get_main_loop() else null
	if role != null and role.has_method("fx_intensity"):
		intensity_scale = float(role.fx_intensity())
	if intensity_scale <= 0.01:
		return
	_shake_intensity = TIER_SHAKE.get(tier, 2.0) * intensity_scale
	_shake_remaining = 0.12 * intensity_scale
	# Wave017 optional impact zoom via battle camera controller
	if _camera != null and is_instance_valid(_camera):
		var scene = _camera.get_parent()
		if scene != null:
			var bcc = scene.get_node_or_null("BattleCameraController")
			if bcc != null and bcc.has_method("trigger_impact_zoom"):
				var boost := 0.04
				match tier:
					"heavy", "aura":
						boost = 0.07
					"super":
						boost = 0.10
				bcc.trigger_impact_zoom(boost * intensity_scale, 0.14)
	_emit_juice("camera_shake", {
		"tier": tier,
		"intensity": _shake_intensity,
		"duration_s": _shake_remaining,
		"camera_event": event,
	})
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
	if not _training_allows("training_vfx_enabled"):
		return
	var role = Engine.get_main_loop().root.get_node_or_null("/root/DeviceRoleRuntime") if Engine.get_main_loop() else null
	if role != null and role.has_method("fx_allows_hit_sparks") and not role.fx_allows_hit_sparks():
		return
	_emit_juice("hit_spark", {"element": element, "socket": "contact", "pos": pos})
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
