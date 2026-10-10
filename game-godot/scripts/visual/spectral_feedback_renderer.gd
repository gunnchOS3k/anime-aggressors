extends Node2D
## Original Compatibility canvas shader meshes. Scene-owned bounded pool; no gameplay writes.
const SHADER = preload("res://shaders/spectral_feedback.gdshader")
const IDS := ["ember-vale","rook-ironside","juno-spark","kaia-windrow","nix-calder","orion-vell","vesper-nyx","yin","yang"]
const COLORS := [Color(1,.31,.035),Color(.79,.56,.28),Color(.34,.84,1),Color(.38,.95,.72),Color(.64,.88,1),Color(.67,.49,1),Color(.88,.38,.87),Color(.48,.39,.67),Color(1,.85,.42)]
const FAMILIES := ["turbulent_combustion","compression_fractures","branching_voltage","open_pressure_crescents","faceted_crystal_lances","collapsing_orbit_nodes","dislocated_phase_seams","subtractive_aperture","constructed_hex_radiance"]
const LIMIT := 96
var slots: Array = []
var history: Array = []
var _seen: Dictionary = {}
var _sequence := 0
var peak_active := 0
var dropped := 0
var reused := 0
var cpu_update_us: Array = []

static func obtain(context: Node) -> Node2D:
	if context == null or not context.is_inside_tree(): return null
	var host: Node = context.get_tree().current_scene
	if host == null: host = context
	while not host is Node2D and host != null: host = host.get_parent()
	if host == null: return null
	var renderer = host.get_node_or_null("SpectralFeedback")
	if renderer == null:
		renderer = load("res://scripts/visual/spectral_feedback_renderer.gd").new()
		renderer.name = "SpectralFeedback"
		host.add_child(renderer)
	return renderer

func _ready() -> void: z_index = 25

func option(key: String) -> bool:
	var settings_node = get_node_or_null("/root/StoryDialogue")
	return bool(settings_node.settings.get(key,false)) if settings_node != null else false

func contact(info: Dictionary, defender: Node2D) -> bool:
	var event_id := str(info.get("combat_event_id",""))
	if event_id.is_empty() or _seen.has(event_id) or not bool(info.get("confirmed_contact",false)): return false
	_seen[event_id] = true
	# Bounded dedupe cache retains the current event IDs, not the entire match.
	if _seen.size() > 256: _seen.erase(_seen.keys()[0])
	var result := str(info.get("contact_result","hit"))
	var fid := str(info.get("attacker_id",""))
	var origin: Vector2 = info.get("contact_world",defender.global_position+Vector2(0,-24))
	var direction: Vector2 = info.get("contact_direction",Vector2.RIGHT)
	var heavy := str(info.get("feedback_tier","light")) in ["heavy","aura","super"]
	emit_effect(fid,10 if result == "armor" else 1 if result in ["shield","parry","clash"] else 0,origin,direction,190 if heavy else 140,.26 if heavy else .18,event_id)
	if result == "hit":
		emit_effect(fid,8,defender.global_position+Vector2(0,-24),direction,74,.2,event_id+":hurt",defender)
	return true

func emit_effect(fid: String, kind: int, world: Vector2, direction := Vector2.RIGHT, extent := 64.0, life := .22, event_id := "", follow: Node2D = null) -> int:
	var max_slots := 32 if option("reduced_particles") else LIMIT
	if active_count() >= max_slots:
		# Preserve confirmation and owned emitters ahead of smoke/whiff decoration.
		var victim := -1
		if kind in [0,1,2,7,8,10,12]:
			for i in slots.size():
				if slots[i].active and slots[i].kind in [4,5,6]: victim=i;break
		if victim>=0: stop_slot(victim)
		else: dropped+=1;return -1
	var index := -1
	for i in slots.size():
		if not slots[i].active: index=i; reused+=1; break
	if index < 0:
		if slots.size() >= max_slots: dropped+=1; return -1
		var mesh := MeshInstance2D.new()
		var quad := QuadMesh.new(); quad.size=Vector2.ONE
		mesh.mesh=quad
		var material := ShaderMaterial.new(); material.shader=SHADER; mesh.material=material
		add_child(mesh)
		slots.append({"mesh":mesh,"active":false}); index=slots.size()-1
	var family := IDS.find(fid)
	if family < 0: family=0
	_sequence+=1
	var seed_value := float((fid+":"+str(kind)+":"+str(_sequence)).hash() & 65535)/997.0
	var slot: Dictionary = slots[index]
	slot.merge({"active":true,"age":0.0,"life":life,"fid":fid,"kind":kind,"extent":extent,"world":world,"dir":direction,"seed":seed_value,"follow":weakref(follow) if follow != null else null,"event_id":event_id},true)
	var mesh: MeshInstance2D = slot.mesh
	mesh.show();mesh.global_position=world;mesh.rotation=direction.angle();mesh.scale=Vector2.ONE*extent
	var ink: Color = COLORS[family]
	if kind == 4: ink=Color(.79,.82,.85,.65).lerp(Color(ink.r,ink.g,ink.b,.6),.23)
	slot.base_ink=ink
	if option("high_contrast_vfx"): ink=Color(1,.95,.76) if kind != 4 else Color(.8,.83,.86)
	if option("reduced_flash"): ink.a*=.55
	for key in {"family":family,"kind":kind,"phase":0.0,"clock_s":0.0,"seed":seed_value,"accent":ink,"density":.2 if option("reduced_particles") else 1.0,"flash":0.0 if option("reduced_flash") else 1.0}:
		mesh.material.set_shader_parameter(key,{"family":family,"kind":kind,"phase":0.0,"clock_s":0.0,"seed":seed_value,"accent":ink,"density":.2 if option("reduced_particles") else 1.0,"flash":0.0 if option("reduced_flash") else 1.0}[key])
	history.append({"kind":kind,"fid":fid,"family":FAMILIES[family],"world":[world.x,world.y],"direction":[direction.x,direction.y],"event_id":event_id,"seed":seed_value,"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),"life":life,"extent":extent})
	if history.size()>2048: history.pop_front()
	peak_active=maxi(peak_active,active_count())
	return index

func update_slot(index: int, world: Vector2, direction: Vector2, extent: float, phase: float = 0.0) -> void:
	if index < 0 or index >= slots.size() or not slots[index].active: return
	var slot: Dictionary=slots[index]
	slot.world=world;slot.dir=direction;slot.extent=extent
	slot.mesh.global_position=world;slot.mesh.rotation=direction.angle();slot.mesh.scale=Vector2.ONE*extent
	slot.mesh.material.set_shader_parameter("phase",phase)

func stop_slot(index: int) -> void:
	if index < 0 or index >= slots.size():return
	slots[index].active=false;slots[index].mesh.hide()

func _process(delta: float) -> void:
	var start := Time.get_ticks_usec()
	var reduced := option("reduced_particles")
	var dimmed := option("reduced_flash")
	var contrast := option("high_contrast_vfx")
	for slot in slots:
		if not slot.active: continue
		slot.mesh.material.set_shader_parameter("density",.2 if reduced else 1.0)
		slot.mesh.material.set_shader_parameter("flash",0.0 if dimmed else 1.0)
		var ink: Color=slot.base_ink
		if contrast:ink=Color(1,.95,.76) if slot.kind != 4 else Color(.8,.83,.86)
		if dimmed:ink.a*=.55
		slot.mesh.material.set_shader_parameter("accent",ink)
		slot.age+=delta
		if slot.follow != null:
			var target = slot.follow.get_ref()
			if target == null: slot.active=false;slot.mesh.hide();continue
			slot.mesh.global_position=target.global_position+Vector2(0,-24)
		if slot.life > 0 and slot.age >= slot.life:
			slot.active=false;slot.mesh.hide();continue
		slot.mesh.material.set_shader_parameter("clock_s",slot.age)
		if slot.life>0: slot.mesh.material.set_shader_parameter("phase",slot.age/slot.life)
	cpu_update_us.append(Time.get_ticks_usec()-start)
	if cpu_update_us.size()>3600:cpu_update_us.pop_front()

func active_count() -> int:
	var n:=0
	for slot in slots:
		if slot.active:n+=1
	return n

func stats() -> Dictionary:
	return {"allocated_meshes":slots.size(),"active_meshes":active_count(),"peak_active_meshes":peak_active,"reused":reused,"dropped":dropped,"max_meshes":LIMIT,"analytic_secondary_motes_per_mesh":2 if option("reduced_particles") else 10,"cpu_update_us":cpu_update_us.duplicate(),"render_target":"gl_compatibility","gpu_particle_nodes":0}
