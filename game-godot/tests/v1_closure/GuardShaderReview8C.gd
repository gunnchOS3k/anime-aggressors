extends SceneTree
## Compact actual Compatibility-renderer shader review; not BattleScene footage.
const Shader8C = preload("res://shaders/elemental_guard_8c.gdshader")
const Renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd")
var output := ""
func _init() -> void:call_deferred("run")
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	root.size=Vector2i(1080,660)
	var background:=ColorRect.new();background.color=Color(.025,.035,.055);background.size=Vector2(1080,660);root.add_child(background)
	var title:=Label.new();title.text="8C ORIGINAL GUARD SHADERS · actual Godot Compatibility · analytical review, not gameplay approval";title.position=Vector2(14,6);root.add_child(title)
	var materials: Array=[]
	for family in range(9):
		var x:=float(family%3)*360;var y:=float(family/3)*205+30
		var label:=Label.new();label.text=Renderer.IDS[family]+"   guard / warning / rupture";label.position=Vector2(x+12,y);root.add_child(label)
		for state in range(3):
			var rect:=ColorRect.new();rect.position=Vector2(x+8+state*112,y+25);rect.size=Vector2(108,150)
			var material:=ShaderMaterial.new();material.shader=Shader8C;rect.material=material
			material.set_shader_parameter("family",family);material.set_shader_parameter("accent",Renderer.COLORS[family]);material.set_shader_parameter("clock_s",.7);material.set_shader_parameter("phase",.22 if state==2 else 0.0)
			material.set_shader_parameter("warning_tier",3.0 if state==1 else 0.0);material.set_shader_parameter("strain",.95 if state==1 else 0.0);material.set_shader_parameter("cue",2.0 if state==2 else 0.0)
			root.add_child(rect);materials.append(material)
	for i in range(8):await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image();var full:=image.save_png(output.path_join("guard_full_actual_renderer.png"))
	for index in materials.size():
		materials[index].set_shader_parameter("density",.28);materials[index].set_shader_parameter("accent",Color(1,.95,.76,.55))
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	var reduced:=root.get_texture().get_image().save_png(output.path_join("guard_reduced_high_contrast_actual_renderer.png"))
	var result: Dictionary={"PASS":full==OK and reduced==OK,"renderer":RenderingServer.get_current_rendering_method(),"video_driver":RenderingServer.get_current_rendering_driver_name(),"images":2,"image_size":[1080,660],"scope":"Actual Godot analytical shield-shader raster, no BattleScene/native gameplay/device/quality approval","human_approved":false}
	var f=FileAccess.open(output.path_join("shader_review_8c.json"),FileAccess.WRITE);f.store_string(JSON.stringify(result,"\t"));f.close();quit(0 if result.PASS else 1)
