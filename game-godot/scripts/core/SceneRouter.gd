extends Node

const SCENES := {
	"boot": "res://scenes/boot/BootScene.tscn",
	"main_menu": "res://scenes/menus/MainMenuScene.tscn",
	"mode_select": "res://scenes/menus/ModeSelectScene.tscn",
	"ruleset": "res://scenes/menus/RulesetScene.tscn",
	"fighter_select": "res://scenes/menus/FighterSelectScene.tscn",
	"stage_select": "res://scenes/menus/StageSelectScene.tscn",
	"versus": "res://scenes/menus/VersusScene.tscn",
	"battle": "res://scenes/battle/BattleScene.tscn",
	"pause": "res://scenes/ui/PauseMenuScene.tscn",
	"results": "res://scenes/ui/ResultsScene.tscn",
	"training": "res://scenes/training/TrainingMenuScene.tscn",
	"training_battle": "res://scenes/training/TrainingBattleScene.tscn",
	"settings": "res://scenes/menus/SettingsScene.tscn",
	"controls": "res://scenes/menus/ControlsScene.tscn",
	"labs": "res://scenes/menus/LabsScene.tscn",
	"mobile_playtest": "res://scenes/menus/MobilePlaytestScene.tscn",
}

func go(scene_key: String) -> void:
	if not SCENES.has(scene_key):
		push_error("Unknown scene key: %s" % scene_key)
		return
	var path: String = SCENES[scene_key]
	if not ResourceLoader.exists(path):
		push_error("Scene missing: %s" % path)
		return
	get_tree().change_scene_to_file(path)

func go_battle_setup() -> void:
	go("ruleset")

func go_training() -> void:
	go("training")

func go_mobile_playtest() -> void:
	go("mobile_playtest")
