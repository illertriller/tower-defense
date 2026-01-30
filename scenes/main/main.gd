extends Node2D

## Main scene controller
## Handles UI updates, tower placement, wave management

@export var tower_scene: PackedScene

@onready var enemy_path: Path2D = $EnemyPath
@onready var grid_manager: Node2D = $GridManager
@onready var money_label: Label = $UI/TopBar/MoneyLabel
@onready var lives_label: Label = $UI/TopBar/LivesLabel
@onready var wave_label: Label = $UI/TopBar/WaveLabel
@onready var start_wave_btn: Button = $UI/StartWaveBtn
@onready var arrow_btn: Button = $UI/TowerPanel/ArrowBtn
@onready var cannon_btn: Button = $UI/TowerPanel/CannonBtn
@onready var magic_btn: Button = $UI/TowerPanel/MagicBtn
@onready var tesla_btn: Button = $UI/TowerPanel/TeslaBtn
@onready var ghost_preview: ColorRect = $GhostPreview

var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy.tscn")
var tesla_tower_scene: PackedScene = preload("res://scenes/towers/tesla_tower.tscn")
var selected_tower: String = ""
var is_placing: bool = false
var total_waves: int = 3

func _ready():
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_completed.connect(_on_wave_completed)
	GameManager.game_over.connect(_on_game_over)
	
	arrow_btn.pressed.connect(_on_arrow_pressed)
	cannon_btn.pressed.connect(_on_cannon_pressed)
	magic_btn.pressed.connect(_on_magic_pressed)
	tesla_btn.pressed.connect(_on_tesla_pressed)
	start_wave_btn.pressed.connect(_on_start_wave_pressed)
	
	# Mark the path cells on the grid
	grid_manager.mark_path_cells(enemy_path.curve)
	
	# Setup ghost preview (hidden by default)
	ghost_preview.visible = false
	ghost_preview.size = Vector2(64, 64)
	ghost_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_update_ui()

func _process(_delta: float):
	if is_placing:
		# Show ghost preview at snapped position
		var snap_pos = grid_manager.get_tower_snap_position(get_global_mouse_position())
		ghost_preview.visible = true
		ghost_preview.global_position = snap_pos - Vector2(32, 32)
		
		# Color based on whether placement is valid
		if grid_manager.can_place_tower(get_global_mouse_position()):
			ghost_preview.color = Color(0, 1, 0, 0.3)  # Green = valid
		else:
			ghost_preview.color = Color(1, 0, 0, 0.3)  # Red = invalid
	else:
		ghost_preview.visible = false

func _update_ui():
	money_label.text = "Gold: %d" % GameManager.money
	lives_label.text = "Lives: %d" % GameManager.lives
	wave_label.text = "Wave %d / %d" % [GameManager.current_wave, total_waves]
	arrow_btn.disabled = not GameManager.can_afford("arrow_tower")
	cannon_btn.disabled = not GameManager.can_afford("cannon_tower")
	magic_btn.disabled = not GameManager.can_afford("magic_tower")
	tesla_btn.disabled = not GameManager.can_afford("tesla_tower")
	start_wave_btn.disabled = GameManager.is_wave_active

func _on_arrow_pressed():
	_select_tower("arrow_tower")

func _on_cannon_pressed():
	_select_tower("cannon_tower")

func _on_magic_pressed():
	_select_tower("magic_tower")

func _on_tesla_pressed():
	_select_tower("tesla_tower")

func _select_tower(type: String):
	if GameManager.can_afford(type):
		selected_tower = type
		is_placing = true

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and is_placing:
			_place_tower(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			is_placing = false
			selected_tower = ""

func _place_tower(world_pos: Vector2):
	if selected_tower.is_empty():
		return
	if not grid_manager.can_place_tower(world_pos):
		return
	if not GameManager.buy_tower(selected_tower):
		return
	
	var snap_pos = grid_manager.get_tower_snap_position(world_pos)
	
	var tower: Node2D
	if selected_tower == "tesla_tower":
		tower = tesla_tower_scene.instantiate()
	else:
		tower = tower_scene.instantiate()
	tower.global_position = snap_pos
	tower.setup(selected_tower)
	$TowersContainer.add_child(tower)
	
	# Mark grid cells as occupied
	grid_manager.place_tower(world_pos)
	
	is_placing = false
	selected_tower = ""
	_update_ui()

func _on_start_wave_pressed():
	if GameManager.is_wave_active:
		return
	if GameManager.current_wave >= total_waves:
		return
	GameManager.start_wave()
	_spawn_wave()

func _spawn_wave():
	var wave_data = _get_wave_data(GameManager.current_wave)
	for group in wave_data:
		var count: int = group["count"]
		var delay: float = group["delay"]
		var type: String = group["type"]
		for i in range(count):
			_spawn_enemy(type)
			await get_tree().create_timer(delay).timeout

func _spawn_enemy(type: String):
	var follow = PathFollow2D.new()
	follow.rotates = false
	follow.loop = false
	enemy_path.add_child(follow)
	var enemy = enemy_scene.instantiate()
	enemy.setup(type)
	follow.add_child(enemy)
	enemy.died.connect(_on_enemy_died.bind(follow))
	enemy.reached_end.connect(_on_enemy_reached_end.bind(follow))

func _on_enemy_died(follow: PathFollow2D):
	if is_instance_valid(follow):
		follow.queue_free()
	_check_wave_done()

func _on_enemy_reached_end(follow: PathFollow2D):
	if is_instance_valid(follow):
		follow.queue_free()
	_check_wave_done()

func _check_wave_done():
	await get_tree().create_timer(0.1).timeout
	if GameManager.is_wave_active:
		var remaining = enemy_path.get_child_count()
		if remaining == 0:
			GameManager.complete_wave()
	_update_ui()

func _get_wave_data(wave: int) -> Array:
	var waves: Array = [
		# Wave 1: 5 enemies
		[{"type": "basic", "count": 5, "delay": 1.0}],
		# Wave 2: 10 enemies (doubled)
		[{"type": "basic", "count": 7, "delay": 0.8}, {"type": "fast", "count": 3, "delay": 0.6}],
		# Wave 3: 20 enemies (doubled again)
		[{"type": "basic", "count": 10, "delay": 0.7}, {"type": "fast", "count": 6, "delay": 0.5}, {"type": "tank", "count": 4, "delay": 1.5}],
	]
	var index = min(wave - 1, waves.size() - 1)
	return waves[index]

func _on_money_changed(_amount):
	_update_ui()

func _on_lives_changed(_amount):
	_update_ui()

func _on_wave_started(_wave):
	_update_ui()

func _on_wave_completed(_wave):
	_update_ui()
	if GameManager.current_wave >= total_waves:
		start_wave_btn.text = "YOU WIN!"
		start_wave_btn.disabled = true

func _on_game_over():
	start_wave_btn.text = "GAME OVER"
	start_wave_btn.disabled = true
