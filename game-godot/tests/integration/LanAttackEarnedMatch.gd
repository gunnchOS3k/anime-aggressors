extends "res://tests/integration/LanTerminalMatch.gd"
## Bounded independently driven ENet seats, no CPU or direct combat mutation.
## Edge positioning, attacks, defense, genuine grabs/throws and recovery input.
var first_contacts: Array = []
var acquisitions: Array = []
var last_body_contacts: Dictionary = {}
var finishing_proof: Dictionary = {}
var terminal_damage: Array = []
var late_contacts := 0
var match_trace: Array = []

func first_match_budget() -> int:
	return 2400

func first_match_started() -> void:
	check(not battle.fighter1.is_cpu and not battle.fighter2.is_cpu, "two_independent_public_input_seats_no_CPU_substitute")
	check(battle.fighter1.damage_percent==0 and battle.fighter2.damage_percent==0, "ordinary_zero_damage_start")
	for actor in [battle.fighter1,battle.fighter2]:
		actor.hit_resolver.hit_confirmed.connect(first_contact)
		actor.koed.connect(first_stock_loss.bind(actor))
		actor.grab_event.connect(func(info):
			if info.get("result", "") == "success": acquisitions.append({"frame":Engine.get_physics_frames(),"slot":actor.slot,"position":[actor.position.x,actor.position.y]}))

func first_contact(attacker, defender, info: Dictionary) -> void:
	if battle._match_finished: late_contacts += 1
	var launch: Vector2 = info.get("actual_launch", Vector2.ZERO)
	var row := {"frame":Engine.get_physics_frames(),"attacker_slot":attacker.slot,"defender_slot":defender.slot,
		"move":info.get("move_id", ""),"result":info.get("contact_result", ""),"event":info.get("combat_event_id", ""),
		"damage":info.get("damage", 0.0),"damage_after":defender.damage_percent,"state":defender.state_machine.current_state,
		"position":[defender.position.x,defender.position.y],"launch":[launch.x,launch.y]}
	first_contacts.append(row)
	if row.result == "hit" and float(row.damage)>0: last_body_contacts[defender.slot] = row.duplicate(true)

func first_stock_loss(actor) -> void:
	var hit: Dictionary = last_body_contacts.get(actor.slot, {})
	if hit.is_empty(): return
	var inside: bool = float(hit.position[0]) >= float(battle.blast.left) and float(hit.position[0]) <= float(battle.blast.right) and float(hit.position[1]) >= float(battle.blast.top) and float(hit.position[1]) <= float(battle.blast.bottom)
	finishing_proof = {"last_contact":hit.duplicate(true),"stock_loss_frame":Engine.get_physics_frames(),"loser":actor.slot,
		"remaining_stocks":actor.stocks,"position":[actor.position.x,actor.position.y],"damage":actor.damage_percent,
		"frames_from_contact":Engine.get_physics_frames()-int(hit.frame),"contact_inside_blast":inside,
		"damage_position_stock_or_winner_injected":false}
	terminal_damage = [battle.fighter1.damage_percent,battle.fighter2.damage_percent]

func drive_host_first_match(frame: int) -> void:
	var p = battle.fighter1; var d = battle.fighter2
	if battle._match_finished: keys([]); return
	if frame % 6 == 0:
		match_trace.append({"frame":Engine.get_physics_frames(),"actors":[{"position":[p.position.x,p.position.y],"velocity":[p.velocity.x,p.velocity.y],"state":p.state_machine.current_state,"damage":p.damage_percent},{"position":[d.position.x,d.position.y],"velocity":[d.velocity.x,d.velocity.y],"state":d.state_machine.current_state,"damage":d.damage_percent}]})
	if p.grabbed_by != null: phase="host_mash_escape"; keys(["attack"] if frame%4<2 else ["jump"]); return
	if p.grabbed_target != null: phase="host_outward_back_throw"; keys(["left","attack"]); return
	# Allow real dash braking distance before the edge. The rejected first
	# driver stopped24px inside the platform with411px/s residual motion and
	# walked off before contact; no attack-earned result was accepted.
	var edge: float = p.platform_center_x-p.platform_half_width+112
	if not p.is_on_floor() and (p.position.x<edge+16 or p.position.y>p.platform_surface_y):
		phase="host_legitimate_air_recovery"
		var action: Array = ["right"]
		if frame%36<2: action.append("jump")
		if p.position.y>p.platform_surface_y and frame%45<2: action.append("up"); action.append("special")
		keys(action); return
	if p.position.x>edge+5: phase="host_edge_positioning"; keys(["left"]); return
	if p.position.x<edge-5: phase="host_edge_spacing"; keys(["right"]); return
	if absf(d.position.x-p.position.x)<65 and absf(d.position.y-p.position.y)<60:
		if p.facing != 1: phase="host_face_opponent"; keys(["right"]); return
		phase="host_real_grab_attempt"; keys(["grab"] if frame%12<2 else []); return
	phase="host_edge_guard"; keys(["shield"] if frame%90<18 else [])

func drive_guest_first_match(snapshot: Dictionary) -> void:
	if not snapshot.get("active",false): keys([]); return
	var f: int = int(snapshot.combat_frame)
	var p: Dictionary = snapshot.actors[1]; var d: Dictionary = snapshot.actors[0]
	var dx: float = float(d.position[0])-float(p.position[0])
	if int(p.get("grab_owner", 0)) > 0: phase="guest_mash_escape"; keys(["jump"] if f%4<2 else ["attack"]); return
	var actor = current_scene.fighter2 if current_scene != null and "fighter2" in current_scene else null
	if actor == null: keys([]); return
	var outside: bool = absf(float(p.position[0])-actor.platform_center_x)>actor.platform_half_width-24 or float(p.position[1])>actor.platform_surface_y+12
	if not p.grounded and outside:
		phase="guest_legitimate_air_recovery"
		var actions: Array = ["right" if float(p.position[0])<actor.platform_center_x else "left"]
		if f%36<3: actions.append("jump")
		if float(p.position[1])>actor.platform_surface_y and f%45<3: actions.append("up"); actions.append("special")
		keys(actions); return
	if absf(dx)>54: phase="guest_approach"; keys(["right" if dx>0 else "left"]); return
	if f%90<12: phase="guest_defensive_guard"; keys(["shield"]); return
	phase="guest_real_melee"; keys(["attack"] if f%32<3 else [])

func first_match_stock_lost() -> bool:
	return battle.fighter1.stocks==0 or battle.fighter2.stocks==0

func expected_first_winner() -> int:
	if side == "host": return int(finishing_proof.get("last_contact", {}).get("attacker_slot", -1))
	return int(first_terminal.get("winner", -1))

func first_match_label() -> String:
	return "ordinary_terminal_stock_loss"

func first_match_scope() -> String:
	return "Two independent public-input seats; bounded edge pressure and resistance/recovery; actual contacts required before stock loss. No CPU, seeded damage, scripted stock removal, fixed winner or walk-off substitute. Headless software acceptance only; no historical rollback."

func validate_first_match() -> void:
	check(not finishing_proof.is_empty(), "actual_opponent_attack_precedes_terminal_stock_loss")
	if finishing_proof.is_empty(): return
	check(finishing_proof.contact_inside_blast and int(finishing_proof.frames_from_contact)<=120 and int(finishing_proof.last_contact.attacker_slot)!=int(finishing_proof.loser) and float(finishing_proof.last_contact.damage)>0 and Vector2(finishing_proof.last_contact.launch[0],finishing_proof.last_contact.launch[1]).length()>0, "real_damage_launch_to_blast_causality")
	check(first_contacts.any(func(row):return row.attacker_slot==2 and float(row.damage)>0), "guest_socket_inputs_earned_real_damage")
	check(not acquisitions.is_empty(), "ordinary_input_grab_acquisition_observed")
	check(late_contacts==0 and terminal_damage==[battle.fighter1.damage_percent,battle.fighter2.damage_percent], "no_contact_after_authoritative_finish")
	check(first_terminal.get("snapshot_boundary", "") == "physics_commit", "finishing_KO_published_only_at_closed_physics_commit")

func first_match_evidence() -> Dictionary:
	return {"contacts":first_contacts,"acquisitions":acquisitions,"finish_proof":finishing_proof,"late_contacts":late_contacts,"inputs":inputs,"trace":match_trace}
