extends Node2D

## Main scene controller — data-driven level gameplay
## Uses GameHUD for all UI, handles tower placement and wave spawning
## Now supports scrollable maps larger than the viewport

@export var tower_scene: PackedScene

@onready var enemy_path: Path2D = $EnemyPath
@onready var grid_manager: Node2D = $GridManager
@onready var ghost_preview: ColorRect = $GhostPreview
@onready var hud = $GameHUD
@onready var camera: Camera2D = $GameCamera
@onready var background: Node2D = $Background
@onready var minimap = $GameHUD/MinimapMargin/Minimap

var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy.tscn")
var selected_tower: String = ""
var is_placing: bool = false
var _spawning_complete: bool = false
var _enemies_spawned: int = 0
var _enemies_finished: int = 0
var selected_placed_tower: Node2D = null

# Map dimensions (from Settings)
var map_width: int
var map_height: int

# Keyboard tower mapping
var tower_types: Array = [
	"arrow_tower", "cannon_tower", "magic_tower", "tesla_tower",
	"frost_tower", "flame_tower", "antiair_tower", "sniper_tower",
	"poison_tower", "bomb_tower", "holy_tower", "barracks_tower",
	"gold_mine", "storm_tower"
]
var tower_hotkeys: Dictionary = {
	KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_4: 3,
	KEY_5: 4, KEY_6: 5, KEY_7: 6, KEY_8: 7,
	KEY_9: 8, KEY_0: 9,
}

func _ready():
	# Get map size from settings
	map_width = Settings.map_width
	map_height = Settings.map_height
	
	# Setup camera for map bounds
	camera.setup(Vector2(map_width, map_height))
	
	# Setup grid for map size
	grid_manager.setup_for_map(map_width, map_height)
	
	# Setup background for map size
	background.setup(map_width, map_height)
	
	# Game signals
	GameManager.money_changed.connect(func(_a): hud.update_hud())
	GameManager.lives_changed.connect(func(_a): hud.update_hud())
	GameManager.wave_started.connect(func(_a): hud.update_hud())
	GameManager.wave_completed.connect(_on_wave_completed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.level_complete.connect(_on_level_complete)
	GameManager.tower_upgraded.connect(func(_t): hud.update_hud())
	
	# HUD signals
	hud.tower_selected.connect(_on_hud_tower_selected)
	hud.upgrade_requested.connect(_on_hud_upgrade_requested)
	hud.demolish_requested.connect(_on_hud_demolish_requested)
	hud.wave_start_requested.connect(_on_start_wave_pressed)
	
	_setup_level()
	
	ghost_preview.visible = false
	ghost_preview.size = Vector2(64, 64)
	ghost_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Setup minimap
	var path_points = LevelData.get_path_points(GameManager.current_level)
	minimap.setup(Vector2(map_width, map_height), path_points)
	minimap.set_containers(enemy_path, $TowersContainer)
	
	hud.update_hud()

func _setup_level():
	var level = GameManager.current_level
	var path_points = LevelData.get_path_points(level)
	var curve = Curve2D.new()
	for point in path_points:
		curve.add_point(point)
	enemy_path.curve = curve
	grid_manager.mark_path_cells(enemy_path.curve)
	enemy_path.queue_redraw()

func _get_world_mouse_pos() -> Vector2:
	## Convert screen mouse position to world coordinates accounting for camera
	return get_global_mouse_position()

func _process(_delta: float):
	if is_placing:
		var world_mouse = _get_world_mouse_pos()
		var snap_pos = grid_manager.get_tower_snap_position(world_mouse)
		ghost_preview.visible = true
		ghost_preview.global_position = snap_pos - Vector2(32, 32)
		ghost_preview.color = Color(0, 1, 0, 0.3) if grid_manager.can_place_tower(world_mouse) else Color(1, 0, 0, 0.3)
	else:
		ghost_preview.visible = false

func _on_hud_tower_selected(type: String):
	_deselect_all()
	if GameManager.can_afford(type):
		selected_tower = type
		is_placing = true
		grid_manager.set_grid_visible(true)
		hud.show_tower_info(type)

func _on_hud_upgrade_requested(path: String):
	if selected_placed_tower and selected_placed_tower.has_method("apply_upgrade"):
		selected_placed_tower.apply_upgrade(path)
		hud.update_hud()

func _on_hud_demolish_requested():
	if not selected_placed_tower:
		return
	var refund = selected_placed_tower.get_total_value() / 2
	GameManager.money += refund
	grid_manager.remove_tower(selected_placed_tower.global_position)
	GameParticles.spawn_death_poof(get_tree(), selected_placed_tower.global_position)
	selected_placed_tower.queue_free()
	_deselect_all()
	hud.update_hud()

func _deselect_all():
	is_placing = false
	selected_tower = ""
	selected_placed_tower = null
	grid_manager.set_grid_visible(false)
	hud.clear_placed_tower()

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and is_placing:
			_place_tower(_get_world_mouse_pos())
		elif event.button_index == MOUSE_BUTTON_LEFT and not is_placing:
			_try_select_placed_tower(_get_world_mouse_pos())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_deselect_all()
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if is_placing or selected_placed_tower:
				_deselect_all()
			else:
				hud.toggle_esc_menu()
		elif event.keycode == KEY_SPACE:
			_on_start_wave_pressed()
		elif event.keycode in tower_hotkeys:
			var idx = tower_hotkeys[event.keycode]
			if idx < tower_types.size():
				_deselect_all()
				_on_hud_tower_selected(tower_types[idx])

func _place_tower(world_pos: Vector2):
	if selected_tower.is_empty():
		return
	if not grid_manager.can_place_tower(world_pos):
		return
	if not GameManager.buy_tower(selected_tower):
		return
	
	var snap_pos = grid_manager.get_tower_snap_position(world_pos)
	var tower: Node2D = tower_scene.instantiate()
	tower.global_position = snap_pos
	tower.setup(selected_tower)
	$TowersContainer.add_child(tower)
	grid_manager.place_tower(world_pos)
	GameParticles.spawn_build_poof(get_tree(), snap_pos)
	
	is_placing = false
	selected_tower = ""
	grid_manager.set_grid_visible(false)
	hud.update_hud()

func _try_select_placed_tower(world_pos: Vector2):
	for tower in $TowersContainer.get_children():
		if tower.global_position.distance_to(world_pos) < 40:
			selected_placed_tower = tower
			hud.show_placed_tower_info(tower)
			return
	if selected_placed_tower:
		_deselect_all()

# Wave management
func _on_start_wave_pressed():
	if GameManager.is_wave_active or GameManager.current_wave >= GameManager.total_waves:
		return
	GameManager.start_wave()
	_spawn_wave()

func _spawn_wave():
	_spawning_complete = false
	_enemies_spawned = 0
	_enemies_finished = 0
	
	var waves = LevelData.get_waves(GameManager.current_level)
	var wave_index = min(GameManager.current_wave - 1, waves.size() - 1)
	var wave_data = waves[wave_index]
	
	for group in wave_data:
		for i in range(group["count"]):
			if not GameManager.game_active:
				return
			_spawn_enemy(group["type"])
			_enemies_spawned += 1
			await get_tree().create_timer(group["delay"]).timeout
	
	_spawning_complete = true
	_check_wave_done()

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
	_enemies_finished += 1
	if is_instance_valid(follow):
		follow.queue_free()
	_check_wave_done()

func _on_enemy_reached_end(follow: PathFollow2D):
	_enemies_finished += 1
	if is_instance_valid(follow):
		follow.queue_free()
	_check_wave_done()

func _check_wave_done():
	if not GameManager.is_wave_active:
		return
	if _spawning_complete and _enemies_finished >= _enemies_spawned:
		GameManager.complete_wave()
	hud.update_hud()

func _on_wave_completed(_wave):
	hud.update_hud()

func _on_game_over():
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/ui/lose_screen.tscn")

func _on_level_complete(_level: int):
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/ui/win_screen.tscn")
