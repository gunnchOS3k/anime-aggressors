extends SceneTree
const Data = preload("res://scripts/data/data_loader.gd")
const Model = preload("res://scripts/fighters/fighter_model_3d.gd")
const Acting = preload("res://scripts/visual/collectible_expression_controller.gd")
var errors: Array = []
var rows: Array = []
func _init() -> void: call_deferred("_run")
func _run() -> void:
	for fid in Data.roster_ids():
		for variant in ["male", "female"]:
			for form in (["BASE", "COSMIC_BOSS"] if fid in ["yin", "yang"] else ["BASE", "BLACK_PUPPET", "WHITE_PUPPET", "PRISMATIC_GRAY"]):
				var data: Dictionary = Data.load_fighter(fid).duplicate(true)
				data["body_variant"] = variant
				data["collectible_review_form"] = form
				var model = Model.new()
				root.add_child(model)
				if not model.configure(data): errors.append("configure:"+fid+variant+form)
				var controller = model.get("_expression_controller")
				if controller == null or controller.meshes.size() < 8:
					errors.append("morph_meshes:"+fid+variant+form)
				else:
					for expression in Acting.EXPRESSIONS:
						model.set_cinematic_expression(expression)
						controller.set_expression(expression, true)
						model._update_expression_for_state("idle")
						if controller.expression != expression:errors.append("acting_override:"+expression)
						var found := false
						for mesh in controller.meshes:
							for i in range(mesh.mesh.get_blend_shape_count()):
								if str(mesh.mesh.get_blend_shape_name(i)) == expression and mesh.get_blend_shape_value(i) > 0:
									found = true
						if not found: errors.append("missing_weight:"+fid+variant+form+expression)
					model.set_cinematic_expression("")
					model._update_expression_for_state("attack_active")
					if controller.expression != "attack_effort": errors.append("combat_face:"+fid)
					rows.append({"fighter_id":fid, "presentation":variant, "form":form, "morph_meshes":controller.meshes.size(), "expressions":Acting.EXPRESSIONS, "cinematic_state_persists":true, "combat_state_resumes":true})
				model.queue_free()
				await process_frame
	var f := FileAccess.open("res://../artifacts/v1_closure/owner_override_face_evidence.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"ok":errors.is_empty() and rows.size()==64, "errors":errors, "rows":rows, "scope":"Real Godot configure and nonzero skinned morph weights for ten expressions on 64 presentations; cinematic acting persists through idle, combat acting resumes. Visual taste remains owner-only.", "owner_approved":false}, "  ")+"\n");f.close()
	print("OWNER_OVERRIDE_FACES ",errors.is_empty(), " rows=",rows.size())
	quit(0 if errors.is_empty() else 1)
