extends RefCounted
## Original saved stage structures, rigidly following the existing canonical rig.
## No body scaling/translation, damage, progression or transformation authority.
const _BoneMap = preload("res://scripts/visual/procedural_bone_map.gd")
var actor
var model: Node3D
var skeleton: Skeleton3D
var document: Dictionary = {}
var _sockets: Array[Node3D] = []
var _installed := ""
var _permanent := ""
var _preview := ""
var _status := "missing"
var _import_kind := ""
var _failures: Array = []
var _socket_correspondence: Array = []

func setup(owner_actor, _model_root: Node3D, rig: Skeleton3D) -> void:
	reset("setup")
	actor = owner_actor;skeleton = rig;model = _model_root;document.clear();_failures.clear();_status = "missing"
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

func _source_transform(rows: Array) -> Transform3D:
	return Transform3D(Basis(Vector3(rows[0][0],rows[1][0],rows[2][0]),Vector3(rows[0][1],rows[1][1],rows[2][1]),Vector3(rows[0][2],rows[1][2],rows[2][2])),Vector3(rows[0][3],rows[1][3],rows[2][3]))

func _exported_transform(node: Node3D) -> Transform3D:
	var result:=node.transform
	var parent=node.get_parent()
	while parent is Node3D:
		result=parent.transform*result;parent=parent.get_parent()
	return result

func _clear_sockets() -> void:
	for socket in _sockets:
		if is_instance_valid(socket):socket.free()
	_sockets.clear();_socket_correspondence.clear();_installed = ""

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
		var declared_rest:=_source_transform(part.source_rest_transform_godot)
		var exported_rest:=_exported_transform(group)
		var bone_index:=skeleton.find_bone(bone)
		var skeleton_in_model:=model.global_transform.affine_inverse()*skeleton.global_transform
		var imported_rest:=skeleton_in_model*skeleton.get_bone_global_rest(bone_index)
		staged.append({"group":group,"bone":bone,"offset":imported_rest.affine_inverse()*exported_rest,"declared_rest":declared_rest,"imported_rest":imported_rest,"exported_rest":exported_rest})
	for part in staged:
		var socket := BoneAttachment3D.new();socket.name="Form8C_"+str(part.bone);socket.bone_name=str(part.bone)
		skeleton.add_child(socket)
		var group: Node3D = part.group
		_release_scene_owner(group)
		group.get_parent().remove_child(group);socket.add_child(group)
		# Saved socket geometry uses the Blender-exported rest basis; the
		# existing body GLB normalizes its skeletal rest. Preserve their exact
		# measured delta in model space. Never move/scale the body or bones.
		group.transform = part.offset
		var reconstructed: Transform3D=part.imported_rest*group.transform
		var reference: Transform3D=part.exported_rest
		var rest_error:=reconstructed.origin.distance_to(reference.origin)
		for column in range(3):rest_error=maxf(rest_error,reconstructed.basis[column].distance_to(reference.basis[column]))
		_socket_correspondence.append({"form":form_id,"bone":part.bone,"source_rest":part.declared_rest,"exported_rest":part.exported_rest,"imported_rig_rest":part.imported_rest,"local_basis_delta":group.transform,"reconstructed_rest":reconstructed,"rest_max_component_error":rest_error})
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
	return {"status":_status,"installed_form":_installed,"permanent_form":_permanent,"preview_form":_preview,"sockets":_sockets.size(),"import":_import_kind,"socket_correspondence":_socket_correspondence.duplicate(true),"failures":_failures.duplicate(),"source_saved_blend_sha256":document.get("source_saved_blend_sha256",""),"independent_hair_cloth":false,"human_approved":false}
