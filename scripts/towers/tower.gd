extends Node2D

## Base tower script
## Targets and shoots at enemies within range

@onready var range_area: Area2D = $RangeArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var barrel: Marker2D = $Barrel

@export var projectile_scene: PackedScene

var tower_type: String = "arrow_tower"
var damage: int = 10
var attack_range: float = 150.0
var fire_rate: float = 1.0
var projectile_speed: float = 300.0
var current_target: Area2D = null
var enemies_in_range: Array = []
var can_shoot: bool = true
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
	projectile_speed = data["projectile_speed"]
	
	# Set range collision shape
	var shape = CircleShape2D.new()
	shape.radius = attack_range
	$RangeArea/CollisionShape2D.shape = shape
	
	# Set fire rate
	shoot_timer.wait_time = 1.0 / fire_rate
	
	print("Tower placed: ", type, " | damage: ", damage, " | range: ", attack_range)

func _process(_delta: float):
	_update_target()
	
	if can_shoot and current_target and is_instance_valid(current_target):
		shoot()

func _update_target():
	# Remove invalid enemies
	var valid_enemies: Array = []
	for e in enemies_in_range:
		if is_instance_valid(e):
			valid_enemies.append(e)
	enemies_in_range = valid_enemies
	
	if enemies_in_range.is_empty():
		current_target = null
		return
	
	# Target enemy furthest along the path (closest to exit)
	var best_target: Area2D = null
	var best_progress: float = 0.0
	
	for enemy in enemies_in_range:
		var path_follow = enemy.get_parent() as PathFollow2D
		if path_follow and path_follow.progress_ratio > best_progress:
			best_progress = path_follow.progress_ratio
			best_target = enemy
	
	current_target = best_target

func shoot():
	if not projectile_scene:
		return
	
	can_shoot = false
	shoot_timer.start()
	
	var projectile = projectile_scene.instantiate()
	if barrel:
		projectile.global_position = barrel.global_position
	else:
		projectile.global_position = global_position
	projectile.target = current_target
	projectile.damage = damage
	projectile.speed = projectile_speed
	
	get_tree().root.add_child(projectile)

func _on_range_area_area_entered(area: Area2D):
	if area.is_in_group("enemies"):
		enemies_in_range.append(area)

func _on_range_area_area_exited(area: Area2D):
	enemies_in_range.erase(area)

func _on_shoot_timer_timeout():
	can_shoot = true
