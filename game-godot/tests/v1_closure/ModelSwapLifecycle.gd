extends SceneTree
## Native Compatibility model-only lifecycle fixture. Never touches match/save authority.
const Model = preload("res://scripts/fighters/fighter_model_3d.gd")
const Data = preload("res://scripts/data/data_loader.gd")
var output := ""
var failures: Array = []
var rows: Array = []
var cycles := 3
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func meshes(node: Node) -> Array:
	var result: Array=[]
	if node is MeshInstance3D: result.append(node)
	for child in node.get_children(): result.append_array(meshes(child))
	return result
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg=="--dispose-pilot":cycles=1
	root.get_node("SceneRouter").go("battle")
	await process_frame
	# Standalone presentation, not a Fighter or competitive attempt.
	var model=Model.new();model.position=Vector2(640,400);model.z_index=100;root.add_child(model)
	await process_frame
	var fingerprints: Dictionary={};var node_counts: Dictionary={}
	for cycle in range(cycles):
		for fid in Data.roster_ids():
			for body in ["male","female"]:
				var label: String=fid+":"+body
				var old_body=weakref(model._loaded_model) if model._loaded_model else null
				var old_anim=weakref(model._animation_controller) if model._animation_controller else null
				var old_mat=weakref(model._material_controller) if model._material_controller else null
				check(model.configure(Data.load_fighter(fid),body),label+":configured")
				for i in range(5):await process_frame
				await RenderingServer.frame_post_draw
				check(old_body==null or old_body.get_ref()==null,label+":retired_body")
				check(old_anim==null or old_anim.get_ref()==null,label+":retired_animation_owner")
				check(old_mat==null or old_mat.get_ref()==null,label+":retired_material_owner")
				check(model.is_visible_renderable_body(),label+":visible_body")
				var image: Image=model._viewport.get_texture().get_image()
				var opaque:=0
				if image:
					for y in range(0,image.get_height(),2):
						for x in range(0,image.get_width(),2):
							if image.get_pixel(x,y).a>.08:opaque+=1
				check(opaque>64,label+":native_pixels")
				var materials: Array=[]
				for mesh in meshes(model._loaded_model):
					for surface in range(mesh.mesh.get_surface_count()):
						var material=mesh.get_active_material(surface)
						check(material!=null,label+":active_material")
						materials.append({"mesh":mesh.name,"surface":surface,"class":material.get_class() if material else "NULL","name":material.resource_name if material else "NULL","color":str(material.albedo_color) if material is StandardMaterial3D else "shader"})
				var fingerprint=JSON.stringify(materials)
				var nodes: int=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
				if cycle==0:fingerprints[label]=fingerprint
				else:check(fingerprints[label]==fingerprint,label+":material_identity_preserved")
				if cycle==1:node_counts[label]=nodes
				if cycle==2:check(nodes==node_counts[label],label+":bounded_live_nodes")
				if cycle==0:image.save_png(output.path_join(fid+"_"+body+".png"))
				rows.append({"cycle":cycle,"fighter":fid,"body":body,"native_opaque_samples":opaque,"nodes":nodes,"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"materials":materials,"model_path":model._loaded_model.scene_file_path})
	model.queue_free()
	for i in range(4):await process_frame
	var file=FileAccess.open(output.path_join("model_swap_lifecycle.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"scope":"54native model-only swaps,9fighters x2bodies x3cycles; pixel/material/node ownership, not gameplay or art approval; renderer diagnostics evaluated separately"},"  "));file.close()
	print("MODEL_SWAP_LIFECYCLE ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size());quit(0 if failures.is_empty() else 1)
