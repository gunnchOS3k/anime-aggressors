extends Node

## Session state for menu → battle flow (autoload).

var p1_fighter_id: String = "ember-vale"
var p2_fighter_id: String = "rook-ironside"
var p2_is_cpu: bool = true
var cpu_level: int = 2
var stage_id: String = "skyline-arena"
var ruleset_id: String = "stock-3"
var stocks: int = 3
var match_timer_seconds: int = 180
var match_type: String = "stock"

var p1_ready: bool = false
var p2_ready: bool = false

var training_dummy_mode: String = "cpu"
var last_winner_slot: int = -1

func reset_match() -> void:
	p1_ready = false
	p2_ready = false
	last_winner_slot = -1

func load_fighter(id: String) -> Dictionary:
	var path := "res://data/fighters/%s.json" % id
	if not FileAccess.file_exists(path):
		push_warning("Missing fighter data: %s" % id)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(f.get_as_text())

func load_stage(id: String) -> Dictionary:
	var path := "res://data/stages/%s.json" % id
	if not FileAccess.file_exists(path):
		push_warning("Missing stage data: %s" % id)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(f.get_as_text())

func roster_ids() -> Array:
	var path := "res://data/fighters/roster.json"
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	return data.get("fighters", [])

func production_stage_ids() -> Array:
	var path := "res://data/stages/production_stages.json"
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	return data.get("stages", [])
