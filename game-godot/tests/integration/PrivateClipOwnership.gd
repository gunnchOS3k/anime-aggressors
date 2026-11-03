extends SceneTree
## Bone-track admission tests only; not original mesh/native art acceptance.
const Art = preload("res://scripts/visual/private_battle_art.gd")
var failures: Array = []

func _initialize() -> void:
	var definition := {"path":"not-loaded.glb","sha256":"not-loaded","clip":"clip","contact":3,"active_end":5,"last":12}
	var row := {"fighter":"ember-vale","body":"male","root_policy":"GAMEPLAY_ROOT_UNCHANGED","model":definition,"moves":{"jab_1":definition}}
	var doc := {"schema":Art.SCHEMA,"review_only":true,"HUMAN_ART_APPROVED":false,"private_volume_uuid":"7264122E-693D-4719-A42D-F1FAA488C119","rows":[row]}
	check(not Art.candidate_row(doc,"ember-vale","male").is_empty(),"Typed candidate metadata admitted without reading assets")
	check(Art.candidate_row(doc,"ember-vale","female").is_empty(),"Wrong body identity rejected")
	doc.rows=[row,row]
	check(Art.candidate_row(doc,"ember-vale","male").is_empty(),"Ambiguous body identity rejected")
	doc.rows=[42]
	check(Art.candidate_row(doc,"ember-vale","male").is_empty(),"Malformed row rejected without an exception")
	var source := actor("Source","Rig")
	var target := actor("Target","OtherRig")
	root.add_child(source);root.add_child(target)
	var a: Skeleton3D=source.get_node("Rig")
	var b: Skeleton3D=target.get_node("OtherRig")
	var pa: AnimationPlayer=source.get_node("Player")
	var pb: AnimationPlayer=target.get_node("Player")
	var clip := Animation.new();clip.length=.2
	var track := clip.add_track(Animation.TYPE_POSITION_3D)
	clip.track_set_path(track,NodePath("Rig:Hips"))
	clip.track_insert_key(track,0.0,Vector3(0,.4,0))
	clip.track_insert_key(track,.2,Vector3(0,.45,0))
	var admitted: Animation=Art.copy_bone_clip(clip,pa,a,pb,b)
	check(admitted!=null,"Own presentation pelvis motion admitted")
	check(str(admitted.track_get_path(0))=="OtherRig:Hips","Track retargets to actual target skeleton")
	var external := clip.duplicate(true) as Animation
	external.track_set_path(0,NodePath(".:position"))
	check(Art.copy_bone_clip(external,pa,a,pb,b)==null,"Actor-root/property writes rejected")
	var methods := Animation.new()
	track=methods.add_track(Animation.TYPE_METHOD)
	methods.track_set_path(track,NodePath("Rig"))
	check(Art.copy_bone_clip(methods,pa,a,pb,b)==null,"Method/event tracks cannot inject gameplay")
	var stretched := Animation.new()
	track=stretched.add_track(Animation.TYPE_SCALE_3D)
	stretched.track_set_path(track,NodePath("Rig:D8_Finger"))
	stretched.track_insert_key(track,0.0,Vector3(1.1,1,1))
	check(Art.copy_bone_clip(stretched,pa,a,pb,b)==null,"Anatomical stretching rejected")
	var moved := clip.duplicate(true) as Animation
	moved.track_set_path(0,NodePath("Rig:D8_Finger"))
	check(Art.copy_bone_clip(moved,pa,a,pb,b)==null,"Non-pelvis local translation rejected")
	b.set_bone_rest(0,Transform3D(Basis.IDENTITY,Vector3(0,.5,0)))
	check(Art.copy_bone_clip(clip,pa,a,pb,b)==null,"Wrong bind rejected")
	source.free();target.free()
	if failures.is_empty():print("PRIVATE_CLIP_OWNERSHIP_PASS: retarget/actor-root/event/stretch/bind boundaries")
	else:push_error(JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func actor(label: String, rig_name: String) -> Node3D:
	var model:=Node3D.new();model.name=label
	var rig:=Skeleton3D.new();rig.name=rig_name
	rig.add_bone("Hips");rig.add_bone("D8_Finger");rig.set_bone_parent(1,0)
	rig.set_bone_rest(0,Transform3D(Basis.IDENTITY,Vector3(0,.4,0)))
	rig.set_bone_rest(1,Transform3D(Basis.IDENTITY,Vector3(.2,.2,0)))
	model.add_child(rig)
	var player:=AnimationPlayer.new();player.name="Player";player.root_node=NodePath("..")
	model.add_child(player)
	return model

func check(ok: bool, reason: String) -> void:
	if not ok:failures.append(reason)
