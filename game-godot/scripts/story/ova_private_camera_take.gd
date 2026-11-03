extends RefCounted

## Opt-in private cinematic camera source. Never loads models, audio or gameplay
## actions. Animation properties are sampled as data; no AnimationPlayer methods
## or callbacks are executed. Private takes are not bundled into the game.
const SCHEMA := "anime.private_camera_library.v1"
const PATHS := ["Camera:focus_mix", "Camera:zoom", "Camera:offset"]
var error := ""
var _base := ""
var _entries: Dictionary = {}
var _canonical: Dictionary = {}
var _animation: Animation
var _bindings: Dictionary = {}
var _cue := ""
var _cue_seconds := 1.0
var _presentation_from: Dictionary = {}
var _last_presentation: Dictionary = {}
const CUE_TRANSITION_SECONDS := 0.3

func load_library(path: String, cues_sha256: String, canonical_nodes: Dictionary) -> bool:
	_entries.clear()
	clear_node()
	error = ""
	if not path.is_absolute_path() or path.begins_with("res://") or path.begins_with("user://"):
		return _reject("Private camera library requires an explicit external absolute path")
	var project_root := ProjectSettings.globalize_path("res://").simplify_path().trim_suffix("/")
	if path.simplify_path().begins_with(project_root + "/"):
		return _reject("Private camera source cannot reside inside the packaged project")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 1048576:
		return _reject("Private camera manifest unavailable or too large")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return _reject("Invalid private camera manifest")
	if parsed.get("schema") != SCHEMA or parsed.get("candidate_only") != true or parsed.get("public_disclosure_authorized") != false:
		return _reject("Private camera candidate/disclosure boundary missing")
	if parsed.get("frame_domain") != "DIALOGUE_CUE_ORDINAL" or parsed.get("gameplay_authority") != false:
		return _reject("Camera take must use dialogue time without gameplay authority")
	if cues_sha256.is_empty() or parsed.get("canonical_cues_sha256") != cues_sha256:
		return _reject("Private camera take does not match canonical cue source")
	if not parsed.get("nodes") is Dictionary:
		return _reject("Missing camera node bindings")
	for entry in parsed["nodes"].values():
		if not entry is Dictionary or not entry.get("ordered_cues") is Array:
			return _reject("Invalid camera node binding")
	_base = path.get_base_dir()
	_canonical = canonical_nodes
	_entries = parsed["nodes"].duplicate(true)
	return true

func select_node(node_id: String) -> bool:
	clear_node()
	if not _entries.has(node_id):
		return false # Unauthored chapters retain the established preview camera.
	var entry: Dictionary = _entries[node_id]
	var canonical: Array = _canonical.get(node_id, {}).get("ordered_cues", [])
	if canonical.is_empty() or entry.get("ordered_cues") != canonical:
		return _reject("Camera cue order differs from canonical node")
	var relative := str(entry.get("path", ""))
	if relative.is_empty() or relative.is_absolute_path() or ".." in relative.split("/") or not relative.ends_with(".tres"):
		return _reject("Invalid relative camera resource path")
	var path := _base.path_join(relative)
	if FileAccess.get_sha256(path) != entry.get("sha256", ""):
		return _reject("Private camera resource hash mismatch")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 131072:
		return _reject("Camera resource unavailable or too large")
	var text := file.get_as_text()
	# Only self-contained native Animation values. External scripts/resources are
	# not part of this content contract and must never be resolved by the loader.
	if not text.begins_with('[gd_resource type="Animation" format=3]') or "ext_resource" in text or "sub_resource" in text or "script" in text:
		return _reject("Camera resource is not a self-contained value animation")
	var resource := ResourceLoader.load(path, "Animation", ResourceLoader.CACHE_MODE_IGNORE) as Animation
	if resource == null or not is_equal_approx(resource.length, float(canonical.size())) or resource.loop_mode != Animation.LOOP_NONE:
		return _reject("Invalid camera animation length or loop")
	if resource.get_track_count() != PATHS.size():
		return _reject("Unexpected camera animation tracks")
	var found := []
	for track in range(resource.get_track_count()):
		var property := str(resource.track_get_path(track))
		if resource.track_get_type(track) != Animation.TYPE_VALUE or property not in PATHS or property in found:
			return _reject("Only unique camera value tracks are permitted")
		found.append(property)
		if resource.track_get_key_count(track) < 2 or not resource.track_is_enabled(track):
			return _reject("Empty or disabled camera track")
		for key in range(resource.track_get_key_count(track)):
			if not _valid_value(property, resource.track_get_key_value(track, key)):
				return _reject("Invalid camera framing value")
	_animation = resource
	for index in range(canonical.size()):
		_bindings[str(canonical[index])] = index
	return true

func begin_cue(cue_id: String, duration_seconds: float) -> void:
	_presentation_from = _last_presentation.duplicate()
	_cue = cue_id if _bindings.has(cue_id) else ""
	_cue_seconds = maxf(duration_seconds, 0.001)
	if _cue.is_empty():
		_presentation_from.clear()
		_last_presentation.clear()

func sample(remaining_seconds: float) -> Dictionary:
	if _animation == null or _cue.is_empty():
		return {}
	# A slow reader/long licensed voice holds this cue's shot. It cannot run the
	# next line's camera early; advance/skip selects that cue explicitly.
	var fraction := clampf(1.0 - remaining_seconds / _cue_seconds, 0.0, 0.94)
	var time := float(_bindings[_cue]) + fraction
	var result := {}
	for track in range(_animation.get_track_count()):
		var property := str(_animation.track_get_path(track))
		var value: Variant = _animation.value_track_interpolate(track, time)
		if not _valid_value(property, value):
			return {}
		result[property.trim_prefix("Camera:")] = value
	return result

func presentation_sample(remaining_seconds: float, reduced_motion := false) -> Dictionary:
	# Preserve the editable native curve. Only the presentation at a cue change
	# eases from its last displayed framing, so advance cannot snap the zoom.
	# Use dialogue time, not a wall clock: pause/long reading holds are stable.
	var target := sample(_cue_seconds if reduced_motion else remaining_seconds)
	if target.is_empty():
		return {}
	if not _presentation_from.is_empty():
		var t := clampf((_cue_seconds - remaining_seconds) / CUE_TRANSITION_SECONDS, 0.0, 1.0)
		var weight := t * t * (3.0 - 2.0 * t)
		for key in ["focus_mix", "zoom", "offset"]:
			target[key] = lerp(_presentation_from[key], target[key], weight)
	_last_presentation = target.duplicate()
	return target

func clear_node() -> void:
	_animation = null
	_bindings.clear()
	_cue = ""
	_presentation_from.clear()
	_last_presentation.clear()

func _valid_value(property: String, value: Variant) -> bool:
	match property:
		"Camera:focus_mix":
			return (value is float or value is int) and is_finite(float(value)) and float(value) >= 0.0 and float(value) <= 1.0
		"Camera:zoom":
			return (value is float or value is int) and is_finite(float(value)) and float(value) >= 0.6 and float(value) <= 2.8
		"Camera:offset":
			return value is Vector2 and value.is_finite() and absf(value.x) <= 150.0 and value.y >= -180.0 and value.y <= 20.0
	return false

func _reject(reason: String) -> bool:
	error = reason
	clear_node()
	return false
