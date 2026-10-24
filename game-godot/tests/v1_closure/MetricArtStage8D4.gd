extends SceneTree
## Offline static source-stage diagnostics. No BattleScene or gameplay claims.
const TILE := Vector2i(512, 512)
const SERIALIZATION_EPSILON_M := 0.00001
var failures: Array = []
var rows: Array = []
var source_folder := ""
var output := ""

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func xyz(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

func collect_meshes(node: Node, result: Dictionary) -> void:
	if node is MeshInstance3D:
		result[String(node.get_meta("source_gltf_node_name", node.name))] = node
	for child in node.get_children():
		collect_meshes(child, result)

func source_equivalence(model: Node3D, expected: Array) -> Dictionary:
	var meshes := {}
	collect_meshes(model, meshes)
	var maximum_error := 0.0
	var samples_checked := 0
	var actual_vertices := 0
	for entry in expected:
		var name := String(entry.mesh)
		check(meshes.has(name), "actual_imported_mesh:" + name)
		if not meshes.has(name):
			continue
		var instance: MeshInstance3D = meshes[name]
		var points: Array[Vector3] = []
		var buckets := {}
		var lo := Vector3(INF, INF, INF)
		var hi := Vector3(-INF, -INF, -INF)
		for surface in instance.mesh.get_surface_count():
			var arrays := instance.mesh.surface_get_arrays(surface)
			for p: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				var q := instance.global_transform * p
				points.append(q)
				lo = lo.min(q)
				hi = hi.max(q)
				var key := Vector3i((q / SERIALIZATION_EPSILON_M).round())
				if not buckets.has(key):
					buckets[key] = []
				buckets[key].append(q)
		actual_vertices += points.size()
		var bounds_error := maxf(lo.distance_to(xyz(entry.minimum_m)), hi.distance_to(xyz(entry.maximum_m)))
		maximum_error = maxf(maximum_error, bounds_error)
		check(bounds_error <= SERIALIZATION_EPSILON_M, "source_bounds:" + name)
		for sample: Array in entry.samples_m:
			var p := xyz(sample)
			var key := Vector3i((p / SERIALIZATION_EPSILON_M).round())
			var nearest := INF
			for x in range(-1, 2):
				for y in range(-1, 2):
					for z in range(-1, 2):
						for q: Vector3 in buckets.get(key + Vector3i(x,y,z), []):
							nearest = minf(nearest, p.distance_to(q))
			maximum_error = maxf(maximum_error, nearest)
			check(nearest <= SERIALIZATION_EPSILON_M, "source_surface_sample:" + name)
			samples_checked += 1
	return {"actual_meshes":meshes.size(), "source_meshes":expected.size(), "surface_samples_checked":samples_checked, "actual_vertices":actual_vertices, "max_serialization_error_m":maximum_error, "scope":"Static evaluated-surface export equivalence only; no animated FK or shipping contact claim"}

func load_snapshot(path: String) -> Node3D:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var result := document.append_from_file(path, state)
	check(result == OK, "GLTFDocument_import:" + path)
	if result != OK:
		return Node3D.new()
	var scene := document.generate_scene(state)
	check(scene is Node3D, "actual_static_scene:" + path)
	# Node names containing punctuation are sanitized by Godot. Bind through
	# the importer's actual node index, never guess or conflate renamed meshes.
	var raw := FileAccess.get_file_as_bytes(path)
	var json_length := raw.decode_u32(12)
	var source: Dictionary = JSON.parse_string(raw.slice(20,20+json_length).get_string_from_utf8())
	for index in source.get("nodes",[]).size():
		var imported := state.get_scene_node(index)
		if imported is MeshInstance3D:
			imported.set_meta("source_gltf_node_name",str(source.nodes[index].get("name",imported.name)))
	return scene as Node3D

func capture(snapshot: Dictionary, quarter: bool, size_m: float) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = TILE
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var model := load_snapshot(source_folder.path_join(snapshot.resource))
	world.add_child(model)
	await process_frame
	var equivalence := source_equivalence(model, snapshot.bounds)
	var lower := Vector3(INF, INF, INF)
	var upper := Vector3(-INF, -INF, -INF)
	for entry: Dictionary in snapshot.bounds:
		lower = lower.min(xyz(entry.minimum_m))
		upper = upper.max(xyz(entry.maximum_m))
	var center := (lower + upper) * 0.5
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.18, 0.21)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.84, 0.9)
	env.ambient_light_energy = 0.7
	environment.environment = env
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	light.light_energy = 0.9
	world.add_child(light)
	# Wire reference only: an opaque floor could conceal penetrating soles.
	var floor := MeshInstance3D.new()
	var grid := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material.albedo_color = Color(0.55,0.62,0.7,0.35)
	grid.surface_begin(Mesh.PRIMITIVE_LINES,material)
	for i in range(-10,11):
		var tick := float(i) * 0.1 # Labelled source-metre guide, not gameplay scale.
		grid.surface_add_vertex(Vector3(center.x-size_m,0,center.z+tick))
		grid.surface_add_vertex(Vector3(center.x+size_m,0,center.z+tick))
		grid.surface_add_vertex(Vector3(center.x+tick,0,center.z-size_m))
		grid.surface_add_vertex(Vector3(center.x+tick,0,center.z+size_m))
	grid.surface_end()
	floor.mesh = grid
	world.add_child(floor)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = size_m
	world.add_child(camera)
	var direction := Vector3(0.8, 0.25, 1).normalized() if quarter else Vector3(0,0,1)
	camera.position = center + direction * size_m * 4
	camera.look_at(center, Vector3.UP)
	camera.current = true
	for i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	var result := {"image":image, "equivalence":equivalence, "view":"three_quarter" if quarter else "side", "camera_size_m":size_m, "floor_stage_y_m":0, "camera_role":"Offline framing; source actors remain unscaled"}
	viewport.queue_free()
	await process_frame
	return result

func run() -> void:
	await process_frame
	var pilot_case := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stage-runtime="):
			source_folder = arg.get_slice("=",1)
		if arg.begins_with("--ordinary-output="):
			output = arg.get_slice("=",1)
		if arg.begins_with("--reference-case="):
			pilot_case = arg.get_slice("=",1)
	check(not source_folder.is_empty() and not output.is_empty(), "explicit_artifact_paths")
	check(DisplayServer.get_name() != "headless", "actual_compatibility_render_required")
	DirAccess.make_dir_recursive_absolute(output)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source_folder.path_join("PRODUCTION_MANIFEST.json")))
	check(manifest.get("complete",false), "completed_source_producer")
	if not pilot_case.is_empty():
		check(manifest.get("reference_scope","") == "SINGLE_CASE_PILOT" and manifest.get("selected_cases",[]) == [pilot_case] and manifest.rows.size() == 1 and manifest.rows[0].case == pilot_case and not manifest.get("full_reference_batch_complete",true), "explicit_single_case_scope")
	else:
		check(manifest.rows.size() == 8, "complete_eight_case_scope")
	if not failures.is_empty():
		quit(1)
		return
	for entry: Dictionary in manifest.rows:
		var sheet := Image.create(TILE.x*3,TILE.y*2,false,Image.FORMAT_RGBA8)
		var observations: Array = []
		for snapshot: Dictionary in entry.snapshots:
			var column := ["open","closed","held"].find(snapshot.state)
			for quarter in [false,true]:
				var result: Dictionary = await capture(snapshot,quarter,float(manifest.reference_camera_size_m))
				sheet.blit_rect(result.image,Rect2i(Vector2i.ZERO,TILE),Vector2i(column*TILE.x,int(quarter)*TILE.y))
				result.erase("image")
				result["state"] = snapshot.state
				observations.append(result)
		var name := String(entry.case) + ".png"
		check(sheet.save_png(output.path_join(name)) == OK,"native_sheet_saved:"+name)
		rows.append({"case":entry.case, "sheet":name, "panels":observations, "source_sha256":entry.saved_source_sha256})
	var file := FileAccess.open(output.path_join("metric_stage_native_8d4.json"),FileAccess.WRITE)
	var execution: Dictionary = manifest.get("private_execution", {})
	file.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures,"observer_sha":OS.get_environment("AA_8D4_SOURCE_SHA"),"execution_environment":execution.get("execution_environment","PRIVATE_GITHUB_ACTIONS"),"execution_workflow_sha":execution.get("execution_workflow_sha"),"execution_recipe_sha":execution.get("execution_recipe_sha"),"renderer":RenderingServer.get_current_rendering_method(),"reference_scope":manifest.get("reference_scope","FULL_REFERENCE_BATCH"),"scope":"Offline art scenes, static imported GLB surface checks and side/three-quarter views. No animated export, BattleScene, public-input, audio or shipping paired-contact evidence.","RUNTIME_PAIRED_CONTACT_VERIFIED":false,"human_approved":false},"\t"))
	file.close()
	quit(0 if failures.is_empty() else 1)
