extends Node
class_name CombatEvents

signal hit_confirmed(attacker: Node, defender: Node, hit_info: Dictionary)
signal shielded(defender: Node, hit_info: Dictionary)
signal launched(target: Node, launch_velocity: Vector2)
signal ko(target: Node)
signal aura_level_changed(fighter: Node, level: int, current_meter: float)
