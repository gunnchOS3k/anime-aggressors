extends "res://tests/v1_closure/SpectralCapture.gd"
## Additional geometry observations on the existing active-CPU input driver.
## No combat, opponent or starting-position overrides.
func observe_contact(attacker: Node, defender: Node, info: Dictionary) -> void:
	super.observe_contact(attacker, defender, info)
	var attack: Rect2 = attacker.hit_resolver._world_bounds(attacker.get_node("Hitbox/HitShape"))
	var hurt: Rect2 = attacker.hit_resolver._world_bounds(defender.get_node("Hurtbox/HurtShape"))
	var overlap := attack.intersection(hurt)
	contacts[-1].merge({"attacker_root": [attacker.position.x, attacker.position.y], "defender_root": [defender.position.x, defender.position.y], "root_separation_px": absf(attacker.position.x - defender.position.x), "attack_bounds": [attack.position.x, attack.position.y, attack.size.x, attack.size.y], "hurt_bounds": [hurt.position.x, hurt.position.y, hurt.size.x, hurt.size.y], "overlap_bounds": [overlap.position.x, overlap.position.y, overlap.size.x, overlap.size.y], "scope": "actual CPU contact; geometry observation only, no exact outer-boundary or human visual acceptance claim"})
