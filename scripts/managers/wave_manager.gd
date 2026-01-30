extends Node

## Wave Manager - Spawns enemies in waves

signal all_waves_complete()

@export var enemy_scene: PackedScene
@export var path: Path2D

var wave_definitions: Array = [
	# Wave 1: Easy intro
	{"enemies": [
		{"type": "basic", "count": 5, "delay": 1.0}
	]},
	# Wave 2: More basics
	{"enemies": [
		{"type": "basic", "count": 8, "delay": 0.8}
	]},
	# Wave 3: Introduce fast enemies
	{"enemies": [
		{"type": "basic", "count": 5, "delay": 1.0},
		{"type": "fast", "count": 3, "delay": 0.6}
	]},
	# Wave 4: Mixed
	{"enemies": [
		{"type": "basic", "count": 8, "delay": 0.8},
		{"type": "fast", "count": 5, "delay": 0.5}
	]},
	# Wave 5: Introduce tank
	{"enemies": [
		{"type": "basic", "count": 6, "delay": 0.8},
		{"type": "fast", "count": 4, "delay": 0.5},
		{"type": "tank", "count": 2, "delay": 2.0}
	]},
	# Wave 6-10: Escalation
	{"enemies": [
		{"type": "basic", "count": 10, "delay": 0.6},
		{"type": "fast", "count": 6, "delay": 0.4},
		{"type": "tank", "count": 3, "delay": 1.5}
	]},
	{"enemies": [
		{"type": "fast", "count": 12, "delay": 0.3},
		{"type": "tank", "count": 4, "delay": 1.2}
	]},
	{"enemies": [
		{"type": "basic", "count": 15, "delay": 0.5},
		{"type": "fast", "count": 8, "delay": 0.3},
		{"type": "tank", "count": 5, "delay": 1.0}
	]},
	{"enemies": [
		{"type": "fast", "count": 15, "delay": 0.25},
		{"type": "tank", "count": 8, "delay": 0.8}
	]},
	# Wave 10: Boss
	{"enemies": [
		{"type": "basic", "count": 10, "delay": 0.5},
		{"type": "fast", "count": 10, "delay": 0.3},
		{"type": "tank", "count": 5, "delay": 0.8},
		{"type": "boss", "count": 1, "delay": 3.0}
	]},
]

var enemies_alive: int = 0

func get_wave_data(wave_number: int) -> Dictionary:
	var index = min(wave_number - 1, wave_definitions.size() - 1)
	return wave_definitions[index]

func spawn_wave(wave_number: int):
	var wave_data = get_wave_data(wave_number)
	enemies_alive = 0
	
	for group in wave_data["enemies"]:
		for i in group["count"]:
			enemies_alive += 1
	
	# Spawn enemies with delays
	for group in wave_data["enemies"]:
		for i in group["count"]:
			_spawn_enemy(group["type"])
			await get_tree().create_timer(group["delay"]).timeout

func _spawn_enemy(type: String):
	if enemy_scene and path:
		var follow = PathFollow2D.new()
		path.add_child(follow)
		var enemy = enemy_scene.instantiate()
		enemy.setup(type)
		follow.add_child(enemy)
		enemy.died.connect(_on_enemy_died)
		enemy.reached_end.connect(_on_enemy_reached_end)

func _on_enemy_died():
	enemies_alive -= 1
	_check_wave_complete()

func _on_enemy_reached_end():
	enemies_alive -= 1
	_check_wave_complete()

func _check_wave_complete():
	if enemies_alive <= 0:
		GameManager.complete_wave()
		if GameManager.current_wave >= wave_definitions.size():
			all_waves_complete.emit()
