extends Node2D

## Main scene controller
## Handles UI updates, tower placement, wave management

@export var tower_scene: PackedScene

@onready var enemy_path: Path2D = $EnemyPath
@onready var money_label: Label = $UI/TopBar/MoneyLabel
@onready var lives_label: Label = $UI/TopBar/LivesLabel
@onready var wave_label: Label = $UI/TopBar/WaveLabel
@onready var start_wave_btn: Button = $UI/StartWaveBtn
@onready var arrow_btn: Button = $UI/TowerPanel/ArrowBtn
@onready var cannon_btn: Button = $UI/TowerPanel/CannonBtn
@onready var magic_btn: Button = $UI/TowerPanel/MagicBtn

var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy.tscn")
var selected_tower: String = ""
var is_placing: bool = false

func _ready():
	# Connect signals
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_completed.connect(_on_wave_completed)
	GameManager.game_over.connect(_on_game_over)
	
	# Connect buttons
	arrow_btn.pressed.connect(func(): _select_tower("arrow_tower"))
	cannon_btn.pressed.connect(func(): _select_tower("cannon_tower"))
	magic_btn.pressed.connect(func(): _select_tower("magic_tower"))
	start_wave_btn.pressed.connect(_on_start_wave_pressed)
	
	# Initial UI update
	_update_ui()

func _update_ui():
	money_label.text = "Gold: %d" % GameManager.money
	lives_label.text = "Lives: %d" % GameManager.lives
	wave_label.text = "Wave: %d" % GameManager.current_wave
	
	# Update button states
	arrow_btn.disabled = not GameManager.can_afford("arrow_tower")
	cannon_btn.disabled = not GameManager.can_afford("cannon_tower")
	magic_btn.disabled = not GameManager.can_afford("magic_tower")
	start_wave_btn.disabled = GameManager.is_wave_active

func _select_tower(type: String):
	if GameManager.can_afford(type):
		selected_tower = type
		is_placing = true

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and is_placing:
			_place_tower(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Cancel placement
			is_placing = false
			selected_tower = ""

func _place_tower(pos: Vector2):
	if not GameManager.buy_tower(selected_tower):
		return
	
	var tower = tower_scene.instantiate()
	tower.global_position = pos
	tower.setup(selected_tower)
	$TowersContainer.add_child(tower)
	
	# Reset placement
	is_placing = false
	selected_tower = ""
	_update_ui()

func _on_start_wave_pressed():
	if GameManager.is_wave_active:
		return
	
	GameManager.start_wave()
	_spawn_wave()

func _spawn_wave():
	var wave_data = _get_wave_data(GameManager.current_wave)
	var total_enemies = 0
	
	for group in wave_data:
		for i in group["count"]:
			total_enemies += 1
			_spawn_enemy(group["type"])
			await get_tree().create_timer(group["delay"]).timeout

func _spawn_enemy(type: String):
	var follow = PathFollow2D.new()
	follow.rotates = false
	follow.loop = false
	enemy_path.add_child(follow)
	
	var enemy = enemy_scene.instantiate()
	enemy.setup(type)
	follow.add_child(enemy)
	
	enemy.died.connect(func(): _on_enemy_removed(follow))
	enemy.reached_end.connect(func(): _on_enemy_removed(follow))

func _on_enemy_removed(follow: PathFollow2D):
	if is_instance_valid(follow):
		follow.queue_free()
	
	# Check if wave is done (no more enemies on path)
	await get_tree().create_timer(0.1).timeout
	if GameManager.is_wave_active:
		var remaining = enemy_path.get_child_count()
		if remaining == 0:
			GameManager.complete_wave()
	_update_ui()

func _get_wave_data(wave: int) -> Array:
	var waves = [
		[{"type": "basic", "count": 5, "delay": 1.0}],
		[{"type": "basic", "count": 8, "delay": 0.8}],
		[{"type": "basic", "count": 5, "delay": 1.0}, {"type": "fast", "count": 3, "delay": 0.6}],
		[{"type": "basic", "count": 8, "delay": 0.8}, {"type": "fast", "count": 5, "delay": 0.5}],
		[{"type": "basic", "count": 6, "delay": 0.8}, {"type": "fast", "count": 4, "delay": 0.5}, {"type": "tank", "count": 2, "delay": 2.0}],
		[{"type": "basic", "count": 10, "delay": 0.6}, {"type": "fast", "count": 6, "delay": 0.4}, {"type": "tank", "count": 3, "delay": 1.5}],
		[{"type": "fast", "count": 12, "delay": 0.3}, {"type": "tank", "count": 4, "delay": 1.2}],
		[{"type": "basic", "count": 15, "delay": 0.5}, {"type": "fast", "count": 8, "delay": 0.3}, {"type": "tank", "count": 5, "delay": 1.0}],
		[{"type": "fast", "count": 15, "delay": 0.25}, {"type": "tank", "count": 8, "delay": 0.8}],
		[{"type": "basic", "count": 10, "delay": 0.5}, {"type": "fast", "count": 10, "delay": 0.3}, {"type": "tank", "count": 5, "delay": 0.8}, {"type": "boss", "count": 1, "delay": 3.0}],
	]
	var index = min(wave - 1, waves.size() - 1)
	return waves[index]

func _on_money_changed(_amount): _update_ui()
func _on_lives_changed(_amount): _update_ui()
func _on_wave_started(_wave): _update_ui()
func _on_wave_completed(_wave): _update_ui()
func _on_game_over():
	# TODO: Game over screen
	start_wave_btn.text = "GAME OVER"
	start_wave_btn.disabled = true
