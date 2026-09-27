extends "res://scripts/ui/console_menu_base.gd"

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Build Info"
	var body := get_node_or_null("%BuildInfoBody") as Label
	if body == null:
		body = Label.new()
		body.name = "BuildInfoBody"
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var vbox := get_node_or_null("VBox")
		if vbox:
			vbox.add_child(body)
	var identity := get_node_or_null("/root/BuildIdentity")
	if identity != null and identity.has_method("display_lines"):
		body.text = "\n".join(identity.display_lines())
	else:
		body.text = "Build identity unavailable."


func footer_hint() -> String:
	return "Review/dev identity. [B] Back"


func on_back() -> void:
	var identity := get_node_or_null("/root/BuildIdentity")
	var target := "settings"
	if identity != null:
		target = str(identity.return_scene)
	if not SceneRouter.SCENES.has(target):
		target = "settings"
	SceneRouter.go(target)
