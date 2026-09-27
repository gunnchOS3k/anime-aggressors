extends Node
class_name CombatFeedback

## Data-driven hit feedback: hitstop, camera, VFX, Path A procedural SFX.

const _ProceduralAudio = preload("res://scripts/audio/procedural_audio_bank.gd")
const _SfxResolver = preload("res://scripts/audio/combat_sfx_resolver.gd")
const _VfxDirector = preload("res://scripts/visual/move_vfx_director.gd")
const _Predictor = preload("res://scripts/combat/critical_launch_predictor.gd")
const _TrailScript = preload("res://scripts/visual/launch_trail_system.gd")
const _CueScript = preload("res://scripts/visual/critical_launch_cue.gd")

signal feedback_triggered(info: Dictionary)

var _profiles: Dictionary = {}
var _camera: Camera2D = null
var _shake_remaining: float = 0.0
var _shake_intensity: float = 0.0
var fighter_id: String = ""
var _last_critical_at: Dictionary = {}
var _last_prediction: Dictionary = {}

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
	_play_v3_move_content(attacker, defender, move, result)
	_trigger_camera(tier, fb.get("camera_event", ""))
	_emit_juice("hitstop", {"tier": tier, "frames": hitstop})
	_emit_juice("impact_vfx", {
		"socket": fb.get("vfx_socket", "chest"),
		"element": result["element"],
		"tier": tier,
		"vfx_event": result["vfx_event"],
	})
	_emit_juice("sfx", {"event_id": result["sfx_event"], "category": "hit", "tier": tier})
	result = _apply_launch_presentation(attacker, defender, move, result)
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


func last_prediction() -> Dictionary:
	return _last_prediction.duplicate(true)


func _apply_launch_presentation(attacker: Node, defender: Node, move: Dictionary, result: Dictionary) -> Dictionary:
	var launch: Vector2 = result.get("launch", Vector2.ZERO)
	if typeof(launch) != TYPE_VECTOR2:
		launch = Vector2.ZERO
	var attacker_id := fighter_id
	if attacker_id == "" and attacker != null and "fighter_id" in attacker:
		attacker_id = str(attacker.fighter_id)
	if bool(move.get("_from_projectile", false)) and attacker != null and "fighter_id" in attacker:
		attacker_id = str(attacker.fighter_id)
	if bool(move.get("reflected", false)) and attacker != null and "fighter_id" in attacker:
		attacker_id = str(attacker.fighter_id)
	if attacker_id == "" and str(move.get("element_effect", {}).get("type", "")) == "":
		attacker_id = "hazard"
	var pos := Vector2.ZERO
	if defender is Node2D:
		pos = (defender as Node2D).global_position
	var already := false
	if defender != null and "stocks" in defender and int(defender.stocks) <= 0:
		already = true
	var blast := _Predictor.DEFAULT_BLAST
	var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState") if Engine.get_main_loop() else null
	if gs != null and gs.has_method("load_stage"):
		var stage: Dictionary = gs.load_stage(str(gs.stage_id)) if "stage_id" in gs else {}
		if stage.has("blastZones"):
			blast = stage.get("blastZones")
	var jumps := 1
	if defender != null and "air_jumps_left" in defender:
		jumps = int(defender.air_jumps_left)
	var pred := _Predictor.evaluate({
		"position": pos,
		"launch_velocity": launch,
		"blast_zones": blast,
		"remaining_jumps": jumps,
		"recovery_ready": jumps > 0,
		"hitstun_sec": float(result.get("hitstop_frames", 3)) / 60.0 + 0.18,
		"already_past_blast": already,
	})
	_last_prediction = pred
	result["launch_prediction"] = pred
	result["launch_trail_tier"] = _Predictor.trail_tier(pred, launch.length())
	var key := str(defender.get_instance_id()) if defender != null else "none"
	var now := Time.get_ticks_msec() / 1000.0
	var last := float(_last_critical_at.get(key, -99.0))
	var danger := str(pred.get("tier", "SAFE"))
	var spam := now - last < 0.45
	var multi := bool(move.get("multi_hit", false)) and not bool(move.get("final_hit", true))
	if multi or spam:
		result["critical_suppressed"] = true
		return result
	if danger in ["CRITICAL_RECOVERABLE", "NEAR_CERTAIN_KO"]:
		_last_critical_at[key] = now
		result["hitstop_frames"] = maxi(int(result.get("hitstop_frames", 3)), 8)
		_emit_juice("launch_critical_recoverable" if danger == "CRITICAL_RECOVERABLE" else "launch_near_certain_ko", {
			"attacker_id": attacker_id,
			"tier": danger,
			"family": _CueScript.family_for(attacker_id),
		})
		if defender is Node2D:
			_spawn_critical_cue(defender as Node2D, attacker_id, launch, danger)
			_ensure_trail(defender as Node2D, attacker_id, "CRITICAL")
		emit_optional_rumble(0.45 if danger == "CRITICAL_RECOVERABLE" else 0.7, 90)
	elif str(result["launch_trail_tier"]) == "HIGH":
		_emit_juice("launch_high", {"attacker_id": attacker_id, "tier": "HIGH"})
		if defender is Node2D:
			_ensure_trail(defender as Node2D, attacker_id, "HIGH")
	return result


func _ensure_trail(defender: Node2D, attacker_id: String, tier: String) -> void:
	var existing := defender.get_node_or_null("LaunchTrail")
	if existing == null:
		existing = _TrailScript.new()
		existing.name = "LaunchTrail"
		defender.add_child(existing)
	if existing.has_method("begin"):
		existing.begin(defender, attacker_id, tier)


func _spawn_critical_cue(defender: Node2D, attacker_id: String, launch: Vector2, tier: String) -> void:
	var cue = _CueScript.new()
	cue.name = "CriticalLaunchCue"
	var parent: Node = defender.get_parent()
	if parent == null:
		parent = defender
	parent.add_child(cue)
	cue.play(attacker_id, defender.global_position + Vector2(0, -24), launch, tier)


func _emit_juice(event_name: String, payload: Dictionary) -> void:
	var bus = Engine.get_main_loop().root.get_node_or_null("/root/JuiceEventBus") if Engine.get_main_loop() else null
	if bus != null and bus.has_method("emit_event"):
		bus.emit_event(event_name, payload)

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

func _play_v3_move_content(attacker: Node, defender: Node, move: Dictionary, result: Dictionary) -> void:
	var fid := fighter_id
	if fid == "" and attacker != null and "fighter_id" in attacker:
		fid = str(attacker.fighter_id)
	var mid := str(move.get("move_id", ""))
	if fid == "" or mid == "":
		return
	var pos := Vector2.ZERO
	if defender is Node2D:
		pos = (defender as Node2D).global_position
	elif attacker is Node2D:
		pos = (attacker as Node2D).global_position
	var facing := 1
	if attacker != null and "facing" in attacker:
		facing = int(attacker.facing)
	var parent: Node2D = defender as Node2D if defender is Node2D else attacker as Node2D
	if parent != null:
		var played: Dictionary = _VfxDirector.play(parent, fid, mid, pos, facing)
		result["vfx_shape"] = played.get("shape", "")
		result["vfx_palette_only"] = bool(played.get("palette_only", false))
	var fb: Dictionary = move.get("feedback", {})
	result["particle_profile"] = fb.get("particle_profile", "")


func _play_procedural_sfx(event: String, tier: String, attacker: Node) -> void:
	if event == "":
		return
	var fid := fighter_id
	if fid == "" and attacker != null and "fighter_id" in attacker:
		fid = str(attacker.fighter_id)
	elif fid == "" and attacker != null and attacker.has_method("get") and attacker.get("data") is Dictionary:
		fid = str((attacker.get("data") as Dictionary).get("id", ""))
	var mid := ""
	if attacker != null and "_current_move" in attacker and attacker._current_move is Dictionary:
		mid = str(attacker._current_move.get("move_id", ""))
	var played: Dictionary
	if fid != "" and mid != "":
		played = _SfxResolver.play_move(fid, mid, self)
	if played.is_empty() or not bool(played.get("ok", false)):
		var cat := _ProceduralAudio.map_sfx_event_to_category(event)
		if fid != "":
			played = _ProceduralAudio.play_fighter(fid, cat, self)
		else:
			played = _ProceduralAudio.play_shared(cat, self)
	if not bool(played.get("ok", false)):
		print("[CombatFeedback] sfx_miss: %s tier:%s" % [event, tier])

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
