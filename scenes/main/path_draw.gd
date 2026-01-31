extends Path2D

## Draws the enemy path as a textured gravel road

var gravel_texture: Texture2D
var path_width: float = 48.0

func _ready():
	# Try level-specific path texture first, fallback to default
	var level = GameManager.current_level
	var level_path = "res://assets/sprites/terrain/level%d_path.png" % level
	
	if ResourceLoader.exists(level_path):
		gravel_texture = load(level_path)
	else:
		gravel_texture = load("res://assets/sprites/terrain/gravel_tile.png")
	
	queue_redraw()

func _draw():
	if not curve or curve.point_count < 2:
		return
	
	var points = curve.get_baked_points()
	
	# Draw dark border (road edge)
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], Color(0.25, 0.2, 0.12), path_width + 6.0)
	
	# Draw the gravel road by tiling texture along the path
	if gravel_texture:
		var tile_size = gravel_texture.get_width()
		# Draw textured quads along the path
		for i in range(points.size() - 1):
			var p1 = points[i]
			var p2 = points[i + 1]
			var direction = (p2 - p1).normalized()
			var perpendicular = Vector2(-direction.y, direction.x)
			var half_w = path_width / 2.0
			
			# Draw segment as textured rect
			var segment_length = p1.distance_to(p2)
			var steps = int(segment_length / tile_size) + 1
			
			for s in range(steps):
				var t = float(s) / max(steps, 1)
				var pos = p1.lerp(p2, t)
				var rect_pos = pos - Vector2(tile_size / 2.0, tile_size / 2.0)
				draw_texture(gravel_texture, rect_pos)
	else:
		# Fallback: solid color road
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], Color(0.55, 0.47, 0.31), path_width)
	
	# Draw subtle center line (worn track marks)
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], Color(0.5, 0.42, 0.28, 0.3), 4.0)
