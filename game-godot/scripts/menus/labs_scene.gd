extends "res://scripts/ui/console_menu_base.gd"

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Labs / Experimental — not production"
	var review_btn := Button.new()
	review_btn.name = "RosterArtReview"
	review_btn.text = "Full roster art review"
	review_btn.pressed.connect(func() -> void: SceneRouter.go_roster_art_review())
	add_child(review_btn)
	review_btn.position = Vector2(48, 120)

func footer_hint() -> String:
	return "Not production combat. Use Versus / Training. TypeScript web battle is legacy."

func on_back() -> void:
	SceneRouter.go("main_menu")
