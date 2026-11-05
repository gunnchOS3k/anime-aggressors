extends SceneTree
## Isolated lifecycle probe for the form/guard shutdown warnings.
## Does not change synthesis, timing, buses, or playback content.
const FormScript = preload("res://scripts/audio/transformation_audio_8c.gd")
const GuardScript = preload("res://scripts/audio/guard_audio_8c.gd")
var mode := "production_exit"

func _init() -> void:
	call_deferred("run")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--audio-mode="):
			mode = arg.get_slice("=", 1)
	await process_frame
	print("AUDIO_PROBE_MODE ", mode)
	print("AUDIO_PROBE_OBJECTS_BEFORE ", Performance.get_monitor(Performance.OBJECT_COUNT))
	if mode == "autoload_only":
		print("AUDIO_PROBE_FORM_CACHE ", FormScript._cache.size())
		print("AUDIO_PROBE_GUARD_CACHE ", GuardScript._streams.size())
		quit(0)
		return
	var holder := Holder.new()
	holder.name = "AudioProbeHolder"
	holder.mode = mode
	root.add_child(holder)
	if mode == "framed_exit":
		await holder.boot_framed()
	else:
		holder.boot()
	await physics_frame
	print("AUDIO_PROBE_FORM_CACHE ", FormScript._cache.size())
	print("AUDIO_PROBE_GUARD_CACHE ", GuardScript._streams.size())
	print("AUDIO_PROBE_OBJECTS_PLAYING ", Performance.get_monitor(Performance.OBJECT_COUNT))
	print("AUDIO_PROBE_VOICES_PLAYING ", holder.playing_count())
	if mode == "await_release":
		holder.release_refs()
		for _i in range(8):
			await process_frame
		print("AUDIO_PROBE_OBJECTS_AFTER_WAIT ", Performance.get_monitor(Performance.OBJECT_COUNT))
		print("AUDIO_PROBE_FORM_CACHE_AFTER ", FormScript._cache.size())
		print("AUDIO_PROBE_GUARD_CACHE_AFTER ", GuardScript._streams.size())
		print("AUDIO_PROBE_VOICES_AFTER_WAIT ", holder.playing_count())
	elif mode == "stop_wait_keep_cache" or mode == "null_wait_keep_cache":
		holder.form.clear()
		holder.guard.clear()
		if mode == "null_wait_keep_cache":
			for voice in holder.form.voices:
				voice.stream = null
			for voice in holder.guard.voices:
				voice.stream = null
		for _i in range(8):
			await process_frame
		print("AUDIO_PROBE_OBJECTS_AFTER_WAIT ", Performance.get_monitor(Performance.OBJECT_COUNT))
		print("AUDIO_PROBE_FORM_CACHE_AFTER ", FormScript._cache.size())
		print("AUDIO_PROBE_GUARD_CACHE_AFTER ", GuardScript._streams.size())
		print("AUDIO_PROBE_VOICES_AFTER_WAIT ", holder.playing_count())
	quit(0)

class Dummy:
	extends Node
	var fighter_id := "kaia-windrow"

class Holder:
	extends Node
	var mode := ""
	var form
	var guard
	var dummy
	func boot() -> void:
		dummy = Dummy.new()
		dummy.name = "ProbeActor"
		add_child(dummy)
		form = FormScript.new()
		form.name = "ProbeFormAudio"
		add_child(form)
		form.setup(dummy)
		# Same cue edges the transformation clock drives: gather, climax, reveal.
		form.begin("PROBE_FORM", 1)
		form.sample(0.60)
		form.sample(0.90)
		guard = GuardScript.new()
		guard.name = "ProbeGuardAudio"
		add_child(guard)
		guard.setup(dummy)
		guard.play("guard_open")
		guard.play("guard_contact")
		guard.play("guard_break")
	func boot_framed() -> void:
		dummy = Dummy.new()
		dummy.name = "ProbeActor"
		add_child(dummy)
		form = FormScript.new()
		form.name = "ProbeFormAudio"
		add_child(form)
		form.setup(dummy)
		form.begin("PROBE_FORM", 1)
		await get_tree().physics_frame
		form.sample(0.60)
		await get_tree().physics_frame
		form.sample(0.90)
		await get_tree().physics_frame
		guard = GuardScript.new()
		guard.name = "ProbeGuardAudio"
		add_child(guard)
		guard.setup(dummy)
		guard.play("guard_open")
		await get_tree().physics_frame
		guard.play("guard_contact")
		await get_tree().physics_frame
		guard.play("guard_break")
		await get_tree().physics_frame
	func playing_count() -> int:
		var n := 0
		for voice in form.voices:
			if voice.playing:
				n += 1
		for voice in guard.voices:
			if voice.playing:
				n += 1
		return n
	func release_refs() -> void:
		form.clear()
		guard.clear()
		for voice in form.voices:
			voice.stream = null
		for voice in guard.voices:
			voice.stream = null
		FormScript._cache.clear()
		FormScript._levels.clear()
		GuardScript._streams.clear()
		GuardScript._measurements.clear()
	func _exit_tree() -> void:
		print("AUDIO_PROBE_EXIT_MODE ", mode)
		if mode == "production_exit" or mode == "framed_exit":
			# Matches fighter.gd _exit_tree: stop voices, leave cached streams.
			form.clear()
			guard.clear()
		elif mode == "null_streams":
			form.clear()
			guard.clear()
			for voice in form.voices:
				voice.stream = null
			for voice in guard.voices:
				voice.stream = null
		elif mode == "clear_caches":
			release_refs()
		print("AUDIO_PROBE_EXIT_FORM_CACHE ", FormScript._cache.size())
		print("AUDIO_PROBE_EXIT_GUARD_CACHE ", GuardScript._streams.size())
