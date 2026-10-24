extends RefCounted
## Confirmed interception presentation only. No combat writes or camera/time effects.
const Audio = preload("res://scripts/audio/elemental_performance.gd")
const Bank = preload("res://scripts/audio/procedural_audio_bank.gd")
var renderer: Node2D
var seen: Dictionary = {}
var recent: Array = []
var history: Array = []
var voices: Array = []
var indicator: Label
var confirmed_count := 0
var primary_count := 0
var decoration_suppressed := 0
var audio_suppressed := 0
var peak_voices := 0
var crowd_simplifications := 0
var last_stage := -100.0
var last_audio := -100.0
var last_audio_major := false
var indicator_age := 0.0

func setup(host: Node2D) -> void:
	renderer = host
	if "--clash-indicators" in OS.get_cmdline_user_args():
		var layer := CanvasLayer.new(); layer.layer = 101; host.add_child(layer)
		indicator = Label.new(); indicator.position = Vector2(26, 218)
		indicator.text = "DEV · confirmed interceptions: 0 (no collision observed)"
		layer.add_child(indicator)

func play_sound(fid: String, event: String, duration: float, pitch: float, intensity: float, cap: int) -> void:
	var stream := Bank.load_stream(Audio.path(fid, event))
	if stream == null: return
	# Retire our oldest voice only; never interrupt combat/dialogue audio.
	while voices.size() >= cap:
		var old: Dictionary = voices.pop_front()
		if is_instance_valid(old.player): old.player.stop(); old.player.queue_free()
	var player := AudioStreamPlayer.new(); player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = linear_to_db(maxf(.0001, Audio.mix_option("element_volume", .65) * intensity)) - 7
	player.set_meta("audio_category", "sfx")
	renderer.add_child(player); player.play()
	voices.append({"player": player, "remaining": duration})
	peak_voices = maxi(peak_voices, voices.size())

func present(first: String, second: String, world: Vector2, direction: Vector2, result: String, event_id: String, context: Node2D, detail: Dictionary) -> void:
	if event_id.is_empty() or seen.has(event_id) or not bool(detail.get("confirmed_interception", false)): return
	seen[event_id] = true
	if seen.size() > 256: seen.erase(seen.keys()[0])
	confirmed_count += 1
	var before: Array = detail.get("before", [1, 1])
	var after: Array = detail.get("after", [0, 0])
	var major: bool = maxi(int(before[0]), int(before[1])) >= 4 and mini(int(before[0]), int(before[1])) >= 2
	var mode: String = renderer.intensity_mode()
	var reduced: bool = renderer.option("reduced_particles")
	var now := float(detail.get("physics_frame", Engine.get_physics_frames())) / 60.0
	while not recent.is_empty() and now - float(recent[0]) > .6: recent.pop_front()
	var secondary := not reduced and recent.size() < (3 if mode == "Full" else 1)
	recent.append(now)
	if recent.size() > 32: recent.pop_front()
	# One mixed-element primary, held briefly rather than a fading explosion.
	var kind := 22 if major else 20 if result == "mutual_cancel" else 21
	var extent := (158.0 if major else 90.0 if kind == 20 else 104.0) * (.8 if reduced else .92 if mode == "Balanced" else 1.0)
	var life := (.36 if major else .28) if not reduced else (.30 if major else .26)
	var winner := 0 if int(before[0]) > int(before[1]) else 1
	var fid: String = first if result == "mutual_cancel" or winner == 0 else second
	var other: String = second if fid == first else first
	var winner_direction: Array = detail.get("winner_direction", [direction.x, direction.y])
	var dir := Vector2(float(winner_direction[0]), float(winner_direction[1])) if result == "breakthrough" else direction
	# Stage and fragments are expendable; the outcome is admitted last.
	if secondary:
		if major or result == "breakthrough":
			var fragments: int = renderer.emit_effect(other, 23, world, -dir, extent * .8, .22, event_id + ":fragments")
			if fragments >= 0: renderer.set_clash_parameters(fragments, fid, result == "breakthrough")
		if now - last_stage >= (.28 if mode == "Full" else .45) and (major or result == "breakthrough"):
			last_stage = now
			renderer.stage_contact({"confirmed_contact": true, "combat_event_id": event_id, "contact_world": world, "attacker_id": fid, "contact_result": "projectile_clash", "feedback_tier": "heavy" if major else "light", "projectile_stage_power": 2 if major else 1}, context)
			if major and mode == "Full" and other != fid:
				renderer.stage_contact({"confirmed_contact": true, "combat_event_id": event_id + ":mixed_surface", "contact_world": world, "attacker_id": other, "contact_result": "projectile_clash", "projectile_stage_power": 2}, context)
	else: decoration_suppressed += 1
	var primary: int = renderer.emit_effect(fid, kind, world, dir, extent, life, event_id + ":outcome")
	if primary >= 0:
		primary_count += 1
		renderer.set_clash_parameters(primary, other, result == "breakthrough")
	if recent.size() > (3 if mode == "Full" else 2): crowd_simplifications += renderer.simplify_nearby_clashes(world)
	# A short transient, a directional tear, and a deeper layered charged cue
	# use existing original samples with bounded envelopes and concurrency.
	var sound := "projectile_impact" if major else "charge_release" if result == "breakthrough" else "block"
	var audio_admitted := now - last_audio >= (.10 if reduced else .065) or (major and not last_audio_major)
	if audio_admitted:
		last_audio = now
		last_audio_major = major
		var cap := 2 if reduced else 3 if mode == "Balanced" else 4
		play_sound(fid, sound, .34 if major else .24 if result == "breakthrough" else .12, .86 if major else 1.08 if result == "breakthrough" else 1.1, .48 if major else .38, cap)
		if secondary and major: play_sound(other, "projectile_impact", .26, 1.08, .24, cap)
	elif not audio_admitted: audio_suppressed += 1
	var row := {"event_id": event_id, "physics_frame": detail.get("physics_frame", -1), "result": result, "presentation_outcome": "major_charged" if major else result, "before": before.duplicate(), "after": after.duplicate(), "world": [world.x, world.y], "direction": [dir.x, dir.y], "primary_slot": primary, "primary_kind": kind, "primary_life": life, "secondary_admitted": secondary, "audio_admitted": audio_admitted, "audio_sample": Audio.path(fid, sound), "mode": mode, "camera_impulses": 0, "gameplay_writes": false}
	history.append(row)
	if history.size() > 256: history.pop_front()
	if is_instance_valid(indicator):
		indicator_age = 0
		indicator.text = "DEV · confirmed interceptions: %d · %s\n%s / %s · %s → %s" % [confirmed_count, row.presentation_outcome.to_upper(), first, second, str(before), str(after)]

func advance(delta: float) -> void:
	for i in range(voices.size() - 1, -1, -1):
		var voice: Dictionary = voices[i]
		voice.remaining -= delta
		if not is_instance_valid(voice.player) or voice.remaining <= 0 or not voice.player.playing:
			if is_instance_valid(voice.player): voice.player.stop(); voice.player.queue_free()
			voices.remove_at(i)
	if is_instance_valid(indicator):
		indicator_age += delta
		indicator.modulate.a = 1.0 if indicator_age < 1.5 else .65

func evidence() -> Dictionary:
	return {"confirmed": confirmed_count, "primary_cues": primary_count, "secondary_suppressed": decoration_suppressed, "crowd_simplifications": crowd_simplifications, "audio_suppressed": audio_suppressed, "active_audio_voices": voices.size(), "peak_audio_voices": peak_voices, "developer_indicator_enabled": is_instance_valid(indicator), "history": history.duplicate(true), "camera_impulses": 0}
