extends "res://scripts/ui/console_menu_base.gd"
## Trials of Convergence hub — first-class player nav (not Labs).

const Catalog = preload("res://scripts/trials/trials_catalog.gd")
const Authority = preload("res://scripts/trials/mode_authority.gd")
const Vxp2BrandScript = preload("res://scripts/vxp2/vxp2_brand.gd")
const Vxp2A11yScript = preload("res://scripts/vxp2/vxp2_accessibility_chrome.gd")

var _rows: Array = []
var _status: Label


func _ready() -> void:
	super._ready()
	Vxp2BrandScript.apply_surface_chrome(self)
	if title_label:
		title_label.text = "Trials of Convergence"
	_rows = Catalog.display_rows()
	_build()
	Vxp2A11yScript.apply(self)


func _build() -> void:
	var vbox = get_node_or_null("Scroll/VBox") as VBoxContainer
	if vbox == null:
		vbox = get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		return
	_status = Label.new()
	_status.name = "Status"
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(420, 64)
	_status.text = "Six Trials · 60 Hz deterministic · never ranked MMR · art/V1 still unapproved"
	vbox.add_child(_status)
	for row in _rows:
		var b: Button = Button.new()
		b.name = "Mode_%s" % str(row.get("id", ""))
		var label: String = str(row.get("title", ""))
		var sub: String = str(row.get("subtitle", ""))
		if not sub.is_empty():
			label = "%s — %s" % [label, sub]
		if str(row.get("label", "")) != "":
			label = "%s [%s]" % [label, row.get("label", "")]
		b.text = label
		b.custom_minimum_size = Vector2(420, 56)
		var mode_id: String = str(row.get("id", ""))
		b.pressed.connect(func() -> void: _open_mode(mode_id))
		vbox.add_child(b)
	var back: Button = Button.new()
	back.name = "BackBtn"
	back.text = "Back"
	back.custom_minimum_size = Vector2(280, 48)
	back.pressed.connect(on_back)
	vbox.add_child(back)
	var first: Control = vbox.get_child(1) as Control
	if first:
		first.grab_focus()


func _open_mode(mode_id: String) -> void:
	GameState.begin_trial(mode_id)
	var key: String = Catalog.scene_key_for(mode_id)
	if key.is_empty():
		push_error("Missing scene_key for trial %s" % mode_id)
		return
	SceneRouter.go(key)


func footer_hint() -> String:
	return "Trials · Confirm · Back · Labs remain diagnostics"


func on_back() -> void:
	GameState.mode = "versus"
	SceneRouter.go("main_menu")
