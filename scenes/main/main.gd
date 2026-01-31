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
@onready var tower_grid: GridContainer = $UI/TowerPanel/ScrollContainer/TowerGrid
@onready var ghost_preview: ColorRect = $GhostPreview
@onready var upgrade_panel: PanelContainer = $UI/UpgradePanel

var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy.tscn")
var selected_tower: String = ""
var is_placing: bool = false
var _spawning_complete: bool = false
var _enemies_spawned: int = 0
var _enemies_finished: int = 0

# Selected placed tower for upgrades
var selected_placed_tower: Node2D = null

# All available tower types in order
var tower_types: Array = [
	"arrow_tower", "cannon_tower", "magic_tower", "tesla_tower",
	"frost_tower", "flame_tower", "antiair_tower", "sniper_tower",
	"poison_tower", "bomb_tower", "holy_tower", "barracks_tower",
	"gold_mine", "storm_tower"
]

# Keyboard mapping
var tower_hotkeys: Dictionary = {
	KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_4: 3,
	KEY_5: 4, KEY_6: 5, KEY_7: 6, KEY_8: 7,
	KEY_9: 8, KEY_0: 9,
}

func _ready():
	# Connect signals
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_completed.connect(_on_wave_completed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.level_complete.connect(_on_level_complete)
	
	start_wave_btn.pressed.connect(_on_start_wave_pressed)
	
	# Build tower buttons dynamically
	_build_tower_buttons()
	
	# Load level data
	_setup_level()
	
	# Setup ghost preview
	ghost_preview.visible = false
	ghost_preview.size = Vector2(64, 64)
	ghost_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Hide upgrade panel initially
	if upgrade_panel:
		upgrade_panel.visible = false
	
	_update_ui()

func _build_tower_buttons():
	# Clear existing buttons
	for child in tower_grid.get_children():
		child.queue_free()
	
	for i in range(tower_types.size()):
		var type = tower_types[i]
		var data = GameManager.tower_data.get(type, {})
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(90, 50)
		var hotkey = ""
		if i < 10:
			hotkey = "[%d] " % ((i + 1) % 10)
		btn.text = "%s%s\n%dg" % [hotkey, data.get("name", type), data.get("cost", 0)]
		btn.tooltip_text = data.get("description", "")
		btn.pressed.connect(_on_tower_btn_pressed.bind(type))
		tower_grid.add_child(btn)

func _setup_level():
	var level = GameManager.current_level
	
	var path_points = LevelData.get_path_points(level)
	var curve = Curve2D.new()
	for point in path_points:
		curve.add_point(point)
	enemy_path.curve = curve
	
	grid_manager.mark_path_cells(enemy_path.curve)
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
	
	# Update tower button states
	var buttons = tower_grid.get_children()
	for i in range(min(buttons.size(), tower_types.size())):
		buttons[i].disabled = not GameManager.can_afford(tower_types[i])
	
	start_wave_btn.disabled = GameManager.is_wave_active
	
	# Update upgrade panel if visible
	if upgrade_panel and upgrade_panel.visible and selected_placed_tower:
		_update_upgrade_panel()

func _on_tower_btn_pressed(type: String):
	_deselect_tower()
	_select_tower(type)

func _select_tower(type: String):
	if GameManager.can_afford(type):
		selected_tower = type
		is_placing = true

func _deselect_tower():
	is_placing = false
	selected_tower = ""
	selected_placed_tower = null
	if upgrade_panel:
		upgrade_panel.visible = false

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and is_placing:
			_place_tower(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_LEFT and not is_placing:
			_try_select_placed_tower(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_deselect_tower()
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if is_placing or selected_placed_tower:
				_deselect_tower()
			else:
				get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
		elif event.keycode == KEY_SPACE:
			_on_start_wave_pressed()
		elif event.keycode in tower_hotkeys:
			var idx = tower_hotkeys[event.keycode]
			if idx < tower_types.size():
				_deselect_tower()
				_select_tower(tower_types[idx])

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
	
	is_placing = false
	selected_tower = ""
	_update_ui()

func _try_select_placed_tower(world_pos: Vector2):
	# Check if clicked on an existing tower
	for tower in $TowersContainer.get_children():
		if tower.global_position.distance_to(world_pos) < 40:
			selected_placed_tower = tower
			_show_upgrade_panel(tower)
			return
	
	# Clicked empty space — deselect
	if selected_placed_tower:
		_deselect_tower()

func _show_upgrade_panel(tower: Node2D):
	if not upgrade_panel or not tower.has_method("get_upgrade_info"):
		return
	upgrade_panel.visible = true
	_update_upgrade_panel()

func _update_upgrade_panel():
	if not selected_placed_tower or not selected_placed_tower.has_method("get_upgrade_info"):
		return
	
	var info = selected_placed_tower.get_upgrade_info()
	
	# Clear existing upgrade buttons
	var container = upgrade_panel.get_node_or_null("VBox")
	if not container:
		return
	
	for child in container.get_children():
		child.queue_free()
	
	# Tower name
	var title = Label.new()
	var td = GameManager.tower_data.get(selected_placed_tower.tower_type, {})
	title.text = td.get("name", "Tower")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)
	
	# Upgrade buttons
	for path_key in info:
		var path_info = info[path_key]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(180, 40)
		if path_info["can_upgrade"]:
			btn.text = "%s Lv%d (%dg)\n%s" % [
				path_info["name"],
				path_info["current_level"] + 1,
				path_info["next_cost"],
				path_info["next_desc"]
			]
			btn.disabled = not GameManager.can_afford_upgrade(
				selected_placed_tower.tower_type,
				path_key,
				path_info["current_level"]
			)
			btn.pressed.connect(_on_upgrade_pressed.bind(path_key))
		else:
			btn.text = "%s — MAX" % path_info["name"]
			btn.disabled = true
		container.add_child(btn)

func _on_upgrade_pressed(path: String):
	if selected_placed_tower and selected_placed_tower.has_method("apply_upgrade"):
		selected_placed_tower.apply_upgrade(path)
		_update_ui()

# Wave spawning
func _on_start_wave_pressed():
	if GameManager.is_wave_active:
		return
	if GameManager.current_wave >= GameManager.total_waves:
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
		var count: int = group["count"]
		var delay: float = group["delay"]
		var type: String = group["type"]
		for i in range(count):
			if not GameManager.game_active:
				return
			_spawn_enemy(type)
			_enemies_spawned += 1
			await get_tree().create_timer(delay).timeout
	
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
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/ui/lose_screen.tscn")

func _on_level_complete(_level: int):
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/ui/win_screen.tscn")
