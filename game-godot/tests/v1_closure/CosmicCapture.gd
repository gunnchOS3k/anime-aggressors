extends "res://tests/v1_closure/SpectralCapture.gd"
## Observations only; inherits the unchanged public-input active-CPU driver.
func write_evidence() -> void:
	super.write_evidence()
	if output.is_empty() or not is_instance_valid(battle):return
	var path=output.path_join("combat_capture.json")
	var d:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	d["candidate_kit"]=true;d["native_video_produced"]=false
	d["cosmic_events"]=[battle.fighter1.cosmic_kit_history.duplicate(true),battle.fighter2.cosmic_kit_history.duplicate(true)]
	var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(d,"  "));f.close()
