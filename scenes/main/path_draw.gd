extends Path2D

## Draws the enemy path as a smooth, natural-looking dirt road
## PRD: "Dirt road layered on top, following path but looking natural"
## No tile stamping — uses thick antialiased lines with rounded joins

var path_width: float = 48.0
var edge_width: float = 56.0

var road_color: Color
var edge_color: Color
var center_color: Color

func _ready():
	var theme = LevelData.get_terrain_theme(GameManager.current_level)
	road_color = theme.road
	edge_color = theme.road_edge
	center_color = theme.road_center
	queue_redraw()

func _draw():
	if not curve or curve.point_count < 2:
		return
	
	var points = curve.get_baked_points()
	if points.size() < 2:
		return
	
	# Layer 1: Road edge / border (darkest, widest)
	_draw_road_layer(points, edge_color, edge_width)
	
	# Layer 2: Main road fill
	_draw_road_layer(points, road_color, path_width)
	
	# Layer 3: Subtle worn center track
	_draw_road_layer(points, center_color, 6.0)

func _draw_road_layer(points: PackedVector2Array, color: Color, width: float):
	# Draw line segments
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], color, width, true)
	
	# Draw circles at each point for smooth rounded joins
	var radius = width / 2.0
	for point in points:
		draw_circle(point, radius, color)
