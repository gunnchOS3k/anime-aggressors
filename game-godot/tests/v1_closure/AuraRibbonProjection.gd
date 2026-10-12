extends SceneTree
## Declared meter/pose geometry fixture; public charging is separately captured.
var output := ""
var failures: Array=[]
var rows: Array=[]
func _init() -> void:call_deferred("_run")
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9
	root.get_node("SceneRouter").go("battle")
	for i in range(200):await physics_frame
	var p=current_scene.fighter1;p.controls_enabled=false
	for fid in preload("res://scripts/visual/elemental_body_aura.gd").IDS:
		for body in ["male","female"]:
			for facing in [-1,1]:
				gs.p1_body_variant=body;p.configure(fid,1,false,9,Vector2(-150,240));p.controls_enabled=false;p.facing=facing;p.model_3d.set_facing(facing);p.aura=100
				p.move_runner.cancel();p.state_machine.enter("idle")
				for i in range(8):await physics_frame
				var aura=p.model_3d._body_aura
				var camera: Camera3D=aura.get_viewport().get_camera_3d()
				var view:=camera.global_transform.basis.z.normalized()
				var vertices: PackedVector3Array=aura.mesh.get_faces()
				var widths: Array=[]
				# Every authored ribbon segment is two triangles. The first edge
				# spans the strip width: its projection must not collapse with yaw.
				for i in range(0,vertices.size(),6):
					var width: Vector3=aura.to_global(vertices[i+1])-aura.to_global(vertices[i])
					if width.length()<.00001:continue
					var retained:=sqrt(maxf(0,1-pow(width.normalized().dot(view),2)))
					widths.append(retained)
				var minimum: float=widths.min() if not widths.is_empty() else 0
				if minimum<.99999:failures.append("%s:%s:%d:camera_width_collapses"%[fid,body,facing])
				rows.append({"fighter":fid,"body":body,"facing":facing,"ribbon_width_projection_min":minimum,"ribbon_width_projection_mean":widths.reduce(func(a,b):return a+b,0.0)/maxi(1,widths.size()),"segments":widths.size(),"actual_model_yaw":p.model_3d._model_root.global_rotation.y,"camera_world_view":str(view),"world_bone_anchors":aura.evidence().anchors,"geometry":aura.evidence()})
	var f=FileAccess.open(output.path_join("aura_ribbon_projection.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"scope":"36 staged all-rig/yaw camera-projection fixtures. Unit-width retention criterion follows perpendicular camera-facing ribbon construction; not aesthetic approval, charging or combat evidence."},"  "));f.close()
	print("AURA_RIBBON_PROJECTION ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures.size());quit(0 if failures.is_empty() else 1)
