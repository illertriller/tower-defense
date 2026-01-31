extends Node2D
class_name GameParticles

## Static helper for spawning visual effects
## Call these from anywhere: GameParticles.spawn_*()

# Spawn a death poof at a position
static func spawn_death_poof(tree: SceneTree, pos: Vector2):
	var poof = _create_animated_sprite(tree, pos, "death")
	if poof:
		poof.modulate = Color(1, 0.7, 0.5, 0.9)

# Spawn a gold pickup number floating up
static func spawn_gold_text(tree: SceneTree, pos: Vector2, amount: int):
	var label = Label.new()
	label.text = "+%d" % amount
	label.global_position = pos - Vector2(15, 20)
	label.z_index = 100
	
	var settings = LabelSettings.new()
	settings.font_size = 14
	settings.font_color = Color(1, 0.85, 0.2, 1)
	settings.outline_size = 2
	settings.outline_color = Color(0, 0, 0, 1)
	label.label_settings = settings
	
	tree.root.add_child(label)
	
	var tween = tree.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 40, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

# Spawn frost crystals (when frost tower hits)
static func spawn_frost_hit(tree: SceneTree, pos: Vector2):
	for i in range(4):
		var crystal = _create_particle(tree, pos, Color(0.5, 0.8, 1.0, 0.8), 3.0)
		if crystal:
			var offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
			var tween = tree.create_tween()
			tween.tween_property(crystal, "position", crystal.position + offset + Vector2(0, -20), 0.5)
			tween.parallel().tween_property(crystal, "modulate:a", 0.0, 0.5)
			tween.tween_callback(crystal.queue_free)

# Spawn fire burst (flame tower AoE)
static func spawn_fire_burst(tree: SceneTree, pos: Vector2):
	for i in range(6):
		var spark = _create_particle(tree, pos, Color(1, randf_range(0.3, 0.7), 0.1, 0.9), randf_range(2, 5))
		if spark:
			var offset = Vector2(randf_range(-25, 25), randf_range(-25, 25))
			var tween = tree.create_tween()
			tween.tween_property(spark, "position", spark.position + offset, 0.4)
			tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.4)
			tween.tween_callback(spark.queue_free)

# Spawn poison cloud
static func spawn_poison_cloud(tree: SceneTree, pos: Vector2):
	for i in range(3):
		var cloud = _create_particle(tree, pos, Color(0.3, 0.8, 0.2, 0.6), randf_range(4, 8))
		if cloud:
			var offset = Vector2(randf_range(-10, 10), randf_range(-20, -5))
			var tween = tree.create_tween()
			tween.tween_property(cloud, "position", cloud.position + offset, 0.7)
			tween.parallel().tween_property(cloud, "modulate:a", 0.0, 0.7)
			tween.parallel().tween_property(cloud, "scale", Vector2(2, 2), 0.7)
			tween.tween_callback(cloud.queue_free)

# Spawn explosion (cannon/bomb splash)
static func spawn_explosion(tree: SceneTree, pos: Vector2, radius: float):
	var ring_count = int(radius / 15)
	for i in range(ring_count + 3):
		var angle = randf() * TAU
		var dist = randf() * radius * 0.7
		var offset = Vector2(cos(angle), sin(angle)) * dist
		var color = Color(1, randf_range(0.2, 0.6), 0.0, 0.9)
		var spark = _create_particle(tree, pos + offset, color, randf_range(3, 6))
		if spark:
			var tween = tree.create_tween()
			tween.tween_property(spark, "position", spark.position + offset.normalized() * 10, 0.3)
			tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.3)
			tween.tween_callback(spark.queue_free)

# Spawn holy glow
static func spawn_holy_hit(tree: SceneTree, pos: Vector2):
	var glow = _create_particle(tree, pos, Color(1, 0.95, 0.5, 0.7), 12.0)
	if glow:
		var tween = tree.create_tween()
		tween.tween_property(glow, "scale", Vector2(3, 3), 0.3)
		tween.parallel().tween_property(glow, "modulate:a", 0.0, 0.3)
		tween.tween_callback(glow.queue_free)

# Tower placement poof
static func spawn_build_poof(tree: SceneTree, pos: Vector2):
	for i in range(8):
		var angle = (float(i) / 8.0) * TAU
		var offset = Vector2(cos(angle), sin(angle)) * 20
		var dust = _create_particle(tree, pos, Color(0.7, 0.65, 0.5, 0.7), randf_range(2, 4))
		if dust:
			var tween = tree.create_tween()
			tween.tween_property(dust, "position", dust.position + offset, 0.4)
			tween.parallel().tween_property(dust, "modulate:a", 0.0, 0.4)
			tween.tween_callback(dust.queue_free)

# === Internal helpers ===

static func _create_particle(tree: SceneTree, pos: Vector2, color: Color, size: float) -> Node2D:
	var node = Node2D.new()
	node.global_position = pos
	node.z_index = 50
	tree.root.add_child(node)
	
	# We can't draw directly on a static-created node easily,
	# so use a ColorRect as a simple particle
	var rect = ColorRect.new()
	rect.size = Vector2(size, size)
	rect.position = -Vector2(size/2, size/2)
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(rect)
	
	return node

static func _create_animated_sprite(tree: SceneTree, pos: Vector2, type: String) -> AnimatedSprite2D:
	var sprite = AnimatedSprite2D.new()
	sprite.global_position = pos
	sprite.z_index = 50
	
	# Try to load death poof sheet
	var sheet_path = "res://assets/sprites/effects/death_poof_sheet.png"
	if type == "death" and ResourceLoader.exists(sheet_path):
		var frames = SpriteFrames.new()
		frames.remove_animation("default")
		frames.add_animation("poof")
		
		var sheet = load(sheet_path)
		var img = sheet.get_image()
		for i in range(4):
			var frame_img = Image.create(64, 64, false, img.get_format())
			frame_img.blit_rect(img, Rect2i(i * 64, 0, 64, 64), Vector2i(0, 0))
			frames.add_frame("poof", ImageTexture.create_from_image(frame_img))
		
		frames.set_animation_speed("poof", 10.0)
		frames.set_animation_loop("poof", false)
		sprite.sprite_frames = frames
		sprite.play("poof")
		
		tree.root.add_child(sprite)
		sprite.animation_finished.connect(sprite.queue_free)
		return sprite
	
	# Fallback: simple colored circle that fades
	var node = Node2D.new()
	node.global_position = pos
	node.z_index = 50
	tree.root.add_child(node)
	
	# Create expanding ring effect
	for i in range(5):
		var rect = ColorRect.new()
		var s = randf_range(4, 8)
		rect.size = Vector2(s, s)
		rect.position = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		rect.color = Color(1, 0.4, 0.1, 0.8)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(rect)
	
	var tween = tree.create_tween()
	tween.tween_property(node, "scale", Vector2(2.5, 2.5), 0.3)
	tween.parallel().tween_property(node, "modulate:a", 0.0, 0.3)
	tween.tween_callback(node.queue_free)
	
	return null
