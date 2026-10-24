extends "res://tests/v1_closure/PairedHandsRuntime8D2.gd"
## Newly saved interface candidates; public mechanics remain existing authority.
## Idle-target fixtures, not activeCPU/earned play or source-paired grip proof.
func run() -> void:
	root.get_node("GameState").set_meta("source_hands_8d3",true)
	await super.run()

func paired_measure(p,d) -> Dictionary:
	var report: Dictionary=super.paired_measure(p,d)
	report.holder_projection=mesh_observer.projection_3d_observation(p.model_3d)
	report.victim_projection=mesh_observer.projection_3d_observation(d.model_3d)
	report["paired_3d_verified"]=false
	return report
