extends Node2D
class_name SkylineArena

@export var build_art_on_ready: bool = true

func _ready() -> void:
	if build_art_on_ready:
		StageArtFactory.build_skyline_layers(self)
		var main := get_node_or_null("MainPlatform") as StaticBody2D
		if main != null:
			StageArtFactory.thicken_platform(main, 40.0)
		for name in ["LeftPlatform", "RightPlatform"]:
			var plat := get_node_or_null(name) as StaticBody2D
			if plat != null:
				StageArtFactory.thicken_platform(plat, 24.0)
