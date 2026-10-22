extends RefCounted
## Original saved stage structures, rigidly following the existing canonical rig.
## No body scaling/translation, damage, progression or transformation authority.
const _BoneMap = preload("res://scripts/visual/procedural_bone_map.gd")
var actor
var skeleton: Skeleton3D
var document: Dictionary = {}
var _sockets: Array[Node3D] = []
var _installed := ""
var _permanent := ""
var _preview := ""
var _status := "missing"
var _import_kind := ""
var _failures: Array = []

func setup(owner_actor, _model_root: Node3D, rig: Skeleton3D) -> void:
	reset("setup")
	actor = owner_actor;skeleton = rig;document.clear();_failures.clear();_status = "missing"
	if not is_instance_valid(actor) or not is_instance_valid(skeleton):return
	var body := str(actor.data.get("body_variant","male"))
	if actor.model_3d != null:body = str(actor.model_3d._body_variant)
	var path := "res://data/animation/form_acting_8c/%s_%s.json" % [actor.fighter_id,body]
	if not FileAccess.file_exists(path):return
	_status = "unverified"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:return
	if parsed.get("schema","")!="original_form_acting_8c.v1" or parsed.get("fighter_id","")!=actor.fighter_id or parsed.get("body_variant","")!=body:return
	if not parsed.get("source_actions_saved",false) or not parsed.get("source_runtime_verified",false) or parsed.get("human_approved",true):return
	if str(parsed.get("source_saved_blend_sha256","")).length()!=64:return
	document = parsed;_status = "verified_saved_export"

func _release_scene_owner(node: Node) -> void:
	node.owner=null
	for child in node.get_children():_release_scene_owner(child)

func _clear_sockets() -> void:
	for socket in _sockets:
		if is_instance_valid(socket):socket.free()
	_sockets.clear();_installed = ""

func _install(form_id: String) -> void:
	if form_id==_installed:return
	_clear_sockets()
	if not is_instance_valid(skeleton):return
	var info: Dictionary = document.get("attachments",{}).get(form_id,{})
	if info.is_empty():return
	var path := str(info.get("path",""))
	if not path.begins_with("res://assets/characters/form_acting_8c/") or not FileAccess.file_exists(path) or FileAccess.get_sha256(path)!=str(info.get("sha256","")):
		_failures.append("attachment_hash:"+form_id);return
	# Direct Godot glTF import also supports newly installed bounded resources
	# before an editor-wide import. This is real engine parsing of actual GLB.
	var importer := GLTFDocument.new();var state := GLTFState.new()
	var result := importer.append_from_file(path,state)
	if result!=OK:_failures.append("gltf_import:"+str(result));return
	var scene := importer.generate_scene(state)
	if scene==null:_failures.append("gltf_scene:"+form_id);return
	var staged: Array = []
	for part in info.get("parts",[]):
		var group := scene.find_child(str(part.node).validate_node_name(),true,false) as Node3D
		var bone := _BoneMap.resolve_on_skeleton(skeleton,str(part.canonical_bone))
		if group==null or bone.is_empty():
			_failures.append("socket_mapping:"+str(part.node));scene.free();return
		staged.append({"group":group,"bone":bone})
	for part in staged:
		var socket := BoneAttachment3D.new();socket.name="Form8C_"+str(part.bone);socket.bone_name=str(part.bone)
		skeleton.add_child(socket)
		var group: Node3D = part.group
		_release_scene_owner(group)
		group.get_parent().remove_child(group);socket.add_child(group)
		# Group held source rest transform; mesh children already bone-local.
		# BoneAttachment supplies live bone transform exactly once.
		group.transform = Transform3D.IDENTITY
		_sockets.append(socket)
	scene.free();_installed=form_id;_import_kind="Godot_GLTFDocument_actual_saved_resource"

func set_form(form_id: String) -> void:
	_preview = ""
	_permanent = form_id
	if form_id.begins_with("PARTY:") and is_instance_valid(actor):_permanent=str(actor.get_current_form_id())
	_install(_permanent)

func preview_form(target_id: String, progress: float) -> void:
	if progress>=.72:
		_preview=target_id;_install(target_id)
	elif not _preview.is_empty():clear_preview()

func clear_preview() -> void:
	_preview="";_install(_permanent)

func reset(_reason: String) -> void:
	_clear_sockets();_preview="";_permanent=""

func snapshot() -> Dictionary:
	return {"status":_status,"installed_form":_installed,"permanent_form":_permanent,"preview_form":_preview,"sockets":_sockets.size(),"import":_import_kind,"failures":_failures.duplicate(),"source_saved_blend_sha256":document.get("source_saved_blend_sha256",""),"independent_hair_cloth":false,"human_approved":false}
