extends SceneTree
## Technical binding checks only. No original asset, contact or art acceptance.
const Art = preload("res://scripts/visual/private_battle_art.gd")
const Runner = preload("res://scripts/combat/move_runner.gd")
var failures: Array = []
var callbacks: Array = []

func _initialize() -> void:
	var source := {"contact":8.0,"active_end":12.0,"last":30.0}
	for startup in [1,4,7]:
		for active in [1,2,5]:
			var move := {"startup_frames":startup,"active_frames":active,"recovery_frames":9,"move_id":"binding-clock"}
			var runner = Runner.new()
			root.add_child(runner)
			callbacks.clear()
			runner.active_frames_tick.connect(func(_move): callbacks.append({"frame":runner.total_frame,"source":Art.source_frame(runner.total_frame,move,source)}))
			runner.start_move(move,null)
			var previous := -1.0
			while runner.active:
				runner.tick_sim_frame()
				var frame := Art.source_frame(runner.total_frame,move,source)
				check(frame >= previous,"Source clock reversed")
				previous=frame
			check(callbacks.size()==active,"Authoritative callback count")
			check(callbacks[0].frame==startup+1,"Actual first hitbox frame")
			check(callbacks[0].source==source.contact,"First real hitbox callback must sample authored contact")
			check(previous==source.last,"Recovery must reach final source frame")
			runner.free()
	check(not Art.private_path("/tmp/unapproved.glb"),"Public/unprotected path rejected")
	check(not Art.private_path("/Volumes/gunnchos-private-art/../outside.glb"),"Traversal rejected")
	# Rig-bind checks do not require private sources or an imported character.
	var a := Skeleton3D.new();var b := Skeleton3D.new()
	a.add_bone("Hips");b.add_bone("Hips")
	check(Art.same_bind(a,b),"Identical rest accepted")
	b.set_bone_rest(0,Transform3D(Basis.IDENTITY,Vector3(0,.01,0)))
	check(not Art.same_bind(a,b),"Changed bind must be rejected")
	a.free();b.free()
	if failures.is_empty(): print("PRIVATE_ART_CLOCK_PASS: nine real MoveRunner timelines; technical bind checks only")
	else: push_error(JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func check(ok: bool, reason: String) -> void:
	if not ok: failures.append(reason)
