extends RefCounted
class_name AuthoredClipLoader

## Load a real exported GLB animation and remap onto the live deform skeleton.
## Does not invent JSON keys. Missing GLB → no authored clip.

const _BoneMap = preload("res://scripts/visual/procedural_bone_map.gd")
const _Provenance = preload("res://scripts/visual/animation_provenance.gd")


static func load_into(player: AnimationPlayer, skeleton: Skeleton3D, fighter_id: String, clip: String, skeleton_path: NodePath) -> Dictionary:
	var path := _Provenance.authored_glb_path(fighter_id, clip)
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		return {"ok": false, "status": _Provenance.MISSING, "clip": clip, "path": path}
	var packed: Resource = ResourceLoader.load(path)
	if packed == null:
		return {"ok": false, "status": _Provenance.MISSING, "clip": clip, "path": path, "reason": "load_failed"}
	var instance: Node = null
	if packed is PackedScene:
		instance = (packed as PackedScene).instantiate()
	if instance == null:
		return {"ok": false, "status": _Provenance.MISSING, "clip": clip, "path": path, "reason": "not_packed_scene"}
	var src_player := _find_player(instance)
	var copied := 0
	if src_player != null:
		var lib_names: Array = []
		# Godot 4 AnimationPlayer: get_animation_list includes library prefix.
		for anim_name in src_player.get_animation_list():
			var src := src_player.get_animation(anim_name)
			if src == null:
				continue
			var remapped := _remap(src, skeleton, skeleton_path)
			if remapped == null:
				continue
			var local_name := clip
			if not player.has_animation_library(""):
				player.add_animation_library("", AnimationLibrary.new())
			var lib: AnimationLibrary = player.get_animation_library("")
			if lib.has_animation(local_name):
				lib.remove_animation(local_name)
			lib.add_animation(local_name, remapped)
			copied += 1
			lib_names.append(anim_name)
	instance.queue_free()
	if copied <= 0:
		return {"ok": false, "status": _Provenance.MISSING, "clip": clip, "path": path, "reason": "no_animation_tracks"}
	return {
		"ok": true,
		"status": _Provenance.AUTHORED_WIP,
		"clip": clip,
		"path": path,
		"copied": copied,
		"not_final_art": true,
		"human_approved": false,
	}


static func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_player(child)
		if found:
			return found
	return null


static func _remap(src: Animation, skeleton: Skeleton3D, skeleton_path: NodePath) -> Animation:
	var dst := Animation.new()
	dst.length = src.length
	dst.loop_mode = src.loop_mode
	var wrote := 0
	for i in src.get_track_count():
		if src.track_get_type(i) != Animation.TYPE_ROTATION_3D:
			continue
		var track_path := str(src.track_get_path(i))
		var bone := track_path.get_slice(":", 1)
		if bone.is_empty():
			bone = track_path.get_file()
		var resolved := ""
		if skeleton:
			resolved = _BoneMap.resolve_on_skeleton(skeleton, bone)
			if resolved.is_empty() and skeleton.find_bone(bone) >= 0:
				resolved = bone
		else:
			resolved = bone
		if resolved.is_empty():
			continue
		var idx := dst.add_track(Animation.TYPE_ROTATION_3D)
		dst.track_set_path(idx, NodePath("%s:%s" % [skeleton_path, resolved]))
		for k in src.track_get_key_count(i):
			dst.track_insert_key(idx, src.track_get_key_time(i, k), src.track_get_key_value(i, k))
		wrote += 1
	if wrote <= 0:
		return null
	return dst
