extends CanvasLayer

## Game HUD — WC3/Diablo-inspired UI with styled frames
## Manages tower build menu, tower info panel, game controls, ESC menu

signal tower_selected(type: String)
signal upgrade_requested(path: String)
signal demolish_requested()
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
@onready var upgrade_container: VBoxContainer = $BottomPanel/HBox/InfoPanel/UpgradeScroll/Upgrades
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
var _settings_scene: PackedScene = preload("res://scenes/ui/settings_menu.tscn")
var _settings_instance: Control = null

func _ready():
	# ESC menu
	esc_menu.visible = false
	resume_btn.pressed.connect(_on_resume)
	restart_btn.pressed.connect(_on_restart)
	settings_btn.pressed.connect(_on_settings)
	settings_btn.disabled = false  # Settings now works!
	main_menu_btn.pressed.connect(_on_main_menu)
	start_wave_btn.pressed.connect(func(): wave_start_requested.emit())
	
	_apply_ui_style()
	_build_tower_buttons()
	_clear_info_panel()

# === UI COLORS ===
# Shared palette — dark panels with gold trim, WC3/Diablo vibe
const UI_BG_DARK = Color(0.08, 0.06, 0.04, 0.92)
const UI_BG_MID = Color(0.12, 0.09, 0.06, 0.95)
const UI_GOLD = Color(0.75, 0.60, 0.22)
const UI_GOLD_BRIGHT = Color(1.0, 0.85, 0.32)
const UI_GOLD_DIM = Color(0.50, 0.40, 0.15)
const UI_INNER_BORDER = Color(0.30, 0.24, 0.12, 0.6)
const UI_SHADOW = Color(0.0, 0.0, 0.0, 0.5)

# === UI STYLING — Pure StyleBoxFlat, no stretched textures ===
func _apply_ui_style():
	_style_bottom_panel()
	_style_top_bar()
	_style_esc_menu()
	_style_all_buttons()

func _style_bottom_panel():
	var style = StyleBoxFlat.new()
	style.bg_color = UI_BG_DARK
	# Gold outer border
	style.border_color = UI_GOLD
	style.border_width_top = 3
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	# Content padding
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 6
	# Subtle shadow above panel
	style.shadow_color = UI_SHADOW
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, -2)
	bottom_panel.add_theme_stylebox_override("panel", style)

func _style_top_bar():
	if not top_bar.get_parent():
		return
	var top_panel = PanelContainer.new()
	var parent = top_bar.get_parent()
	var idx = top_bar.get_index()
	parent.remove_child(top_bar)
	top_panel.add_child(top_bar)
	parent.add_child(top_panel)
	parent.move_child(top_panel, idx)
	
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 0
	top_panel.offset_top = 0
	top_panel.offset_right = 0
	top_panel.offset_bottom = 40
	
	var style = StyleBoxFlat.new()
	style.bg_color = UI_BG_DARK
	style.border_color = UI_GOLD
	style.border_width_bottom = 2
	style.border_width_left = 0
	style.border_width_right = 0
	style.border_width_top = 0
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.shadow_color = UI_SHADOW
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	top_panel.add_theme_stylebox_override("panel", style)

func _style_esc_menu():
	var style = StyleBoxFlat.new()
	style.bg_color = UI_BG_MID
	style.border_color = UI_GOLD
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(20)
	# Drop shadow
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	esc_menu.add_theme_stylebox_override("panel", style)

func _style_all_buttons():
	var normal = _make_ui_btn_style(UI_BG_MID, UI_GOLD)
	var hover = _make_ui_btn_style(Color(0.16, 0.12, 0.08, 0.95), UI_GOLD_BRIGHT)
	var pressed = _make_ui_btn_style(Color(0.06, 0.04, 0.02, 0.95), UI_GOLD)
	var disabled = _make_ui_btn_style(Color(0.08, 0.07, 0.06, 0.7), UI_GOLD_DIM)
	
	for btn in [resume_btn, restart_btn, settings_btn, main_menu_btn, start_wave_btn]:
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_stylebox_override("disabled", disabled)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _make_ui_btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(6)
	return style

# === TOWER SLOT STYLES ===
func _make_tower_slot_style(border_color: Color, bg_color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(5)
	return style

var _slot_normal: StyleBoxFlat
var _slot_hover: StyleBoxFlat
var _slot_pressed: StyleBoxFlat
var _slot_disabled: StyleBoxFlat

func _init_tower_slot_styles():
	# Normal — dark background, warm gold border
	_slot_normal = _make_tower_slot_style(
		Color(0.70, 0.55, 0.20), Color(0.12, 0.10, 0.08, 0.9))
	# Hover — brighter gold, slightly lighter bg
	_slot_hover = _make_tower_slot_style(
		Color(1.0, 0.85, 0.30), Color(0.18, 0.15, 0.10, 0.95))
	# Pressed — inset feel
	_slot_pressed = _make_tower_slot_style(
		Color(0.90, 0.70, 0.20), Color(0.08, 0.06, 0.04, 0.95))
	# Disabled — dim
	_slot_disabled = _make_tower_slot_style(
		Color(0.35, 0.30, 0.15, 0.5), Color(0.08, 0.07, 0.06, 0.7))

# === TOWER BUTTONS ===
func _build_tower_buttons():
	for child in tower_grid.get_children():
		child.queue_free()
	
	_init_tower_slot_styles()
	
	for i in range(tower_types.size()):
		var type = tower_types[i]
		var data = GameManager.tower_data.get(type, {})
		
		# Styled button with gold border
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(68, 68)
		btn.text = ""
		btn.add_theme_stylebox_override("normal", _slot_normal)
		btn.add_theme_stylebox_override("hover", _slot_hover)
		btn.add_theme_stylebox_override("pressed", _slot_pressed)
		btn.add_theme_stylebox_override("disabled", _slot_disabled)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		
		# Tower sprite inside the button
		var tex_path = "res://assets/sprites/towers/%s.png" % type
		if ResourceLoader.exists(tex_path):
			var icon = TextureRect.new()
			icon.texture = load(tex_path)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(icon)
		
		# Hotkey + name + cost in tooltip
		var hotkey = "[%d] " % ((i + 1) % 10) if i < 10 else ""
		btn.tooltip_text = "%s%s — %dg\n%s" % [
			hotkey, data.get("name", type),
			data.get("cost", 0), data.get("description", "")
		]
		
		btn.pressed.connect(func(): tower_selected.emit(type))
		tower_grid.add_child(btn)

# === HUD UPDATE ===
func update_hud():
	gold_label.text = "⛏ %d" % GameManager.money
	lives_label.text = "♥ %d" % GameManager.lives
	wave_label.text = "Wave %d/%d" % [GameManager.current_wave, GameManager.total_waves]
	level_label.text = "%s" % LevelData.get_level_name(GameManager.current_level)
	
	var buttons = tower_grid.get_children()
	for i in range(min(buttons.size(), tower_types.size())):
		var can = GameManager.can_afford(tower_types[i])
		buttons[i].modulate = Color(1, 1, 1, 1) if can else Color(0.4, 0.4, 0.4, 0.6)
		buttons[i].disabled = not can
	
	start_wave_btn.disabled = GameManager.is_wave_active
	
	if _selected_placed_tower and is_instance_valid(_selected_placed_tower):
		_update_tower_info(_selected_placed_tower)

# === TOWER INFO ===
func show_tower_info(tower_type: String):
	var data = GameManager.tower_data.get(tower_type, {})
	info_title.text = data.get("name", "Unknown")
	info_desc.text = data.get("description", "")
	info_stats.text = "DMG: %d  RNG: %d  SPD: %.1f" % [
		data.get("damage", 0), int(data.get("range", 0)), data.get("fire_rate", 0)
	]
	_clear_upgrades()

func show_placed_tower_info(tower: Node2D):
	_selected_placed_tower = tower
	_update_tower_info(tower)

func _update_tower_info(tower: Node2D):
	if not tower or not is_instance_valid(tower):
		return
	
	var data = GameManager.tower_data.get(tower.tower_type, {})
	info_title.text = data.get("name", "Tower")
	info_desc.text = "Click upgrade to enhance"
	info_stats.text = "DMG: %d  RNG: %d  SPD: %.1f" % [
		tower.damage, int(tower.attack_range), tower.fire_rate
	]
	
	# Clear and rebuild
	_clear_upgrades()
	
	# Upgrade buttons
	if tower.has_method("get_upgrade_info"):
		var upgrade_info = tower.get_upgrade_info()
		for path_key in upgrade_info:
			var path = upgrade_info[path_key]
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(0, 26)
			
			if path["can_upgrade"]:
				btn.text = "⬆ %s Lv%d — %dg (%s)" % [
					path["name"], path["current_level"] + 1,
					path["next_cost"], path["next_desc"]
				]
				btn.disabled = not GameManager.can_afford_upgrade(
					tower.tower_type, path_key, path["current_level"]
				)
				var pk = path_key
				btn.pressed.connect(func(): upgrade_requested.emit(pk))
			else:
				btn.text = "✓ %s — MAX" % path["name"]
				btn.disabled = true
			
			upgrade_container.add_child(btn)
	
	# === DEMOLISH BUTTON — always added to upgrade container ===
	var demolish = Button.new()
	demolish.custom_minimum_size = Vector2(0, 26)
	demolish.name = "DemolishBtn"
	
	# Calculate refund
	var refund = 0
	if tower.has_method("get_total_value"):
		refund = tower.get_total_value() / 2
	else:
		refund = data.get("cost", 0) / 2
	
	demolish.text = "🔨 Demolish (+%dg)" % refund
	demolish.modulate = Color(1.0, 0.7, 0.7)
	demolish.pressed.connect(func(): demolish_requested.emit())
	upgrade_container.add_child(demolish)

func clear_placed_tower():
	_selected_placed_tower = null
	_clear_info_panel()

func _clear_upgrades():
	for child in upgrade_container.get_children():
		child.queue_free()

func _clear_info_panel():
	info_title.text = "Tower Defense"
	info_stats.text = "Select a tower to build"
	info_desc.text = "or click a placed tower to upgrade"
	_clear_upgrades()

# === ESC MENU ===
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
	if _settings_instance:
		return
	_settings_instance = _settings_scene.instantiate()
	_settings_instance.closed.connect(_on_settings_closed)
	add_child(_settings_instance)

func _on_settings_closed():
	if _settings_instance:
		_settings_instance.queue_free()
		_settings_instance = null

func _on_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
