extends "res://tests/v1_closure/PartyOverdriveRuntime.gd"
## Existing public-input kit fixtures, with actual event-owned audio observation.
var inspected:=0
func write(done: bool) -> void:
	if rows.size()>inspected:
		inspected=rows.size()
		var actor=current_scene.fighter1
		var snapshot: Dictionary=actor._form_audio_8c.snapshot()
		var row: Dictionary=rows[-1];var token:=int(row.state.activation)
		var events: Array=snapshot.history.filter(func(event):return event.target=="PARTY:"+str(token))
		var required: Array=["party_pickup","party_activate","party_reveal","ultimate_prepare","ultimate_release","ultimate_recover","party_expire"]
		if row.item!="prism_heart":required=["party_pickup","party_activate","party_reveal"]
		for name in required:
			check(events.filter(func(event):return event.event==name).size()==1,str(row.fighter)+str(token)+":one_owned_"+name)
		check(int(snapshot.voices)==2,str(row.fighter)+":shared_two_voice_pool")
		rows[-1]["owned_audio"]=snapshot
	var f=FileAccess.open(output.path_join("party_audio_8c.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"failures":failures,"scope":"Existing controlled real BattleScene public pickup/taunt/ultimate/counter/contact fixtures plus actual owned audio; no activeCPU/native/mix/human approval"},"\t"));f.close()
