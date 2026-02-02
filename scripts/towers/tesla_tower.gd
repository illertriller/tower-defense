extends Node2D

## Tesla Tower - Zaps up to 3 enemies with continuous lightning
## No projectiles — draws lightning bolts directly to targets

@onready var range_area: Area2D = $RangeArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var zap_timer: Timer = $ZapTimer

var tower_type: String = "tesla_tower"
var damage: int = 5
var attack_range: float = 140.0
var fire_rate: float = 4.0  # zaps per second
var max_targets: int = 3
var enemies_in_range: Array = []
var current_targets: Array = []
var lightning_lines: Array = []
var can_zap: bool = true
var _pending_type: String = ""

func setup(type: String):
	_pending_type = type

func _ready():
	if not _pending_type.is_empty():
		_apply_setup(_pending_type)

func _apply_setup(type: String):
	tower_type = type
	var data = GameManager.tower_data[type]
	damage = data["damage"]
	attack_range = data["range"]
	fire_rate = data["fire_rate"]
	
	# Set tower sprite
	sprite.texture = load("res://assets/sprites/towers/tesla_tower.png")
	
	# Set range collision shape
	var shape = CircleShape2D.new()
	shape.radius = attack_range
	$RangeArea/CollisionShape2D.shape = shape
	
	# Set zap rate
	zap_timer.wait_time = 1.0 / fire_rate
	
	print("Tesla tower placed | damage: ", damage, " | range: ", attack_range)

func _process(_delta: float):
	_update_targets()
	_update_lightning()
	
	if can_zap and not current_targets.is_empty():
		_zap()

func _update_targets():
	# Remove invalid enemies
	var valid: Array = []
	for e in enemies_in_range:
		if is_instance_valid(e):
			valid.append(e)
	enemies_in_range = valid
	
	# Pick up to max_targets closest enemies
	current_targets.clear()
	
	if enemies_in_range.is_empty():
		return
	
	# Sort by distance
	var sorted_enemies = enemies_in_range.duplicate()
	sorted_enemies.sort_custom(func(a, b):
		var da = global_position.distance_squared_to(a.global_position)
		var db = global_position.distance_squared_to(b.global_position)
		return da < db
	)
	
	for i in range(min(max_targets, sorted_enemies.size())):
		current_targets.append(sorted_enemies[i])

func _update_lightning():
	# Remove old lightning lines
	for line in lightning_lines:
		if is_instance_valid(line):
			line.queue_free()
	lightning_lines.clear()
	
	# Draw new lightning to each target
	for target in current_targets:
		if is_instance_valid(target):
			var line = Line2D.new()
			line.width = 2.0
			line.default_color = Color(0.4, 0.7, 1.0, 0.9)
			line.z_index = 10
			
			# Generate jagged lightning path
			var start = Vector2.ZERO  # local to tower
			var end = target.global_position - global_position
			var points = _generate_lightning_points(start, end)
			
			for p in points:
				line.add_point(p)
			
			add_child(line)
			lightning_lines.append(line)

func _generate_lightning_points(start: Vector2, end: Vector2) -> Array:
	var points: Array = [start]
	var segments = 6
	var direction = end - start
	
	for i in range(1, segments):
		var t = float(i) / segments
		var base_point = start + direction * t
		# Add random offset perpendicular to the lightning direction
		var perpendicular = Vector2(-direction.y, direction.x).normalized()
		var offset = perpendicular * randf_range(-12.0, 12.0)
		points.append(base_point + offset)
	
	points.append(end)
	return points

func _zap():
	can_zap = false
	zap_timer.start()
	AudioManager.play_sfx("spell", -3.0)
	
	for target in current_targets:
		if is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(damage)

func _on_range_area_area_entered(area: Area2D):
	if area.is_in_group("enemies"):
		enemies_in_range.append(area)

func _on_range_area_area_exited(area: Area2D):
	enemies_in_range.erase(area)

func _on_zap_timer_timeout():
	can_zap = true
