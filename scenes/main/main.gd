extends Node2D

## Main scene controller — data-driven level gameplay
## Loads path/wave data from LevelData based on GameManager.current_level

@export var tower_scene: PackedScene

@onready var enemy_path: Path2D = $EnemyPath
@onready var grid_manager: Node2D = $GridManager
@onready var money_label: Label = $UI/TopBar/MoneyLabel
@onready var lives_label: Label = $UI/TopBar/LivesLabel
@onready var wave_label: Label = $UI/TopBar/WaveLabel
@onready var level_label: Label = $UI/TopBar/LevelLabel
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

func _ready():
	# Connect signals
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_completed.connect(_on_wave_completed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.level_complete.connect(_on_level_complete)
	
	arrow_btn.pressed.connect(_on_arrow_pressed)
	cannon_btn.pressed.connect(_on_cannon_pressed)
	magic_btn.pressed.connect(_on_magic_pressed)
	tesla_btn.pressed.connect(_on_tesla_pressed)
	start_wave_btn.pressed.connect(_on_start_wave_pressed)
	
	# Load level data
	_setup_level()
	
	# Setup ghost preview
	ghost_preview.visible = false
	ghost_preview.size = Vector2(64, 64)
	ghost_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_update_ui()

func _setup_level():
	var level = GameManager.current_level
	
	# Set path from level data
	var path_points = LevelData.get_path_points(level)
	var curve = Curve2D.new()
	for point in path_points:
		curve.add_point(point)
	enemy_path.curve = curve
	
	# Mark path cells on the grid
	grid_manager.mark_path_cells(enemy_path.curve)
	
	# Force path to redraw
	enemy_path.queue_redraw()

func _process(_delta: float):
	if is_placing:
		var snap_pos = grid_manager.get_tower_snap_position(get_global_mouse_position())
		ghost_preview.visible = true
		ghost_preview.global_position = snap_pos - Vector2(32, 32)
		
		if grid_manager.can_place_tower(get_global_mouse_position()):
			ghost_preview.color = Color(0, 1, 0, 0.3)
		else:
			ghost_preview.color = Color(1, 0, 0, 0.3)
	else:
		ghost_preview.visible = false

func _update_ui():
	money_label.text = "Gold: %d" % GameManager.money
	lives_label.text = "Lives: %d" % GameManager.lives
	wave_label.text = "Wave %d / %d" % [GameManager.current_wave, GameManager.total_waves]
	level_label.text = "Level %d — %s" % [GameManager.current_level, LevelData.get_level_name(GameManager.current_level)]
	
	arrow_btn.text = "[1] Arrow (%dg)" % GameManager.tower_data["arrow_tower"]["cost"]
	cannon_btn.text = "[2] Cannon (%dg)" % GameManager.tower_data["cannon_tower"]["cost"]
	magic_btn.text = "[3] Magic (%dg)" % GameManager.tower_data["magic_tower"]["cost"]
	tesla_btn.text = "[4] Tesla (%dg)" % GameManager.tower_data["tesla_tower"]["cost"]
	
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
	
	# ESC to deselect tower, or back to menu if nothing selected
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_placing:
			is_placing = false
			selected_tower = ""
		else:
			get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
	
	# Keyboard shortcuts for tower selection: 1-4
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_select_tower("arrow_tower")
			KEY_2:
				_select_tower("cannon_tower")
			KEY_3:
				_select_tower("magic_tower")
			KEY_4:
				_select_tower("tesla_tower")
			KEY_SPACE:
				_on_start_wave_pressed()

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
	
	grid_manager.place_tower(world_pos)
	
	is_placing = false
	selected_tower = ""
	_update_ui()

func _on_start_wave_pressed():
	if GameManager.is_wave_active:
		return
	if GameManager.current_wave >= GameManager.total_waves:
		return
	GameManager.start_wave()
	_spawn_wave()

func _spawn_wave():
	var waves = LevelData.get_waves(GameManager.current_level)
	var wave_index = min(GameManager.current_wave - 1, waves.size() - 1)
	var wave_data = waves[wave_index]
	
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

# Signal handlers
func _on_money_changed(_amount):
	_update_ui()

func _on_lives_changed(_amount):
	_update_ui()

func _on_wave_started(_wave):
	_update_ui()

func _on_wave_completed(_wave):
	_update_ui()
	if GameManager.current_wave >= GameManager.total_waves:
		start_wave_btn.text = "Level Clear!"
		start_wave_btn.disabled = true

func _on_game_over():
	# Short delay then show lose screen
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/ui/lose_screen.tscn")

func _on_level_complete(_level: int):
	# Short delay then show win screen
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/ui/win_screen.tscn")
