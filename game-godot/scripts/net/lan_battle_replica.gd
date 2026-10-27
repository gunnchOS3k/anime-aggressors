extends Node
## Presentation of HOST state in the real guest BattleScene. Never simulates
## contacts, movement, damage, timers, meter costs, results or saved progression.
const Spectral = preload("res://scripts/visual/spectral_feedback_renderer.gd")
var battle
var sequence := -1
var applied := 0
var presented_contacts: Dictionary = {}
var _shots: Dictionary = {}
var _targets: Array = []
var _remaining := 0
var sample: Dictionary = {}

func setup(scene) -> void:
	battle = scene
	for actor in [battle.fighter1, battle.fighter2]:
		actor.set_physics_process(false)
		actor.controls_enabled = false
		actor.combat_closed = true # Replicas can never acquire damage authority.
		actor.collision_layer = 0
		actor.collision_mask = 0
		actor.hitbox.monitoring = false
		actor.hitbox.monitorable = false
		actor.hurtbox.monitoring = false
		actor.hurtbox.monitorable = false
		actor.projectile_spawner.clear_all()
	step(0.0)

func step(delta: float) -> void:
	var latest: Dictionary = LanSession.latest
	if latest.is_empty(): return
	var actors: Array = [battle.fighter1, battle.fighter2]
	if int(latest.sequence) != sequence:
		sequence = int(latest.sequence)
		applied += 1
		sample = latest.duplicate(true)
		_targets.clear()
		_remaining = 3 #20Hz host snapshots; bounded interpolation at60Hz.
		for i in range(2):
			var actor = actors[i]
			var row: Dictionary = latest.actors[i]
			_targets.append(Vector2(float(row.position[0]), float(row.position[1])))
			actor.velocity = row.velocity
			actor.damage_percent = float(row.damage)
			actor.stocks = int(row.stocks)
			actor.aura = float(row.aura)
			actor.shield_health = float(row.shield)
			actor.shielding = bool(row.shielding)
			actor.facing = int(row.facing)
			actor.state_machine.current_state = str(row.state) # No enter() side effects.
			actor.state_machine.state_frame = int(row.state_frame)
			actor.state_machine.state_time = float(row.state_time)
			actor._current_move = row.move.duplicate(true)
			actor._throw_direction = str(row.throw_direction)
			actor.grabbed_by = actors[int(row.grab_owner)-1] if int(row.grab_owner) > 0 else null
			actor.grabbed_target = actors[int(row.grab_target)-1] if int(row.grab_target) > 0 else null
			if actor._current_form_id != str(row.form):
				actor._current_form_id = str(row.form)
				actor.model_3d.set_form_id(actor._current_form_id, actor._forms_doc.get("forms", {}).get(actor._current_form_id, {}))
			actor.model_3d.set_facing(actor.facing)
			actor._play_current_animation(str(row.state))
			var controller = actor.model_3d.get_animation_controller()
			if controller != null:
				controller.presentation_frozen = float(row.hitstop) > 0 or bool(latest.paused)
				if row.move_active: controller.synchronize_move(int(row.move_frame), row.move)
				else: controller.synchronize_locomotion(_targets[i], actor.model_3d, bool(row.grounded))
			if actor._guard_presentation != null: actor._guard_presentation.tick(delta)
		battle._time_remaining = float(latest.time_remaining)
		battle._update_timer_label()
		battle._update_hud()
		battle.countdown_label.visible = not bool(latest.active) or bool(latest.closed) or bool(latest.paused)
		if latest.phase == "result":
			battle.countdown_label.text = "%s Wins!" % actors[int(latest.winner)-1].data.get("displayName", "Fighter") if int(latest.winner) in [1,2] else "Match closed"
		elif latest.paused: battle.countdown_label.text = "Host paused"
		elif latest.closed: battle.countdown_label.text = "LAN closed · Back to reconnect"
		else: battle.countdown_label.text = "Host countdown"
		for event in latest.get("contacts", []):
			var id := str(event.get("combat_event_id", ""))
			if id.is_empty() or presented_contacts.has(id): continue
			presented_contacts[id] = true
			if presented_contacts.size() > 256: presented_contacts.erase(presented_contacts.keys()[0])
			var defender = actors[int(event.defender_slot)-1]
			defender.combat_feedback.present_replica_contact(event, defender)
		_update_shots(latest.get("projectiles", []))
	if _remaining > 0:
		for i in range(2): actors[i].position = actors[i].position.lerp(_targets[i], 1.0 / float(_remaining))
		_remaining -= 1

func _update_shots(shots: Array) -> void:
	var keep: Dictionary = {}
	var renderer = Spectral.obtain(battle)
	for row in shots:
		var id := int(row.id)
		keep[id] = true
		if not _shots.has(id): _shots[id] = renderer.emit_effect(str(row.fighter), 3, row.position, row.direction, float(row.extent), -1.0, "lan-shot:%d" % id)
		var slot := int(_shots[id])
		if slot >= 0:
			renderer.update_slot(slot, row.position, row.direction, float(row.extent), 1.0)
			renderer.set_projectile_integrity(slot, int(row.integrity), int(row.initial_integrity))
	for id in _shots.keys():
		if not keep.has(id): renderer.stop_slot(int(_shots[id])); _shots.erase(id)

func _exit_tree() -> void:
	if is_instance_valid(battle):
		var renderer = Spectral.obtain(battle)
		for slot in _shots.values(): renderer.stop_slot(int(slot))
	_shots.clear()
