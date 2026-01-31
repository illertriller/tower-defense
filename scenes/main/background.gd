extends Node2D

## Draws continuous terrain background with themed environmental details
## PRD: "Grass field as continuous background layer (NOT grid-tied squares/circles)"
## Each level has unique terrain + scattered decorative details

var terrain_texture: Texture2D
var decorations: Array = []  # [{pos, type, size, color, ...}]

func _ready():
	var theme = LevelData.get_terrain_theme(GameManager.current_level)
	_generate_terrain(theme)
	_generate_decorations(GameManager.current_level, theme)
	queue_redraw()

func _generate_terrain(theme: Dictionary):
	var w = 320
	var h = 180
	var img = Image.create(w, h, false, Image.FORMAT_RGB8)
	
	var noise = FastNoiseLite.new()
	noise.seed = GameManager.current_level * 42
	noise.frequency = 0.025
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	var detail_noise = FastNoiseLite.new()
	detail_noise.seed = GameManager.current_level * 137
	detail_noise.frequency = 0.06
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	var base_color: Color = theme.grass
	var var_color: Color = theme.grass_var
	
	for x in range(w):
		for y in range(h):
			var n1 = (noise.get_noise_2d(x, y) + 1.0) * 0.5
			var n2 = (detail_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var blend = clampf(n1 * 0.7 + n2 * 0.3, 0.0, 1.0)
			var color = base_color.lerp(var_color, blend)
			img.set_pixel(x, y, color)
	
	img.resize(1280, 720, Image.INTERPOLATE_BILINEAR)
	terrain_texture = ImageTexture.create_from_image(img)

func _generate_decorations(level: int, theme: Dictionary):
	decorations.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = level * 7919  # Consistent per level
	
	# Get path segments to avoid placing decorations on the road
	var path_points = LevelData.get_path_points(level)
	
	var count = 80  # Number of decoration attempts
	
	for i in range(count):
		var pos = Vector2(rng.randf_range(30, 1250), rng.randf_range(30, 690))
		
		# Skip if too close to any path segment
		if _near_path(pos, path_points, 55.0):
			continue
		
		# Skip if too close to edges (HUD areas)
		if pos.y < 45 or pos.y > 680:
			continue
		
		var deco = _make_decoration(level, rng, pos, theme)
		if deco.size() > 0:
			decorations.append(deco)

func _make_decoration(level: int, rng: RandomNumberGenerator, pos: Vector2, theme: Dictionary) -> Dictionary:
	match level:
		1:  # Valley — grass tufts, flowers, small rocks
			var roll = rng.randf()
			if roll < 0.45:
				return {"pos": pos, "type": "grass_tuft", "height": rng.randf_range(6, 14),
						"color": theme.grass_var.darkened(rng.randf_range(0.0, 0.2))}
			elif roll < 0.75:
				var flower_colors = [Color(0.9, 0.3, 0.3), Color(0.9, 0.85, 0.2), Color(0.6, 0.3, 0.8), Color(0.95, 0.95, 0.95)]
				return {"pos": pos, "type": "flower", "color": flower_colors[rng.randi() % flower_colors.size()],
						"stem_h": rng.randf_range(5, 10)}
			else:
				return {"pos": pos, "type": "rock", "size": rng.randf_range(3, 7),
						"color": Color(0.5, 0.48, 0.44).darkened(rng.randf_range(0.0, 0.2))}
		
		2:  # Crossing — dry grass, fallen leaves, hay bales
			var roll = rng.randf()
			if roll < 0.4:
				return {"pos": pos, "type": "grass_tuft", "height": rng.randf_range(6, 12),
						"color": Color(0.55, 0.45, 0.15).darkened(rng.randf_range(0.0, 0.15))}
			elif roll < 0.7:
				var leaf_colors = [Color(0.8, 0.35, 0.1), Color(0.85, 0.55, 0.1), Color(0.7, 0.25, 0.08)]
				return {"pos": pos, "type": "leaf", "color": leaf_colors[rng.randi() % leaf_colors.size()],
						"rot": rng.randf_range(0, TAU)}
			elif roll < 0.85:
				return {"pos": pos, "type": "rock", "size": rng.randf_range(3, 6),
						"color": Color(0.55, 0.48, 0.35).darkened(rng.randf_range(0.0, 0.15))}
			else:
				return {"pos": pos, "type": "hay_bale", "size": rng.randf_range(8, 14),
						"color": Color(0.7, 0.6, 0.25)}
		
		3:  # Spiral — mushrooms, moss patches, ferns
			var roll = rng.randf()
			if roll < 0.35:
				var cap_colors = [Color(0.7, 0.15, 0.1), Color(0.6, 0.5, 0.2), Color(0.4, 0.25, 0.5)]
				return {"pos": pos, "type": "mushroom",
						"cap_color": cap_colors[rng.randi() % cap_colors.size()],
						"size": rng.randf_range(4, 8)}
			elif roll < 0.6:
				return {"pos": pos, "type": "moss", "size": rng.randf_range(8, 18),
						"color": Color(0.12, 0.28, 0.15, 0.5)}
			elif roll < 0.85:
				return {"pos": pos, "type": "fern", "size": rng.randf_range(6, 12),
						"color": Color(0.1, 0.3, 0.12)}
			else:
				return {"pos": pos, "type": "rock", "size": rng.randf_range(3, 8),
						"color": Color(0.3, 0.3, 0.28).darkened(rng.randf_range(0.0, 0.15))}
		
		4:  # Serpent — cacti, bones, sand ripples, rocks
			var roll = rng.randf()
			if roll < 0.3:
				return {"pos": pos, "type": "cactus", "height": rng.randf_range(10, 22),
						"color": Color(0.3, 0.5, 0.2)}
			elif roll < 0.5:
				return {"pos": pos, "type": "rock", "size": rng.randf_range(4, 10),
						"color": Color(0.65, 0.55, 0.38).darkened(rng.randf_range(0.0, 0.15))}
			elif roll < 0.7:
				return {"pos": pos, "type": "bones", "size": rng.randf_range(5, 10),
						"color": Color(0.85, 0.82, 0.72)}
			else:
				return {"pos": pos, "type": "sand_ripple", "width": rng.randf_range(15, 35),
						"color": theme.grass_var.lightened(0.08)}
		
		5:  # Gauntlet — lava pools, cracks, embers, skull rocks
			var roll = rng.randf()
			if roll < 0.3:
				return {"pos": pos, "type": "lava_pool", "size": rng.randf_range(8, 20),
						"color": Color(0.9, 0.35, 0.05)}
			elif roll < 0.5:
				return {"pos": pos, "type": "crack", "length": rng.randf_range(12, 30),
						"rot": rng.randf_range(0, TAU),
						"color": Color(0.85, 0.3, 0.05, 0.6)}
			elif roll < 0.7:
				return {"pos": pos, "type": "ember", "size": rng.randf_range(2, 5),
						"color": Color(1.0, 0.6, 0.1, 0.7)}
			elif roll < 0.85:
				return {"pos": pos, "type": "skull_rock", "size": rng.randf_range(5, 10),
						"color": Color(0.35, 0.28, 0.25)}
			else:
				return {"pos": pos, "type": "rock", "size": rng.randf_range(4, 9),
						"color": Color(0.25, 0.2, 0.2)}
		_:
			return {}
	return {}

func _near_path(pos: Vector2, path_points: PackedVector2Array, min_dist: float) -> bool:
	for i in range(path_points.size() - 1):
		var closest = _closest_point_on_segment(pos, path_points[i], path_points[i + 1])
		if pos.distance_to(closest) < min_dist:
			return true
	return false

func _closest_point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab = b - a
	var t = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return a + ab * t

func _draw():
	# Layer 1: Terrain
	if terrain_texture:
		draw_texture(terrain_texture, Vector2.ZERO)
	else:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.28, 0.55, 0.22))
	
	# Layer 2: Decorations
	for d in decorations:
		_draw_decoration(d)

func _draw_decoration(d: Dictionary):
	var pos: Vector2 = d.pos
	match d.type:
		"grass_tuft":
			var h = d.height
			var c: Color = d.color
			# 3-5 blades of grass
			for blade in range(4):
				var offset_x = (blade - 1.5) * 3.0
				var sway = (blade % 2) * 2.0 - 1.0
				draw_line(pos + Vector2(offset_x, 0), pos + Vector2(offset_x + sway, -h), c, 1.5, true)
		
		"flower":
			var stem_h = d.stem_h
			# Stem
			draw_line(pos, pos + Vector2(0, -stem_h), Color(0.2, 0.4, 0.15), 1.0)
			# Petals (small circle)
			draw_circle(pos + Vector2(0, -stem_h), 2.5, d.color)
			# Center dot
			draw_circle(pos + Vector2(0, -stem_h), 1.0, Color(0.9, 0.8, 0.2))
		
		"rock":
			var s = d.size
			# Simple rock: dark ellipse with highlight
			draw_circle(pos, s, d.color)
			draw_circle(pos + Vector2(-s * 0.25, -s * 0.25), s * 0.5, d.color.lightened(0.15))
		
		"leaf":
			# Fallen leaf: small rotated diamond
			var s = 3.5
			var rot = d.rot
			var c: Color = d.color
			var p1 = pos + Vector2(cos(rot), sin(rot)) * s
			var p2 = pos + Vector2(cos(rot + PI/2), sin(rot + PI/2)) * s * 0.5
			var p3 = pos + Vector2(cos(rot + PI), sin(rot + PI)) * s
			var p4 = pos + Vector2(cos(rot + PI*1.5), sin(rot + PI*1.5)) * s * 0.5
			draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), c)
		
		"hay_bale":
			var s = d.size
			# Rounded rectangle shape
			draw_circle(pos, s * 0.6, d.color)
			draw_circle(pos, s * 0.4, d.color.lightened(0.1))
			# Straw lines
			for i in range(3):
				var angle = i * TAU / 3.0
				draw_line(pos, pos + Vector2(cos(angle), sin(angle)) * s * 0.5,
						  d.color.darkened(0.15), 1.0)
		
		"mushroom":
			var s = d.size
			# Stem
			draw_line(pos, pos + Vector2(0, -s * 1.2), Color(0.85, 0.8, 0.7), 2.0)
			# Cap
			draw_circle(pos + Vector2(0, -s * 1.2), s * 0.8, d.cap_color)
			# Cap highlight
			draw_circle(pos + Vector2(-1, -s * 1.2 - 1), s * 0.35, d.cap_color.lightened(0.25))
		
		"moss":
			# Soft blob
			draw_circle(pos, d.size * 0.5, d.color)
			draw_circle(pos + Vector2(d.size * 0.3, -d.size * 0.1), d.size * 0.35, d.color)
			draw_circle(pos + Vector2(-d.size * 0.2, d.size * 0.2), d.size * 0.3, d.color)
		
		"fern":
			var s = d.size
			var c: Color = d.color
			# Central stem
			draw_line(pos, pos + Vector2(0, -s), c, 1.0)
			# Fronds (alternating)
			for i in range(3):
				var y_off = -s * (0.3 + i * 0.25)
				draw_line(pos + Vector2(0, y_off), pos + Vector2(-s * 0.4, y_off - 2), c, 1.0)
				draw_line(pos + Vector2(0, y_off), pos + Vector2(s * 0.4, y_off - 2), c, 1.0)
		
		"cactus":
			var h = d.height
			var c: Color = d.color
			# Main trunk
			draw_line(pos, pos + Vector2(0, -h), c, 4.0, true)
			# Arms
			var arm_y = h * 0.5
			draw_line(pos + Vector2(0, -arm_y), pos + Vector2(-7, -arm_y), c, 3.0, true)
			draw_line(pos + Vector2(-7, -arm_y), pos + Vector2(-7, -arm_y - 6), c, 3.0, true)
			if h > 15:
				var arm_y2 = h * 0.7
				draw_line(pos + Vector2(0, -arm_y2), pos + Vector2(6, -arm_y2), c, 3.0, true)
				draw_line(pos + Vector2(6, -arm_y2), pos + Vector2(6, -arm_y2 - 5), c, 3.0, true)
		
		"bones":
			var s = d.size
			var c: Color = d.color
			# Crossed bones
			draw_line(pos + Vector2(-s, -s*0.3), pos + Vector2(s, s*0.3), c, 1.5, true)
			draw_line(pos + Vector2(-s*0.3, s*0.5), pos + Vector2(s*0.3, -s*0.5), c, 1.5, true)
			# Bone knobs
			draw_circle(pos + Vector2(-s, -s*0.3), 2.0, c)
			draw_circle(pos + Vector2(s, s*0.3), 2.0, c)
		
		"sand_ripple":
			var w = d.width
			var c: Color = d.color
			# Subtle curved lines
			for i in range(3):
				var y_off = i * 4.0
				draw_line(pos + Vector2(-w*0.5, y_off), pos + Vector2(w*0.5, y_off), c, 1.0, true)
		
		"lava_pool":
			var s = d.size
			# Outer glow
			draw_circle(pos, s * 1.3, Color(0.9, 0.2, 0.0, 0.2))
			# Dark crust edge
			draw_circle(pos, s, Color(0.15, 0.08, 0.05))
			# Inner lava
			draw_circle(pos, s * 0.7, d.color)
			# Bright hotspot
			draw_circle(pos + Vector2(-s*0.15, -s*0.15), s * 0.3, Color(1.0, 0.7, 0.1))
		
		"crack":
			var l = d.length
			var rot = d.rot
			var c: Color = d.color
			var dir = Vector2(cos(rot), sin(rot))
			# Main crack
			draw_line(pos - dir * l * 0.5, pos + dir * l * 0.5, c, 1.5)
			# Branch cracks
			var mid = pos + dir * l * 0.15
			var perp = Vector2(-dir.y, dir.x)
			draw_line(mid, mid + perp * l * 0.3, c * Color(1,1,1,0.5), 1.0)
		
		"ember":
			# Glowing ember dot
			draw_circle(pos, d.size * 2.0, Color(1.0, 0.4, 0.0, 0.15))
			draw_circle(pos, d.size, d.color)
			draw_circle(pos, d.size * 0.4, Color(1.0, 0.9, 0.4))
		
		"skull_rock":
			var s = d.size
			var c: Color = d.color
			# Rock body
			draw_circle(pos, s, c)
			# Skull-like features: two dark "eye" hollows
			draw_circle(pos + Vector2(-s*0.3, -s*0.2), s * 0.2, c.darkened(0.4))
			draw_circle(pos + Vector2(s*0.3, -s*0.2), s * 0.2, c.darkened(0.4))
			# Highlight
			draw_circle(pos + Vector2(-s*0.2, -s*0.4), s * 0.25, c.lightened(0.12))
