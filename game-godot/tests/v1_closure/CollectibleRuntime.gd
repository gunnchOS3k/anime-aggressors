extends SceneTree
const Model = preload("res://scripts/fighters/fighter_model_3d.gd")
const Data = preload("res://scripts/data/data_loader.gd")
const Feedback = preload("res://scripts/combat/combat_feedback.gd")
const Sfx = preload("res://scripts/audio/v1_candidate_sfx.gd")
const Bank = preload("res://scripts/audio/procedural_audio_bank.gd")
var failures: Array = []
var rows: Array = []

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func _run() -> void:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://../artifacts/v1_closure/review/asset_manifest.json"))
	check(manifest is Dictionary, "manifest_readable")
	check(manifest.get("assets", []).size() == 64, "64_required_presentations")
	for asset in manifest.get("assets", []):
		var fid: String = asset.fighter_id
		var data := Data.load_fighter(fid).duplicate(true)
		data["collectible_review_form"] = asset.form
		var model := Model.new()
		root.add_child(model)
		check(model.configure(data, asset.presentation), "configure:" + asset.path)
		await process_frame
		var flags := model.truth_flags()
		check(flags.CURRENT_MODEL_SOURCE == "COLLECTIBLE_V1_CANDIDATE", "source:" + asset.path)
		check(flags.VISIBLE_SKELETON_PRESENT, "skeleton:" + asset.path)
		check(not flags.FINAL_CHARACTER_ART_PASS, "approval_false:" + asset.path)
		var skeleton: Skeleton3D = model.get("_visible_skeleton")
		check(skeleton != null and skeleton.get_bone_count() == 22, "22_bones:" + asset.path)
		var controller = model.get("_animation_controller")
		var clips: Array = controller.get_loaded_clip_names()
		for clip in ["idle_primary", "run_loop", "jab", "heavy", "side_special", "aura_burst", "aerial_back", "victory", "defeat"]:
			check(clip in clips, "clip:" + asset.path + ":" + clip)
		controller.play_for_state("attack_startup", {"move_id":"jab_1"})
		await process_frame
		check(controller.get_active_clip() == "jab", "active_jab:" + asset.path)
		rows.append({"fighter_id":fid,"presentation":asset.presentation,"form":asset.form,"flags":flags,"bones":skeleton.get_bone_count(),"loaded_clips":clips.size(),"active_clip":controller.get_active_clip()})
		print("MODEL_CHECK ", fid, " ",asset.presentation," ",asset.form," clips=",clips.size())
		model.queue_free()
		await process_frame
	for fid in ["ember-vale","rook-ironside","juno-spark","kaia-windrow","nix-calder","orion-vell","vesper-nyx","yin","yang"]:
		for event in ["whiff","light","heavy","signature","special","super_startup","super_impact","block","launch","ko","select","transform","black_puppet","white_puppet","prismatic"]:
			check(Bank.load_stream("res://assets/audio/collectible_v1/%s/%s.wav" % [fid,event]) != null, "audio:" + fid + ":" + event)
	var fb := Feedback.new()
	root.add_child(fb)
	var blocked := fb.apply_hit(null, null, {"feedback":{"tier":"super","sfx_event":"super","camera_event":"super"}}, {"blocked":true,"launch":Vector2.ZERO})
	check(blocked.sfx_event == "block" and blocked.camera_event == "" and blocked.vfx_event == "shield_flash", "block_is_not_super_impact")
	fb.queue_free()
	var payload := {"ok":failures.is_empty(),"failures":failures,"rows":rows,"scope":"Godot model configure, 22-bone import, embedded candidate playback, 135 WAV loads and block feedback classification. Not complete battle paths, authored animation or visual taste approval.","V1_AUTOMATED_READY":false,"V1_ANIME_HUMAN_PASS":false}
	var f := FileAccess.open("res://../artifacts/v1_closure/collectible_runtime_evidence.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(payload,"  ")+"\n");f.close()
	print("COLLECTIBLE_RUNTIME ", "PASS" if failures.is_empty() else "FAIL", " rows=",rows.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
