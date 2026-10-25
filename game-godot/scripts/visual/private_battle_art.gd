extends RefCounted
## Explicit local review only. No bundled art, gameplay events or release approval.
const PRIVATE_ROOT := "/Volumes/gunnchos-private-art/"
const SCHEMA := "private_battle_art.v1"
const REST_EPSILON := 0.000001 # Float32 serialization, not a visual/contact tolerance.

static func requested_manifest() -> String:
	if not OS.has_feature("editor"): return ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--private-art-manifest="):
			return arg.trim_prefix("--private-art-manifest=")
	return ""

static func private_path(path: String) -> bool:
	var clean := path.simplify_path()
	if not path.is_absolute_path() or not clean.begins_with(PRIVATE_ROOT): return false
	# Do not follow a symlink out of encrypted storage, even with a valid hash.
	var directory := DirAccess.open("/Volumes")
	if directory == null or directory.is_link("gunnchos-private-art"): return false
	var relative := clean.trim_prefix(PRIVATE_ROOT)
	var parent := PRIVATE_ROOT.trim_suffix("/")
	for piece in relative.split("/", false):
		directory = DirAccess.open(parent)
		if directory == null or directory.is_link(piece): return false
		parent = parent.path_join(piece)
	return FileAccess.file_exists(clean)

static func checked_asset(definition: Dictionary) -> String:
	var path := str(definition.get("path", ""))
	var expected := str(definition.get("sha256", ""))
	if expected.length() != 64 or not private_path(path): return ""
	return path if FileAccess.get_sha256(path) == expected else ""

static func row_for(fighter: String, body: String) -> Dictionary:
	var path := requested_manifest()
	if path.is_empty() or not private_path(path): return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("schema", "") != SCHEMA: return {}
	if data.get("review_only") != true or data.get("HUMAN_ART_APPROVED") != false: return {}
	if data.get("private_volume_uuid", "") != "7264122E-693D-4719-A42D-F1FAA488C119": return {}
	var found: Dictionary = {}
	for row in data.get("rows", []):
		if row.get("fighter", "") != fighter or row.get("body", "") != body: continue
		if not found.is_empty(): return {} # Ambiguous identities are not accepted.
		found = row
	if found.is_empty() or found.get("root_policy", "") != "GAMEPLAY_ROOT_UNCHANGED": return {}
	if checked_asset(found.get("model", {})).is_empty(): return {}
	return found.duplicate(true)

static func gather(node: Node, rigs: Array, players: Array) -> void:
	if node is Skeleton3D: rigs.append(node)
	if node is AnimationPlayer: players.append(node)
	for child in node.get_children(): gather(child, rigs, players)

static func import_model(row: Dictionary) -> Node3D:
	var path := checked_asset(row.get("model", {}))
	if path.is_empty(): return null
	var importer := GLTFDocument.new()
	var state := GLTFState.new()
	if importer.append_from_file(path, state) != OK: return null
	var model := importer.generate_scene(state, 60.0) as Node3D
	if model == null: return null
	var rigs: Array = []; var players: Array = []
	gather(model, rigs, players)
	if rigs.size() != 1 or players.size() != 1:
		model.free(); return null
	model.set_meta("private_original_art", row)
	return model

static func same_bind(a: Skeleton3D, b: Skeleton3D) -> bool:
	if a.get_bone_count() != b.get_bone_count(): return false
	for i in range(a.get_bone_count()):
		var name := a.get_bone_name(i)
		var j := b.find_bone(name)
		if j < 0: return false
		var ap := a.get_bone_parent(i); var bp := b.get_bone_parent(j)
		if (ap < 0) != (bp < 0): return false
		if ap >= 0 and a.get_bone_name(ap) != b.get_bone_name(bp): return false
		var ar := a.get_bone_rest(i); var br := b.get_bone_rest(j)
		if ar.origin.distance_to(br.origin) > REST_EPSILON: return false
		for c in range(3):
			if ar.basis[c].distance_to(br.basis[c]) > REST_EPSILON: return false
	return true

static func copy_bone_clip(source: Animation, source_player: AnimationPlayer, source_rig: Skeleton3D, target_player: AnimationPlayer, target_rig: Skeleton3D) -> Animation:
	if not same_bind(source_rig, target_rig): return null
	var result := source.duplicate(true) as Animation
	var source_root := source_player.get_node(source_player.root_node)
	var target_root := target_player.get_node(target_player.root_node)
	for i in range(result.get_track_count()):
		var type := result.track_get_type(i)
		# Source motion cannot inject audio, methods, damage, root movement or events.
		if type not in [Animation.TYPE_ROTATION_3D, Animation.TYPE_POSITION_3D, Animation.TYPE_SCALE_3D]: return null
		var path := result.track_get_path(i)
		if path.get_subname_count() != 1: return null
		if source_root.get_node_or_null(NodePath(path.get_concatenated_names())) != source_rig: return null
		var bone := str(path.get_subname(0))
		var index := target_rig.find_bone(bone)
		if index < 0: return null
		for k in range(result.track_get_key_count(i)):
			if type == Animation.TYPE_SCALE_3D:
				var scale: Vector3 = result.track_get_key_value(i, k)
				if scale.distance_to(Vector3.ONE) > REST_EPSILON: return null
			if type == Animation.TYPE_POSITION_3D and bone != "Hips":
				var position: Vector3 = result.track_get_key_value(i, k)
				if position.distance_to(target_rig.get_bone_rest(index).origin) > REST_EPSILON: return null
		result.track_set_path(i, NodePath(str(target_root.get_path_to(target_rig))+":"+bone))
	result.loop_mode = Animation.LOOP_NONE
	return result

static func load_clip(definition: Dictionary, target_player: AnimationPlayer, target_rig: Skeleton3D) -> Animation:
	if not definition.has_all(["clip", "contact", "active_end", "last"]): return null
	if not (0 < float(definition.contact) and float(definition.contact) <= float(definition.active_end) and float(definition.active_end) < float(definition.last)): return null
	var path := checked_asset(definition)
	if path.is_empty(): return null
	var importer := GLTFDocument.new(); var state := GLTFState.new()
	if importer.append_from_file(path, state) != OK: return null
	var model := importer.generate_scene(state, 60.0)
	if model == null: return null
	var rigs: Array = []; var players: Array = []
	gather(model, rigs, players)
	var result: Animation = null
	if rigs.size() == 1 and players.size() == 1:
		var player: AnimationPlayer = players[0]
		var requested := str(definition.get("clip", ""))
		for key in player.get_animation_list():
			if str(key).get_file() == requested:
				if result != null: result = null; break
				if absf(player.get_animation(key).length*60.0-float(definition.last)) > .001: break
				result = copy_bone_clip(player.get_animation(key), player, rigs[0], target_player, target_rig)
	model.free()
	return result

static func source_frame(frame: int, move: Dictionary, source: Dictionary) -> float:
	# Resolved gameplay phase clock only; a visual landmark never confirms a hit.
	var start := maxi(1, int(move.get("startup_frames", 1)))
	var active := maxi(1, int(move.get("active_frames", 1)))
	var recovery := maxi(1, int(move.get("recovery_frames", 1)))
	var contact := float(source.contact)
	var active_end := float(source.active_end)
	var last := float(source.last)
	if frame < start: return contact * clampf(float(frame)/float(start), 0, 1)
	if frame <= start+active: return lerpf(contact, active_end, clampf(float(frame-start)/float(active), 0, 1))
	return lerpf(active_end, last, clampf(float(frame-start-active)/float(recovery), 0, 1))
