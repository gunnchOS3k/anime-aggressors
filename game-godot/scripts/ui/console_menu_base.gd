extends Control
class_name ConsoleMenuBase

@onready var footer: Label = %FooterHint
@onready var title_label: Label = %Title

func _ready() -> void:
	focus_default()
	if footer:
		footer.text = footer_hint()

func footer_hint() -> String:
	return "[A] Confirm   [B] Back   Anime Aggressors — Godot Primary Runtime"

func focus_default() -> void:
	var first := find_focusable(self)
	if first:
		first.grab_focus()

func find_focusable(node: Node) -> Control:
	if node is Button and (node as Button).visible:
		return node
	for c in node.get_children():
		var found := find_focusable(c)
		if found:
			return found
	return null

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var nav := get_node_or_null("/root/NavigationAuthority")
		if nav != null and nav.has_method("handle_back"):
			nav.handle_back("ui_cancel")
		else:
			on_back()
		get_viewport().set_input_as_handled()

func on_back() -> void:
	SceneRouter.go("main_menu")
