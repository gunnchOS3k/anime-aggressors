extends RefCounted
class_name ElementalAuraSystem

static func attach(owner: Node, fighter_id: String, socket: Node3D) -> void:
	ElementalVfxFactory.attach_aura(owner, fighter_id, socket)

static func set_charging(socket: Node3D, charging: bool) -> void:
	if socket == null:
		return
	for child in socket.get_children():
		if child is GPUParticles3D:
			(child as GPUParticles3D).emitting = charging
