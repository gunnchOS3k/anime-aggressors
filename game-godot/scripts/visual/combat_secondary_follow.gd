extends Node
## Small critically damped follow-through on existing accessory meshes only.
## Original additive fallback, not authored cloth simulation or gameplay authority.
var controller: Node
var parts: Array=[]
var offset := 0.0
var speed := 0.0
var previous_chest := Quaternion.IDENTITY
var chest := -1
func setup(model: Node3D, owner_controller: Node) -> void:
	controller=owner_controller
	var sk=controller.get_skeleton()
	chest=sk.find_bone("Chest")
	if chest>=0: previous_chest=sk.get_bone_pose_rotation(chest)
	for node in model.find_children("*","MeshInstance3D",true,false):
		var label: String=node.name.to_lower()
		# Skip scalp, face and rigid combat anatomy. No model/skin replacements.
		if not (label.contains("ponytail") or label.contains("ribbon") or label.contains("hair lifted") or label.contains("flame swirl") or label.contains("coat hem") or label.contains("scarf")): continue
		if parts.size()>=12:break
		parts.append({"node":node,"position":node.position,"weight":.45 if label.contains("ribbon") else .3})
func _process(delta: float) -> void:
	if controller==null or not is_instance_valid(controller) or controller.presentation_frozen: return
	var settings=get_node_or_null("/root/StoryDialogue")
	var reduced: bool=settings!=null and bool(settings.settings.get("reduced_shake",false))
	var dt:=minf(delta,.025)
	if chest>=0:
		var now: Quaternion=controller.get_skeleton().get_bone_pose_rotation(chest)
		var q: Quaternion=previous_chest.inverse()*now
		var impulse:=clampf(q.get_euler().y,-.15,.15)
		speed=clampf(speed-impulse*1.4,-.8,.8); previous_chest=now
	speed+=(-110.0*offset-21.0*speed)*dt
	offset=clampf(offset+speed*dt,-.012,.012)
	if reduced:offset=0;speed=0
	for part in parts:
		if is_instance_valid(part.node):part.node.position=part.position+Vector3(0,0,offset*float(part.weight))
func diagnostics() -> Dictionary:
	return {"accessory_meshes":parts.size(),"offset_m":offset,"limit_m":.012,"scope":"bounded additive original fallback; authored secondary/human acceptance not granted"}
