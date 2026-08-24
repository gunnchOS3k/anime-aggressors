extends RefCounted
## Competitive procedural stage geometry — replaces greybox ColorRect-only platforms.
## Geometry + procedural environment set-dressing are PROCEDURAL_FINAL (not greybox). Painted remasters optional.

const _ProceduralAudio = preload("res://scripts/audio/procedural_audio_bank.gd")

const THEMES := {
	"skyline-arena": {
		"bg": Color(0.05, 0.08, 0.16),
		"platform": Color(0.18, 0.22, 0.34),
		"trim": Color(0.35, 0.72, 1.0),
		"accent": Color(0.55, 0.85, 1.0, 0.35),
		"hazard": Color(0.2, 0.55, 0.95, 0.4),
	},
	"neon-rooftops": {
		"bg": Color(0.08, 0.04, 0.12),
		"platform": Color(0.22, 0.12, 0.28),
		"trim": Color(1.0, 0.35, 0.75),
		"accent": Color(0.95, 0.4, 0.85, 0.32),
		"hazard": Color(1.0, 0.3, 0.7, 0.35),
	},
	"cascade-foundry": {
		"bg": Color(0.12, 0.06, 0.04),
		"platform": Color(0.32, 0.2, 0.12),
		"trim": Color(1.0, 0.55, 0.2),
		"accent": Color(1.0, 0.45, 0.15, 0.3),
		"hazard": Color(1.0, 0.4, 0.1, 0.4),
	},
	"void-pier": {
		"bg": Color(0.03, 0.03, 0.08),
		"platform": Color(0.14, 0.12, 0.24),
		"trim": Color(0.55, 0.35, 1.0),
		"accent": Color(0.45, 0.3, 0.9, 0.28),
		"hazard": Color(0.5, 0.2, 1.0, 0.35),
	},
	"ember-courtyard": {
		"bg": Color(0.1, 0.05, 0.05),
		"platform": Color(0.28, 0.14, 0.12),
		"trim": Color(1.0, 0.4, 0.25),
		"accent": Color(0.95, 0.35, 0.2, 0.3),
		"hazard": Color(0.9, 0.25, 0.15, 0.35),
	},
	"training-grid": {
		"bg": Color(0.06, 0.07, 0.09),
		"platform": Color(0.2, 0.22, 0.26),
		"trim": Color(0.45, 0.85, 0.55),
		"accent": Color(0.35, 0.7, 0.45, 0.25),
		"hazard": Color(0.3, 0.7, 0.4, 0.25),
	},
}


static func build(stage_root: Node2D, stage_data: Dictionary, reduce_motion: bool = false) -> Dictionary:
	for c in stage_root.get_children():
		c.queue_free()
	var stage_id := str(stage_data.get("id", "skyline-arena"))
	var theme: Dictionary = THEMES.get(stage_id, THEMES["skyline-arena"])
	var lighting: Dictionary = stage_data.get("lightingProfile", {})
	var camera: Dictionary = stage_data.get("cameraProfile", {})
	var perf_tier := str(stage_data.get("performanceTier", {}).get("default", "high"))

	_add_background(stage_root, theme, lighting, reduce_motion, perf_tier)
	_add_environment_setdress(stage_root, stage_id, theme, perf_tier, reduce_motion)
	if stage_id == "ember-courtyard":
		_add_ember_golden_slice_layers(stage_root, theme, reduce_motion, perf_tier)
	_add_blast_guides(stage_root, stage_data.get("blastZones", {}), theme)
	var main: Dictionary = stage_data.get("mainPlatform", {})
	_add_platform(stage_root, main, theme, true)
	for p in stage_data.get("sidePlatforms", []):
		_add_platform(stage_root, p, theme, false)
	_add_hazard_sockets(stage_root, stage_data.get("hazardSockets", []), theme)
	_add_spawn_markers(stage_root, stage_data.get("spawnPoints", []), theme)
	_add_a11y_edges(stage_root, main, stage_data)
	_add_preview_plane(stage_root, stage_data)
	var audio_bed: Dictionary = stage_data.get("audioBed", {})
	var bed_path := str(audio_bed.get("path", _ProceduralAudio.stage_bed_path(stage_id)))
	var bed_loaded := _ProceduralAudio.load_stream(bed_path) != null
	if bed_loaded and stage_root.is_inside_tree():
		_ProceduralAudio.play(bed_path, stage_root, -10.0)
	return {
		"stage_id": stage_id,
		"productionStatus": str(stage_data.get("productionStatus", "")),
		"geometry": "PROCEDURAL_FINAL",
		"art": "PROCEDURAL_FINAL",
		"camera": camera,
		"lighting": lighting,
		"performanceTier": stage_data.get("performanceTier", {}),
		"audioBed": audio_bed,
		"audioBedLoaded": bed_loaded,
		"previewLoaded": bool(stage_root.get_meta("preview_loaded", false)),
	}


static func _add_background(root: Node2D, theme: Dictionary, lighting: Dictionary, reduce_motion: bool, perf_tier: String) -> void:
	var bg := Polygon2D.new()
	bg.color = theme.bg
	bg.polygon = PackedVector2Array([
		Vector2(-1200, -700), Vector2(1200, -700), Vector2(1200, 700), Vector2(-1200, 700),
	])
	bg.z_index = -20
	root.add_child(bg)
	# Atmospheric bands (procedural, not placeholder grey slabs).
	if not reduce_motion and perf_tier != "low":
		var count := 4 if perf_tier == "high" else 2
		for i in range(count):
			var band := Polygon2D.new()
			band.color = theme.accent
			var y := -320.0 + i * 110.0
			band.polygon = PackedVector2Array([
				Vector2(-1100, y), Vector2(1100, y + 8), Vector2(1100, y + 28), Vector2(-1100, y + 20),
			])
			band.z_index = -18
			root.add_child(band)
	# Key light wash
	var wash := Polygon2D.new()
	var key := Color(lighting.get("keyColor", "#6688cc"))
	key.a = float(lighting.get("keyAlpha", 0.12))
	wash.color = key
	wash.polygon = PackedVector2Array([
		Vector2(-400, -500), Vector2(600, -520), Vector2(200, 200), Vector2(-500, 180),
	])
	wash.z_index = -15
	root.add_child(wash)


static func _add_platform(root: Node2D, p: Dictionary, theme: Dictionary, is_main: bool) -> void:
	var w := float(p.get("width", 800))
	var h := float(p.get("height", 40))
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, h)
	shape.shape = rect
	body.position = Vector2(float(p.get("x", 0)), float(p.get("y", 280)) + h / 2.0)
	body.add_child(shape)

	# Beveled competitive platform (Polygon2D), not flat grey ColorRect.
	var bevel := 10.0 if is_main else 6.0
	var vis := Polygon2D.new()
	vis.color = theme.platform
	vis.polygon = PackedVector2Array([
		Vector2(-w / 2.0, -h / 2.0 + bevel),
		Vector2(-w / 2.0 + bevel, -h / 2.0),
		Vector2(w / 2.0 - bevel, -h / 2.0),
		Vector2(w / 2.0, -h / 2.0 + bevel),
		Vector2(w / 2.0, h / 2.0),
		Vector2(-w / 2.0, h / 2.0),
	])
	body.add_child(vis)

	var lip := Polygon2D.new()
	lip.color = theme.trim
	lip.polygon = PackedVector2Array([
		Vector2(-w / 2.0 + 4, -h / 2.0),
		Vector2(w / 2.0 - 4, -h / 2.0),
		Vector2(w / 2.0 - 4, -h / 2.0 + 5),
		Vector2(-w / 2.0 + 4, -h / 2.0 + 5),
	])
	body.add_child(lip)

	# Soft under-shadow for readable depth.
	var shadow := Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.35)
	shadow.polygon = PackedVector2Array([
		Vector2(-w / 2.0 + 8, h / 2.0),
		Vector2(w / 2.0 - 8, h / 2.0),
		Vector2(w / 2.0 - 20, h / 2.0 + 14),
		Vector2(-w / 2.0 + 20, h / 2.0 + 14),
	])
	shadow.z_index = -1
	body.add_child(shadow)

	if is_main:
		var grit := Polygon2D.new()
		grit.color = Color(theme.trim.r, theme.trim.g, theme.trim.b, 0.18)
		grit.polygon = PackedVector2Array([
			Vector2(-w / 4.0, -h / 2.0 + 8),
			Vector2(w / 4.0, -h / 2.0 + 8),
			Vector2(w / 5.0, -h / 2.0 + 16),
			Vector2(-w / 5.0, -h / 2.0 + 16),
		])
		body.add_child(grit)

	root.add_child(body)


static func _add_hazard_sockets(root: Node2D, sockets: Array, theme: Dictionary) -> void:
	for s in sockets:
		var node := Polygon2D.new()
		node.color = theme.hazard
		var x := float(s.get("x", 0))
		var y := float(s.get("y", 0))
		var r := float(s.get("radius", 18))
		node.polygon = PackedVector2Array([
			Vector2(x - r, y), Vector2(x, y - r), Vector2(x + r, y), Vector2(x, y + r),
		])
		node.z_index = -5
		node.name = "HazardSocket_%s" % str(s.get("id", "hz"))
		root.add_child(node)


static func _add_spawn_markers(root: Node2D, spawns: Array, theme: Dictionary) -> void:
	for sp in spawns:
		var m := Polygon2D.new()
		m.color = Color(theme.trim.r, theme.trim.g, theme.trim.b, 0.55)
		var x := float(sp.get("x", 0))
		var y := float(sp.get("y", 200))
		m.polygon = PackedVector2Array([
			Vector2(x - 12, y + 8), Vector2(x + 12, y + 8), Vector2(x, y - 10),
		])
		m.z_index = -4
		root.add_child(m)


static func _add_blast_guides(root: Node2D, blast: Dictionary, theme: Dictionary) -> void:
	if blast.is_empty():
		return
	var left := float(blast.get("left", -560))
	var right := float(blast.get("right", 560))
	var top := float(blast.get("top", -380))
	var bottom := float(blast.get("bottom", 440))
	var c := Color(theme.trim.r, theme.trim.g, theme.trim.b, 0.15)
	for edge in [
		[Vector2(left, top), Vector2(left, bottom)],
		[Vector2(right, top), Vector2(right, bottom)],
		[Vector2(left, top), Vector2(right, top)],
		[Vector2(left, bottom), Vector2(right, bottom)],
	]:
		var line := Line2D.new()
		line.width = 2.0
		line.default_color = c
		line.add_point(edge[0])
		line.add_point(edge[1])
		line.z_index = -12
		root.add_child(line)


static func _add_a11y_edges(root: Node2D, main: Dictionary, stage_data: Dictionary) -> void:
	if not bool(stage_data.get("a11y", {}).get("highContrastEdges", true)):
		return
	var w := float(main.get("width", 800))
	var h := float(main.get("height", 40))
	var body := Node2D.new()
	body.position = Vector2(float(main.get("x", 0)), float(main.get("y", 280)) + h / 2.0)
	var edge := Line2D.new()
	edge.width = 3.0
	edge.default_color = Color(1, 1, 1, 0.55)
	edge.add_point(Vector2(-w / 2.0, -h / 2.0))
	edge.add_point(Vector2(w / 2.0, -h / 2.0))
	body.add_child(edge)
	root.add_child(body)


static func _add_preview_plane(root: Node2D, stage_data: Dictionary) -> void:
	var preview_path := str(stage_data.get("previewPlaceholder", ""))
	root.set_meta("preview_loaded", false)
	if preview_path.is_empty():
		return
	if not ResourceLoader.exists(preview_path) and not FileAccess.file_exists(preview_path):
		return
	var tex: Texture2D = null
	if ResourceLoader.exists(preview_path):
		tex = load(preview_path) as Texture2D
	if tex == null:
		return
	var sprite := Sprite2D.new()
	sprite.name = "StagePreviewArt"
	sprite.texture = tex
	sprite.centered = true
	sprite.position = Vector2(0, -40)
	sprite.modulate = Color(1, 1, 1, 0.35)
	sprite.z_index = -19
	var sz := tex.get_size()
	if sz.x > 0.0:
		sprite.scale = Vector2(900.0 / sz.x, 320.0 / maxf(1.0, sz.y))
	root.add_child(sprite)
	root.set_meta("preview_loaded", true)


static func _add_environment_setdress(root: Node2D, stage_id: String, theme: Dictionary, perf_tier: String, reduce_motion: bool) -> void:
	## Distinct non-greybox silhouettes per stage (buildings / neon / stacks / piers / lanterns / grid).
	var count := 6 if perf_tier == "high" else (4 if perf_tier == "medium" else 2)
	match stage_id:
		"skyline-arena":
			for i in range(count):
				var tower := Polygon2D.new()
				tower.color = Color(theme.trim.r, theme.trim.g, theme.trim.b, 0.28)
				var x := -520.0 + i * 170.0
				var h := 180.0 + (i % 3) * 55.0
				tower.polygon = PackedVector2Array([
					Vector2(x, 260), Vector2(x + 40, 260), Vector2(x + 40, 260 - h), Vector2(x, 260 - h),
				])
				tower.z_index = -12
				root.add_child(tower)
		"neon-rooftops":
			for i in range(count):
				var bar := Polygon2D.new()
				bar.color = Color(theme.trim.r, theme.trim.g, theme.trim.b, 0.55)
				var x := -480.0 + i * 190.0
				var y := -40.0 + (i % 2) * 70.0
				bar.polygon = PackedVector2Array([
					Vector2(x, y), Vector2(x + 120, y), Vector2(x + 120, y + 10), Vector2(x, y + 10),
				])
				bar.z_index = -12
				root.add_child(bar)
		"cascade-foundry":
			for i in range(mini(count, 4)):
				var stack := Polygon2D.new()
				stack.color = Color(theme.trim.r, theme.trim.g, theme.trim.b, 0.4)
				var x := -360.0 + i * 220.0
				stack.polygon = PackedVector2Array([
					Vector2(x, 260), Vector2(x + 36, 260), Vector2(x + 36, 40), Vector2(x, 40),
				])
				stack.z_index = -12
				root.add_child(stack)
				var cap := Polygon2D.new()
				cap.color = theme.trim
				cap.polygon = PackedVector2Array([
					Vector2(x - 6, 40), Vector2(x + 42, 40), Vector2(x + 42, 28), Vector2(x - 6, 28),
				])
				cap.z_index = -11
				root.add_child(cap)
		"void-pier":
			for i in range(count):
				var post := Polygon2D.new()
				post.color = Color(theme.trim.r, theme.trim.g, theme.trim.b, 0.45)
				var x := -450.0 + i * 180.0
				post.polygon = PackedVector2Array([
					Vector2(x, 320), Vector2(x + 14, 320), Vector2(x + 14, 200), Vector2(x, 200),
				])
				post.z_index = -12
				root.add_child(post)
			var water := Polygon2D.new()
			water.color = Color(theme.accent.r, theme.accent.g, theme.accent.b, 0.22)
			water.polygon = PackedVector2Array([
				Vector2(-700, 300), Vector2(700, 300), Vector2(700, 380), Vector2(-700, 380),
			])
			water.z_index = -14
			root.add_child(water)
		"ember-courtyard":
			for i in range(count):
				var lantern := Polygon2D.new()
				lantern.color = Color(theme.trim.r, theme.trim.g, theme.trim.b, 0.6)
				var x := -400.0 + i * 150.0
				var y := -80.0 + (i % 3) * 35.0
				lantern.polygon = PackedVector2Array([
					Vector2(x, y), Vector2(x + 16, y - 10), Vector2(x + 32, y), Vector2(x + 16, y + 14),
				])
				lantern.z_index = -12
				root.add_child(lantern)
		"training-grid":
			if not reduce_motion:
				for i in range(-6, 7):
					var v := Polygon2D.new()
					v.color = Color(theme.trim.r, theme.trim.g, theme.trim.b, 0.12)
					var x := i * 90.0
					v.polygon = PackedVector2Array([
						Vector2(x, -400), Vector2(x + 2, -400), Vector2(x + 2, 400), Vector2(x, 400),
					])
					v.z_index = -16
					root.add_child(v)
		_:
			pass


static func _add_ember_golden_slice_layers(root: Node2D, theme: Dictionary, reduce_motion: bool, perf_tier: String) -> void:
	## Wave017 Golden Slice stage reconstruction — depth, parallax bands, integrated platforms feel.
	var far := Polygon2D.new()
	far.name = "Wave017GoldenSliceFar"
	far.z_index = -18
	far.color = Color(0.18, 0.06, 0.05, 0.85)
	far.polygon = PackedVector2Array([
		Vector2(-900, 40), Vector2(-500, -80), Vector2(-100, -40), Vector2(300, -100),
		Vector2(700, -50), Vector2(980, 60), Vector2(980, 320), Vector2(-900, 320),
	])
	root.add_child(far)
	var mid := Polygon2D.new()
	mid.name = "Wave017GoldenSliceMid"
	mid.z_index = -14
	mid.color = Color(0.32, 0.12, 0.08, 0.55)
	mid.polygon = PackedVector2Array([
		Vector2(-760, 120), Vector2(-420, 40), Vector2(-40, 90), Vector2(360, 30),
		Vector2(720, 100), Vector2(720, 300), Vector2(-760, 300),
	])
	root.add_child(mid)
	# Warm key wash
	var wash := ColorRect.new()
	wash.name = "EmberKeyWash"
	wash.z_index = -12
	wash.position = Vector2(-700, -400)
	wash.size = Vector2(1400, 900)
	wash.color = Color(1.0, 0.35, 0.18, 0.08 if reduce_motion else 0.12)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(wash)
	# Courtyard pillars (readable boundaries)
	for x in [-480.0, 480.0]:
		var pillar := Polygon2D.new()
		pillar.z_index = -8
		pillar.color = Color(0.22, 0.10, 0.08, 0.92)
		pillar.polygon = PackedVector2Array([
			Vector2(x - 28, 40), Vector2(x + 28, 40), Vector2(x + 36, 300), Vector2(x - 36, 300),
		])
		root.add_child(pillar)
		var flame := Polygon2D.new()
		flame.z_index = -7
		flame.color = Color(1.0, 0.55, 0.2, 0.55)
		flame.polygon = PackedVector2Array([
			Vector2(x - 14, 20), Vector2(x, -30), Vector2(x + 14, 20),
		])
		root.add_child(flame)
	if not reduce_motion and perf_tier != "low":
		var parallax := Node2D.new()
		parallax.name = "EmberParallaxHints"
		parallax.z_index = -16
		for i in 5:
			var ember := Polygon2D.new()
			ember.color = Color(1.0, 0.6, 0.25, 0.25)
			var ox := -600.0 + i * 280.0
			ember.polygon = PackedVector2Array([
				Vector2(ox, -120), Vector2(ox + 18, -160), Vector2(ox + 36, -120),
			])
			parallax.add_child(ember)
		root.add_child(parallax)
