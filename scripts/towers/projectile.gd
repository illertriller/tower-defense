extends Area2D

## Projectile that flies toward a target enemy

var target: Area2D = null
var damage: int = 10
var speed: float = 300.0
var direction: Vector2 = Vector2.ZERO

func _ready():
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
