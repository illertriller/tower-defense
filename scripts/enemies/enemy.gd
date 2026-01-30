extends Area2D

## Base enemy script
## Follows a Path2D and takes damage from towers

signal died()
signal reached_end()

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

var max_health: int = 50
var health: int = 50
var speed: float = 80.0
var reward: int = 10
var slow_multiplier: float = 1.0
var slow_timer: float = 0.0

# Enemy type data
var enemy_types: Dictionary = {
	"basic": {"health": 50, "speed": 80, "reward": 10, "color": Color.RED},
	"fast": {"health": 30, "speed": 150, "reward": 15, "color": Color.ORANGE},
	"tank": {"health": 200, "speed": 40, "reward": 30, "color": Color.DARK_RED},
	"boss": {"health": 500, "speed": 50, "reward": 100, "color": Color.PURPLE}
}

func setup(type: String):
	if type in enemy_types:
		var data = enemy_types[type]
		max_health = data["health"]
		health = max_health
		speed = data["speed"]
		reward = data["reward"]
		# Temporary color indicator until we have sprites
		modulate = data["color"]

func _ready():
	health_bar.max_value = max_health
	health_bar.value = health

func _process(delta: float):
	# Handle slow effect
	if slow_timer > 0:
		slow_timer -= delta
		if slow_timer <= 0:
			slow_multiplier = 1.0
	
	# Move along path
	var path_follow = get_parent() as PathFollow2D
	if path_follow:
		path_follow.progress += speed * slow_multiplier * delta
		
		# Check if reached the end
		if path_follow.progress_ratio >= 1.0:
			GameManager.enemy_reached_end()
			reached_end.emit()
			queue_free()

func take_damage(amount: int):
	health -= amount
	health_bar.value = health
	
	# Flash white on hit
	modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	# Reset to type color
	
	if health <= 0:
		die()

func apply_slow(amount: float, duration: float):
	slow_multiplier = amount
	slow_timer = duration

func die():
	GameManager.enemy_killed(reward)
	died.emit()
	
	# TODO: death animation / particles
	queue_free()
