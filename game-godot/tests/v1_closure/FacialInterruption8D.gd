extends "res://tests/v1_closure/FacialPerformance8D.gd"
## Real public opposing attacks; existing throw/grab/hit authority unchanged.
var requested_body := "male"
func configure(p,d,fid: String,_body: String,facing: int) -> void:
	await super.configure(p,d,fid,requested_body,facing)

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.items_enabled=false;gs.hazards_enabled=false;gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	var campaign=root.get_node("CampaignRuntime");var before:=JSON.stringify(campaign.progress)
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	for fid in IDs:
		var forms: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/forms/%s.json" % fid))
		for body in ["male","female"]:
			requested_body=body
			var index:=1 if body=="male" else 2
			await interrupt(p,d,fid,str(forms.form_ladder[index]),str(forms.form_ladder[index-1]))
			var face=p.model_3d._expression_controller
			check(not face.evidence().performance_owned,fid+body+":actual_contact_retires_facial_phase")
			check(face.expression in ["pain","shock"],fid+body+":actual_hurt_expression")
			rows[-1]["body"]=body
			rows[-1]["face_after_real_contact"]=face.evidence()
	check(before==JSON.stringify(campaign.progress),"Story:unchanged")
	release();write_facial(true);quit(0 if failures.is_empty() else 1)
