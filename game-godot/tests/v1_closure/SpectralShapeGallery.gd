extends SceneTree
## Isolated shader raster fixture; not battle contact, human quality or combo evidence.
const Renderer=preload("res://scripts/visual/spectral_feedback_renderer.gd")
var output := ""
func _init() -> void:call_deferred("_run")
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var fixture:=Node2D.new();root.add_child(fixture);current_scene=fixture
	var renderer=Renderer.new();fixture.add_child(renderer);renderer.set_process(false)
	var rows: Array=[]
	for i in Renderer.IDS.size():
		var center:=Vector2(160+(i%3)*300,170+floori(float(i)/3.0)*180)
		var slot: int=renderer.emit_effect(Renderer.IDS[i],0,center,Vector2.RIGHT,160,.18,"raster-fixture")
		renderer.slots[slot].mesh.material.set_shader_parameter("phase",.12)
		renderer.slots[slot].mesh.material.set_shader_parameter("clock_s",.06)
		var label:=Label.new();label.text=Renderer.IDS[i];label.position=center+Vector2(-76,78);fixture.add_child(label)
		rows.append({"fighter":Renderer.IDS[i],"center":[center.x,center.y],"extent":160,"family":Renderer.FAMILIES[i],"phase":.12})
	var heading:=Label.new();heading.text="ORIGINAL SHADER RASTER FIXTURE · nine distinct shapes · no battle/quality acceptance";heading.position=Vector2(34,30);fixture.add_child(heading)
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("nine_shape_normal.png"))
	var settings=root.get_node("StoryDialogue")
	settings.set_option("reduced_flash",true);settings.set_option("reduced_particles",true);settings.set_option("high_contrast_vfx",true)
	renderer._process(0)
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("nine_shape_accessible.png"))
	var f=FileAccess.open(output.path_join("raster_fixture.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"rows":rows,"scope":"actual Godot Compatibility shader raster fixture, identical extent/direction/time; not natural battle or human approval"},"  ")+"\n");f.close()
	quit()
