extends Node
class_name FighterAnimator

## Proxy AnimationPlayer clips — labeled PROXY until final authored GLB art lands.

const PROXY_LABEL := "PROXY — NOT FINAL ART"

var _fighter: AAFighter
var _player: AnimationPlayer
var _proxy_label: Label

func setup(fighter: AAFighter, body: ColorRect) -> void:
	_fighter = fighter
	_player = AnimationPlayer.new()
	add_child(_player)
	_build_proxy_clips(body)
	_proxy_label = Label.new()
	_proxy_label.text = PROXY_LABEL
	_proxy_label.add_theme_font_size_override("font_size", 8)
	_proxy_label.position = Vector2(-50, -88)
	add_child(_proxy_label)

func play_for_state(state: String) -> void:
	var clip := FighterStates.animation_for_state(state)
	if _player.has_animation(clip):
		if _player.current_animation != clip or not _player.is_playing():
			_player.play(clip)

func set_proxy_visible(value: bool) -> void:
	if _proxy_label:
		_proxy_label.visible = value

func _build_proxy_clips(body: ColorRect) -> void:
	var lib := AnimationLibrary.new()
	var defs := {
		"idle": _bob(body, 0, 2),
		"walk": _bob(body, 4, 3),
		"dash": _slide(body, 8),
		"jump": _jump(body),
		"fall": _tilt(body, -8),
		"land": _squash(body),
		"jab": _punch(body),
		"heavy": _heavy(body),
		"special": _special(body),
		"shield": _shield(body),
		"hurt_light": _flash(body, 0.3),
		"hurt_heavy": _flash(body, 0.6),
		"launched": _spin(body),
		"aura_charge": _pulse(body),
		"aura_burst": _burst(body),
		"grab": _reach(body),
		"throw": _throw(body),
		"ko": _ko(body),
		"victory": _victory(body),
		"defeat": _defeat(body),
	}
	for name in defs:
		lib.add_animation(name, defs[name])
	_player.add_animation_library("", lib)

func _bob(body: ColorRect, amp: float, spd: float) -> Animation:
	var a := Animation.new()
	a.length = 0.5
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, NodePath(str(body.get_path()) + ":position:y"))
	a.track_insert_key(t, 0.0, body.position.y)
	a.track_insert_key(t, 0.25, body.position.y - amp)
	a.track_insert_key(t, 0.5, body.position.y)
	a.loop_mode = Animation.LOOP_LINEAR
	return a

func _slide(body: ColorRect, dx: float) -> Animation:
	var a := Animation.new()
	a.length = 0.12
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, NodePath(str(body.get_path()) + ":position:x"))
	a.track_insert_key(t, 0.0, body.position.x)
	a.track_insert_key(t, 0.12, body.position.x + dx)
	return a

func _jump(body: ColorRect) -> Animation:
	var a := Animation.new()
	a.length = 0.2
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, NodePath(str(body.get_path()) + ":scale:y"))
	a.track_insert_key(t, 0.0, 1.0)
	a.track_insert_key(t, 0.1, 1.15)
	a.track_insert_key(t, 0.2, 1.0)
	return a

func _tilt(body: ColorRect, deg: float) -> Animation:
	var a := Animation.new()
	a.length = 0.15
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, NodePath(str(body.get_path()) + ":rotation_degrees"))
	a.track_insert_key(t, 0.0, 0.0)
	a.track_insert_key(t, 0.15, deg)
	a.loop_mode = Animation.LOOP_LINEAR
	return a

func _squash(body: ColorRect) -> Animation:
	var a := Animation.new()
	a.length = 0.1
	var ty := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(ty, NodePath(str(body.get_path()) + ":scale:y"))
	a.track_insert_key(ty, 0.0, 1.2)
	a.track_insert_key(ty, 0.1, 1.0)
	return a

func _punch(body: ColorRect) -> Animation:
	return _slide(body, 12.0)

func _heavy(body: ColorRect) -> Animation:
	return _slide(body, 20.0)

func _special(body: ColorRect) -> Animation:
	var a := Animation.new()
	a.length = 0.25
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, NodePath(str(body.get_path()) + ":modulate"))
	a.track_insert_key(t, 0.0, Color.WHITE)
	a.track_insert_key(t, 0.12, Color(1.2, 1.0, 0.6))
	a.track_insert_key(t, 0.25, Color.WHITE)
	return a

func _shield(body: ColorRect) -> Animation:
	var a := Animation.new()
	a.length = 0.3
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, NodePath(str(body.get_path()) + ":modulate"))
	a.track_insert_key(t, 0.0, Color(0.7, 0.85, 1.2))
	a.loop_mode = Animation.LOOP_LINEAR
	return a

func _flash(body: ColorRect, intensity: float) -> Animation:
	var a := Animation.new()
	a.length = 0.12
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, NodePath(str(body.get_path()) + ":modulate"))
	a.track_insert_key(t, 0.0, Color(1, 1 - intensity, 1 - intensity))
	a.track_insert_key(t, 0.12, Color.WHITE)
	return a

func _spin(body: ColorRect) -> Animation:
	var a := Animation.new()
	a.length = 0.4
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, NodePath(str(body.get_path()) + ":rotation_degrees"))
	a.track_insert_key(t, 0.0, 0.0)
	a.track_insert_key(t, 0.4, 360.0)
	a.loop_mode = Animation.LOOP_LINEAR
	return a

func _pulse(body: ColorRect) -> Animation:
	var a := Animation.new()
	a.length = 0.6
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, NodePath(str(body.get_path()) + ":modulate"))
	a.track_insert_key(t, 0.0, Color(1, 0.9, 0.5))
	a.track_insert_key(t, 0.3, Color(1.3, 1.1, 0.4))
	a.track_insert_key(t, 0.6, Color(1, 0.9, 0.5))
	a.loop_mode = Animation.LOOP_LINEAR
	return a

func _burst(body: ColorRect) -> Animation:
	var a := Animation.new()
	a.length = 0.35
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, NodePath(str(body.get_path()) + ":scale"))
	a.track_insert_key(t, 0.0, Vector2.ONE)
	a.track_insert_key(t, 0.15, Vector2(1.4, 1.4))
	a.track_insert_key(t, 0.35, Vector2.ONE)
	return a

func _reach(body: ColorRect) -> Animation:
	return _slide(body, 8.0)

func _throw(body: ColorRect) -> Animation:
	return _slide(body, -16.0)

func _ko(body: ColorRect) -> Animation:
	var a := Animation.new()
	a.length = 0.5
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, NodePath(str(body.get_path()) + ":modulate:a"))
	a.track_insert_key(t, 0.0, 1.0)
	a.track_insert_key(t, 0.5, 0.0)
	return a

func _victory(body: ColorRect) -> Animation:
	return _bob(body, 6, 4)

func _defeat(body: ColorRect) -> Animation:
	return _tilt(body, 25)
