extends Camera2D
class_name GameCamera

## Game Camera — WASD + edge-pan + middle-mouse drag
## Follows the action on maps larger than the viewport

# Edge panning
var _edge_panning: bool = false

# Middle-mouse drag
var _dragging: bool = false
var _drag_start: Vector2 = Vector2.ZERO

# Map bounds (set by main scene)
var map_size: Vector2 = Vector2(2560, 1440)

func _ready():
	# Camera starts centered on the map
	enabled = true
	position = map_size / 2.0
	_clamp_position()

func setup(p_map_size: Vector2):
	map_size = p_map_size
	position = map_size / 2.0
	_clamp_position()

func _process(delta: float):
	var move = Vector2.ZERO
	
	# WASD / Arrow key panning
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move.y += 1
	
	if move != Vector2.ZERO:
		position += move.normalized() * Settings.camera_keyboard_speed * delta
	
	# Edge panning
	if Settings.camera_edge_pan and not _dragging:
		var viewport_size = get_viewport_rect().size
		var mouse_pos = get_viewport().get_mouse_position()
		var edge = Vector2.ZERO
		var margin = Settings.camera_edge_margin
		
		if mouse_pos.x < margin:
			edge.x = -1
		elif mouse_pos.x > viewport_size.x - margin:
			edge.x = 1
		if mouse_pos.y < margin:
			edge.y = -1
		elif mouse_pos.y > viewport_size.y - margin:
			edge.y = 1
		
		if edge != Vector2.ZERO:
			position += edge.normalized() * Settings.camera_edge_speed * delta
	
	_clamp_position()

func _unhandled_input(event: InputEvent):
	# Middle-mouse drag
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_dragging = true
				_drag_start = event.position
			else:
				_dragging = false
	
	if event is InputEventMouseMotion and _dragging:
		position -= event.relative / zoom
		_clamp_position()

func _clamp_position():
	var viewport_size = get_viewport_rect().size / zoom
	var half_vp = viewport_size / 2.0
	
	# Clamp so camera doesn't show past map edges
	position.x = clampf(position.x, half_vp.x, max(map_size.x - half_vp.x, half_vp.x))
	position.y = clampf(position.y, half_vp.y, max(map_size.y - half_vp.y, half_vp.y))

func center_on(pos: Vector2):
	position = pos
	_clamp_position()

## Convert screen position to world position (accounting for camera)
func screen_to_world(screen_pos: Vector2) -> Vector2:
	var viewport_size = get_viewport_rect().size / zoom
	return position - viewport_size / 2.0 + screen_pos / zoom
