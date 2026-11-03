extends "res://tests/v1_closure/GrabActingRuntime8B.gd"
## New saved hand models, existing real public grab/throw authority. Idle targets
## and initial geometry are explicit fixtures, never activeCPU or earned proof.
var mesh_observer=preload("res://tests/v1_closure/hand_mesh_observer_8d2.gd").new()
func run() -> void:
	var gs=root.get_node("GameState");gs.set_meta("source_hands_8d2",true)
	for arg in OS.get_cmdline_user_args():
		if arg=="--source-paired-8d2":gs.set_meta("source_paired_8d2",true)
	await super.run()

func setup_pair(p,d,fid: String,body: String,face: int,mixed_bodies: bool=false) -> void:
	mesh_observer.cache.clear()
	await super.setup_pair(p,d,fid,body,face,mixed_bodies)

func paired_measure(p,d) -> Dictionary:
	var report: Dictionary=super.paired_measure(p,d)
	var measured: Dictionary={}
	for side in ["L","R"]:
		var hand: PackedVector2Array=mesh_observer.hull(p.model_3d,"hand",side)
		var nearest:=INF;var arm_rows: Array=[]
		for other in ["L","R"]:
			var arm: PackedVector2Array=mesh_observer.hull(d.model_3d,"arm",other)
			var residual: float=mesh_observer.gap(hand,arm)
			check(residual>=0,"actual_weighted_hand_and_victim_arm_mesh_present")
			if residual>=0:nearest=minf(nearest,residual)
			arm_rows.append({"side":other,"gap_px":residual,"projected_mesh_hull":mesh_observer.points(arm)})
		measured[side]={"nearest_arm_silhouette_gap_px":nearest,"hand_mesh_hull":mesh_observer.points(hand),"victim_meshes":arm_rows}
	var floor: Array=[]
	for actor in [p,d]:
		var bounds: Rect2=actor.hit_resolver._world_bounds(actor.get_node("CollisionShape2D"))
		for side in ["L","R"]:
			var sole: PackedVector2Array=mesh_observer.hull(actor.model_3d,"sole",side);var bottom: float=-INF
			for vertex in sole:bottom=maxf(bottom,vertex.y)
			floor.append({"fighter":actor.fighter_id,"side":side,"on_floor":actor.is_on_floor(),"projected_boot_bottom_px":bottom,"collision_bottom_px":bounds.end.y,"sole_below_collision_bottom_px":bottom-bounds.end.y,"scope":"Below collision bottom is a floor residual only while on_floor; held victim elevation is intentional"})
	check(mesh_observer.issues.is_empty(),"actual_mesh_skin_bindings_valid")
	report.merge({"actual_mesh_projection":measured,"floor_observations":floor,"holder_projection":mesh_observer.projection(p.model_3d),"victim_projection":mesh_observer.projection(d.model_3d),"holder_hand_source":p.model_3d._source_controls_8d.evidence(),"victim_hand_source":d.model_3d._source_controls_8d.evidence(),"mesh_scope":"CPU evaluated weights and actual imported bind matrices; projected hand/arm silhouettes, no hidden bone targets. A zero gap is not3D pressure, occlusion, ordinaryCPU or human art acceptance.","human_approved":false})
	return report
