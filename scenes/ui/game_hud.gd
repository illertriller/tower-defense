extends CanvasLayer

## Game HUD — WC3-inspired bottom panel UI
## Manages tower build menu, tower info panel, game controls, ESC menu

signal tower_selected(type: String)
signal upgrade_requested(path: String)
signal wave_start_requested()

@onready var top_bar: HBoxContainer = $TopBar
@onready var gold_label: Label = $TopBar/GoldLabel
@onready var lives_label: Label = $TopBar/LivesLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var level_label: Label = $TopBar/LevelLabel

# Bottom panel
@onready var bottom_panel: PanelContainer = $BottomPanel
@onready var tower_grid: GridContainer = $BottomPanel/HBox/TowerMenu/ScrollContainer/TowerGrid
@onready var info_panel: VBoxContainer = $BottomPanel/HBox/InfoPanel
@onready var info_title: Label = $BottomPanel/HBox/InfoPanel/Title
@onready var info_stats: Label = $BottomPanel/HBox/InfoPanel/Stats
@onready var info_desc: Label = $BottomPanel/HBox/InfoPanel/Desc
@onready var upgrade_container: VBoxContainer = $BottomPanel/HBox/InfoPanel/Upgrades
@onready var controls_container: VBoxContainer = $BottomPanel/HBox/Controls

# ESC menu
@onready var esc_menu: PanelContainer = $EscMenu
@onready var resume_btn: Button = $EscMenu/VBox/ResumeBtn
@onready var restart_btn: Button = $EscMenu/VBox/RestartBtn
@onready var settings_btn: Button = $EscMenu/VBox/SettingsBtn
@onready var main_menu_btn: Button = $EscMenu/VBox/MainMenuBtn

# Start wave button
@onready var start_wave_btn: Button = $BottomPanel/HBox/Controls/StartWaveBtn

var tower_types: Array = [
	"arrow_tower", "cannon_tower", "magic_tower", "tesla_tower",
	"frost_tower", "flame_tower", "antiair_tower", "sniper_tower",
	"poison_tower", "bomb_tower", "holy_tower", "barracks_tower",
	"gold_mine", "storm_tower"
]

var _selected_placed_tower: Node2D = null

func _ready():
	# ESC menu
	esc_menu.visible = false
	resume_btn.pressed.connect(_on_resume)
	restart_btn.pressed.connect(_on_restart)
	settings_btn.pressed.connect(_on_settings)
	main_menu_btn.pressed.connect(_on_main_menu)
	start_wave_btn.pressed.connect(func(): wave_start_requested.emit())
	
	_build_tower_buttons()
	_clear_info_panel()

func _build_tower_buttons():
	for child in tower_grid.get_children():
		child.queue_free()
	
	for i in range(tower_types.size()):
		var type = tower_types[i]
		var data = GameManager.tower_data.get(type, {})
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 64)
		
		# Hotkey label
		var hotkey = ""
		if i < 10:
			hotkey = "[%d]" % ((i + 1) % 10)
		
		btn.text = "%s\n%s\n%dg" % [hotkey, data.get("name", type).substr(0, 8), data.get("cost", 0)]
		btn.tooltip_text = "%s — %s" % [data.get("name", ""), data.get("description", "")]
		btn.pressed.connect(func(): tower_selected.emit(type))
		tower_grid.add_child(btn)

func update_hud():
	gold_label.text = "⛏ %d" % GameManager.money
	lives_label.text = "♥ %d" % GameManager.lives
	wave_label.text = "Wave %d/%d" % [GameManager.current_wave, GameManager.total_waves]
	level_label.text = "%s" % LevelData.get_level_name(GameManager.current_level)
	
	# Update tower button affordability
	var buttons = tower_grid.get_children()
	for i in range(min(buttons.size(), tower_types.size())):
		buttons[i].disabled = not GameManager.can_afford(tower_types[i])
	
	start_wave_btn.disabled = GameManager.is_wave_active
	
	# Update upgrade buttons if showing a placed tower
	if _selected_placed_tower:
		_update_tower_info(_selected_placed_tower)

func show_tower_info(tower_type: String):
	"""Show info for a tower type (when hovering build menu)."""
	var data = GameManager.tower_data.get(tower_type, {})
	info_title.text = data.get("name", "Unknown")
	info_desc.text = data.get("description", "")
	
	var stats_text = "DMG: %d  RNG: %d  SPD: %.1f" % [
		data.get("damage", 0),
		int(data.get("range", 0)),
		data.get("fire_rate", 0)
	]
	info_stats.text = stats_text
	
	# Clear upgrades section
	for child in upgrade_container.get_children():
		child.queue_free()

func show_placed_tower_info(tower: Node2D):
	"""Show info + upgrades for a placed tower."""
	_selected_placed_tower = tower
	_update_tower_info(tower)

func _update_tower_info(tower: Node2D):
	if not tower or not tower.has_method("get_upgrade_info"):
		return
	
	var data = GameManager.tower_data.get(tower.tower_type, {})
	info_title.text = data.get("name", "Tower")
	info_desc.text = "Click upgrade to enhance"
	
	info_stats.text = "DMG: %d  RNG: %d  SPD: %.1f" % [
		tower.damage, int(tower.attack_range), tower.fire_rate
	]
	
	# Build upgrade buttons
	for child in upgrade_container.get_children():
		child.queue_free()
	
	var upgrade_info = tower.get_upgrade_info()
	for path_key in upgrade_info:
		var path = upgrade_info[path_key]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 32)
		
		if path["can_upgrade"]:
			btn.text = "⬆ %s Lv%d — %dg (%s)" % [
				path["name"], path["current_level"] + 1,
				path["next_cost"], path["next_desc"]
			]
			btn.disabled = not GameManager.can_afford_upgrade(
				tower.tower_type, path_key, path["current_level"]
			)
			var pk = path_key  # Capture for lambda
			btn.pressed.connect(func(): upgrade_requested.emit(pk))
		else:
			btn.text = "✓ %s — MAX" % path["name"]
			btn.disabled = true
		
		upgrade_container.add_child(btn)

func clear_placed_tower():
	_selected_placed_tower = null
	_clear_info_panel()

func _clear_info_panel():
	info_title.text = "Tower Defense"
	info_stats.text = "Select a tower to build"
	info_desc.text = "or click a placed tower to upgrade"
	for child in upgrade_container.get_children():
		child.queue_free()

# ESC Menu
func toggle_esc_menu():
	esc_menu.visible = not esc_menu.visible
	get_tree().paused = esc_menu.visible

func _on_resume():
	esc_menu.visible = false
	get_tree().paused = false

func _on_restart():
	get_tree().paused = false
	GameManager.start_level(GameManager.current_level)
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_settings():
	pass  # Phase 4

func _on_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
