extends "res://scripts/ui/console_menu_base.gd"

## Digital RC credits — original IP / Path A procedural attribution.

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Credits"
	var body := get_node_or_null("%CreditsBody") as Label
	if body == null:
		body = Label.new()
		body.name = "CreditsBody"
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var vbox := get_node_or_null("VBox")
		if vbox:
			vbox.add_child(body)
	body.text = "\n".join([
		"Anime Aggressors — original characters and stages.",
		"Path A digital launch art/audio: PROCEDURAL_FINAL (internal).",
		"Painted remasters and studio stems: not claimed.",
		"Private/dev digital RC only — no public matchmaking.",
		"Engine: Godot 4.5",
	])


func on_back() -> void:
	SceneRouter.go("main_menu")
