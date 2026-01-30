extends Path2D

## Draws the enemy path visually

func _draw():
	if curve and curve.point_count > 1:
		var points = curve.get_baked_points()
		# Draw path background (dirt road)
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], Color(0.55, 0.47, 0.31), 40.0)
		# Draw path border
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], Color(0.45, 0.37, 0.21), 44.0, false)
		# Redraw center on top
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], Color(0.55, 0.47, 0.31), 38.0)
