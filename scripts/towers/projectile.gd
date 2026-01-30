extends Area2D

## Projectile that flies toward a target enemy

var target: Area2D = null
var damage: int = 10
var speed: float = 300.0
var direction: Vector2 = Vector2.ZERO
var projectile_type: String = "arrow"

func _ready():
	# Set projectile sprite based on type
	var proj_textures = {
		"arrow": "res://assets/sprites/projectiles/arrow_proj.png",
		"cannon": "res://assets/sprites/projectiles/cannon_proj.png",
		"magic": "res://assets/sprites/projectiles/magic_proj.png"
	}
	if proj_textures.has(projectile_type):
		$Sprite2D.texture = load(proj_textures[projectile_type])
	if target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	# Auto-destroy after 3 seconds if it misses
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self):
		queue_free()

func _process(delta: float):
	if target and is_instance_valid(target):
		# Home in on target
		direction = (target.global_position - global_position).normalized()
	
	position += direction * speed * delta
	rotation = direction.angle()

func _on_area_entered(area: Area2D):
	if area.is_in_group("enemies") and area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
