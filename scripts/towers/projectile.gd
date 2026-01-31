extends Area2D

## Projectile that flies toward a target enemy
## Supports splash damage, slow, and poison on hit

var target: Area2D = null
var damage: int = 10
var speed: float = 300.0
var direction: Vector2 = Vector2.ZERO
var projectile_type: String = "arrow"

# Special effects
var splash_radius: float = 0.0
var apply_slow_on_hit: bool = false
var slow_amount: float = 0.5
var slow_duration: float = 1.5
var apply_poison_on_hit: bool = false
var poison_damage: float = 4.0
var poison_duration: float = 4.0

func _ready():
	# Set projectile sprite based on type
	var proj_textures = {
		"arrow": "res://assets/sprites/projectiles/arrow_proj.png",
		"cannon": "res://assets/sprites/projectiles/cannon_proj.png",
		"magic": "res://assets/sprites/projectiles/magic_proj.png",
		"frost": "res://assets/sprites/projectiles/frost_proj.png",
		"poison": "res://assets/sprites/projectiles/poison_proj.png",
		"holy": "res://assets/sprites/projectiles/holy_proj.png",
	}
	if proj_textures.has(projectile_type):
		var tex_path = proj_textures[projectile_type]
		if ResourceLoader.exists(tex_path):
			$Sprite2D.texture = load(tex_path)
	
	if target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	
	# Auto-destroy after 3 seconds if it misses
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self):
		queue_free()

func _process(delta: float):
	if target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	
	position += direction * speed * delta
	rotation = direction.angle()

func _on_area_entered(area: Area2D):
	if area.is_in_group("enemies") and area.has_method("take_damage"):
		_apply_hit(area)
		queue_free()

func _apply_hit(enemy: Area2D):
	# Direct hit
	enemy.take_damage(damage)
	_apply_effects(enemy)
	
	# Splash damage
	if splash_radius > 0:
		var splash_enemies = _get_enemies_in_radius(splash_radius)
		for e in splash_enemies:
			if e != enemy and is_instance_valid(e) and e.has_method("take_damage"):
				e.take_damage(int(damage * 0.5))  # 50% splash damage
				_apply_effects(e)

func _apply_effects(enemy: Area2D):
	if apply_slow_on_hit and enemy.has_method("apply_slow"):
		enemy.apply_slow(slow_amount, slow_duration)
	if apply_poison_on_hit and enemy.has_method("apply_poison"):
		enemy.apply_poison(poison_damage, poison_duration)

func _get_enemies_in_radius(radius: float) -> Array:
	var enemies: Array = []
	var space_state = get_world_2d().direct_space_state
	# Simple distance check against all enemies
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and global_position.distance_to(node.global_position) <= radius:
			enemies.append(node)
	return enemies
