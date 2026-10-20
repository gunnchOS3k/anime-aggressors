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
	if key == "reduced_particles" and intensity_mode() == "Reduced": return true
	return bool(settings_node.settings.get(key,false)) if settings_node != null else false

func intensity_mode() -> String:
	var settings_node = get_node_or_null("/root/StoryDialogue")
	return str(settings_node.settings.get("vfx_intensity","Balanced")) if settings_node != null else "Balanced"

func density_multiplier() -> float:
	return .2 if option("reduced_particles") else .6 if intensity_mode() == "Balanced" else 1.0

func trim_decoration_budget(max_slots: int) -> void:
	# A live accessibility change retires transient decoration first. Charge,
	# projectile, confirmation and reaction owners keep their natural lifecycle.
	var remaining := active_count()-max_slots
	if remaining <= 0:return
	for i in slots.size():
		if slots[i].active and slots[i].kind in [4,5,6,13,14,15,16,17,18,19]:
			stop_slot(i);remaining-=1
			if remaining<=0:return

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
	# Decoration is admitted first; the authoritative collision remains the last
	# primary confirmation and can evict it when the shared pool is saturated.
	stage_contact(info,defender)
	emit_effect(fid,10 if result == "armor" else 1 if result in ["shield","parry","clash"] else 0,origin,direction,190 if heavy else 140,.26 if heavy else .18,event_id)
	if result == "hit":
		if heavy:emit_effect(fid,16,origin,direction,128,.10,event_id+":confirmed_expression")
		emit_effect(fid,8,defender.global_position+Vector2(0,-24),direction,74,.2,event_id+":hurt",defender)
	return true

func stage_contact(info: Dictionary, context: Node2D) -> bool:
	# The stage surface is queried, never inferred from the model's soles.
	# An airborne hit over empty space cannot paint an imaginary ground plane.
	if not bool(info.get("confirmed_contact",false)) or str(info.get("combat_event_id","")).is_empty() or context==null:return false
	var origin: Vector2=info.get("contact_world",Vector2.INF)
	if not origin.is_finite():return false
	var query:=PhysicsRayQueryParameters2D.create(origin+Vector2.UP*4,origin+Vector2.DOWN*180,1)
	query.collide_with_areas=false
	var surface:=context.get_world_2d().direct_space_state.intersect_ray(query)
	if surface.is_empty() or not surface.collider is StaticBody2D or surface.normal.y>-.6:return false
	var event_id:=str(info.get("combat_event_id",""))+":stage"
	if _seen.has(event_id):return false
	_seen[event_id]=true
	if _seen.size()>256:_seen.erase(_seen.keys()[0])
	var result:=str(info.get("contact_result","hit"))
	var tier:=str(info.get("feedback_tier","light"))
	var special:=str(info.get("move_id","")).contains("special")
	var power:=3 if tier=="super" else 2 if tier in ["heavy","aura"] or special else 1
	if result!="hit":power=1
	var mode:=intensity_mode()
	var mode_scale:=.65 if option("reduced_particles") else 1.2 if mode=="Full" else 1.0
	var extent:=float([0,140,300,420][power])*mode_scale
	var life:=float([0,.32,.58,.8][power])
	if mode=="Reduced" or option("reduced_particles"):life*=.65
	var fid:=str(info.get("attacker_id",""))
	var position: Vector2=surface.position+Vector2.UP*2
	var slot:=emit_effect(fid,18,position,Vector2.RIGHT,extent,life,event_id)
	if slot>=0:
		slots[slot].aspect=Vector2(1,.30)
		slots[slot].mesh.scale=Vector2(extent,extent*.30)
		slots[slot].mesh.material.set_shader_parameter("flash",0.0)
	# Residue is a bounded decoration, never a projectile or damage owner.
	if power>1 and result=="hit" and intensity_mode()!="Reduced" and not option("reduced_particles"):
		var residue:=emit_effect(fid,19,position,Vector2.RIGHT,extent*.75,.85 if power==2 else 1.15,event_id+":residue")
		if residue>=0:
			slots[residue].aspect=Vector2(1,.17)
			slots[residue].mesh.scale=Vector2(extent*.75,extent*.75*.17)
	return slot>=0

func emit_effect(fid: String, kind: int, world: Vector2, direction := Vector2.RIGHT, extent := 64.0, life := .22, event_id := "", follow: Node2D = null) -> int:
	var max_slots := 32 if option("reduced_particles") else LIMIT
	if active_count() >= max_slots:
		# Preserve confirmation and owned emitters ahead of smoke/whiff decoration.
		var victim := -1
		if kind in [0,1,2,7,8,10,12]:
			for i in slots.size():
				# Short expression decorations have no persistent emitter owner.
				# They must yield to the primary collision/defense/KO result.
				if slots[i].active and slots[i].kind in [4,5,6,13,14,15,16,17,18,19]: victim=i;break
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
	slot.merge({"active":true,"age":0.0,"life":life,"fid":fid,"kind":kind,"extent":extent,"world":world,"dir":direction,"seed":seed_value,"follow":weakref(follow) if follow != null else null,"event_id":event_id,"aspect":Vector2.ONE,"strength":1.0},true)
	var mesh: MeshInstance2D = slot.mesh
	# Canvas contract: platform0 < surface1 < fighter display2 < contact25.
	mesh.z_index=-24 if kind in [18,19] else 0
	mesh.show();mesh.global_position=world;mesh.rotation=direction.angle();mesh.scale=Vector2.ONE*extent
	var ink: Color = COLORS[family]
	if kind == 4: ink=Color(.79,.82,.85,.65).lerp(Color(ink.r,ink.g,ink.b,.6),.23)
	slot.base_ink=ink
	if option("high_contrast_vfx"): ink=Color(1,.95,.76) if kind != 4 else Color(.8,.83,.86)
	if option("reduced_flash"): ink.a*=.55
	var parameters := {"family":family,"kind":kind,"phase":0.0,"clock_s":0.0,"seed":seed_value,"accent":ink,"density":density_multiplier(),"flash":0.0 if option("reduced_flash") else 1.0}
	for key in parameters:mesh.material.set_shader_parameter(key,parameters[key])
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

func set_slot_strength(index: int, strength: float) -> void:
	if index < 0 or index >= slots.size() or not slots[index].active: return
	slots[index]["strength"] = clampf(strength, 0.0, 1.0)

func projectile_contact(first: String, second: String, world: Vector2, direction: Vector2, result: String, event_id: String, context: Node2D) -> void:
	# Two original elemental silhouettes, no fighter-hit signal or receipt.
	# Interception itself is confirmed by the fixed-tick projectile resolver.
	var size := 132.0 if result == "mutual_cancel" else 104.0
	emit_effect(first, 1 if result == "mutual_cancel" else 9, world, direction, size, .22, event_id + ":a")
	emit_effect(second, 1 if result == "mutual_cancel" else 0, world, -direction, size * .85, .18, event_id + ":b")
	stage_contact({"confirmed_contact": true, "combat_event_id": event_id, "contact_world": world, "attacker_id": first, "contact_result": "clash", "feedback_tier": "heavy", "damage": 0}, context)

func stop_slot(index: int) -> void:
	if index < 0 or index >= slots.size():return
	slots[index].active=false;slots[index].mesh.hide()

func _process(delta: float) -> void:
	var start := Time.get_ticks_usec()
	var reduced := option("reduced_particles")
	var dimmed := option("reduced_flash")
	var contrast := option("high_contrast_vfx")
	trim_decoration_budget(32 if reduced else LIMIT)
	var density := density_multiplier()
	for slot in slots:
		if not slot.active: continue
		slot.mesh.material.set_shader_parameter("density",density)
		slot.mesh.material.set_shader_parameter("flash",0.0 if dimmed or slot.kind in [18,19] else 1.0)
		var ink: Color=slot.base_ink
		if contrast:ink=Color(1,.95,.76) if slot.kind != 4 else Color(.8,.83,.86)
		if dimmed:ink.a*=.55
		ink.a *= float(slot.get("strength", 1.0))
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
	return {"allocated_meshes":slots.size(),"active_meshes":active_count(),"peak_active_meshes":peak_active,"reused":reused,"dropped":dropped,"max_meshes":LIMIT,"presentation_budget":32 if option("reduced_particles") else LIMIT,"intensity_mode":intensity_mode(),"density_multiplier":density_multiplier(),"analytic_secondary_motes_per_mesh":int(10*density_multiplier()),"cpu_update_us":cpu_update_us.duplicate(),"render_target":"gl_compatibility","gpu_particle_nodes":0}
