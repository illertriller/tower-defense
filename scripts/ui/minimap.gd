extends Control

## Minimap — shows bird's eye view of the map
## Displays: terrain, path, towers, enemies, camera viewport

const MINIMAP_SIZE: Vector2 = Vector2(200, 120)
const MARGIN: float = 10.0

var map_size: Vector2 = Vector2(2560, 1440)
var path_points: PackedVector2Array = PackedVector2Array()
var _enemies_container: Node = null
var _towers_container: Node = null

func _ready():
	# Position in top-right corner
	custom_minimum_size = MINIMAP_SIZE
	size = MINIMAP_SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS

func setup(p_map_size: Vector2, p_path_points: PackedVector2Array):
	map_size = p_map_size
	path_points = p_path_points
	queue_redraw()

func set_containers(enemies: Node, towers: Node):
	_enemies_container = enemies
	_towers_container = towers

func _process(_delta: float):
	queue_redraw()

func _draw():
	if not Settings.show_minimap:
		visible = false
		return
	visible = true
	
	var scale_x = MINIMAP_SIZE.x / map_size.x
	var scale_y = MINIMAP_SIZE.y / map_size.y
	
	# Background
	draw_rect(Rect2(Vector2.ZERO, MINIMAP_SIZE), Color(0.1, 0.08, 0.06, 0.85))
	
	# Border
	draw_rect(Rect2(Vector2.ZERO, MINIMAP_SIZE), Color(0.6, 0.5, 0.3, 0.8), false, 2.0)
	
	# Path
	if path_points.size() >= 2:
		for i in range(path_points.size() - 1):
			var from = Vector2(path_points[i].x * scale_x, path_points[i].y * scale_y)
			var to = Vector2(path_points[i + 1].x * scale_x, path_points[i + 1].y * scale_y)
			draw_line(from, to, Color(0.55, 0.43, 0.28, 0.9), 2.0)
	
	# Towers (green dots)
	if _towers_container and is_instance_valid(_towers_container):
		for tower in _towers_container.get_children():
			if is_instance_valid(tower):
				var tp = Vector2(tower.global_position.x * scale_x, tower.global_position.y * scale_y)
				draw_circle(tp, 2.5, Color(0.2, 0.9, 0.3, 0.9))
	
	# Enemies (red dots)
	if _enemies_container and is_instance_valid(_enemies_container):
		for follow in _enemies_container.get_children():
			if is_instance_valid(follow) and follow is PathFollow2D:
				for child in follow.get_children():
					if is_instance_valid(child):
						var ep = Vector2(child.global_position.x * scale_x, child.global_position.y * scale_y)
						draw_circle(ep, 1.5, Color(1.0, 0.3, 0.2, 0.9))
	
	# Camera viewport rectangle
	var cam = get_viewport().get_camera_2d()
	if cam:
		var zoom = cam.zoom
		var vp_size = get_viewport_rect().size / zoom
		var cam_tl = cam.position - vp_size / 2.0
		
		var rect_pos = Vector2(cam_tl.x * scale_x, cam_tl.y * scale_y)
		var rect_size = Vector2(vp_size.x * scale_x, vp_size.y * scale_y)
		
		draw_rect(Rect2(rect_pos, rect_size), Color(1, 1, 1, 0.4), false, 1.5)

func _gui_input(event: InputEvent):
	# Click on minimap to move camera
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_jump_camera(event.position)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_jump_camera(event.position)

func _jump_camera(local_pos: Vector2):
	var scale_x = map_size.x / MINIMAP_SIZE.x
	var scale_y = map_size.y / MINIMAP_SIZE.y
	var world_pos = Vector2(local_pos.x * scale_x, local_pos.y * scale_y)
	
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("center_on"):
		cam.center_on(world_pos)
