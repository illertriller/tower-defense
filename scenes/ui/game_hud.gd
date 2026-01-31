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
	
	# UI textures use linear filtering for smooth scaling
	# (game world stays on nearest-neighbor for crisp pixel art)
	_set_ui_linear_filter()
	
	_apply_ui_style()
	_build_tower_buttons()
	_clear_info_panel()

func _set_ui_linear_filter():
	# Apply linear filtering to all UI containers so frame textures
	# render smooth instead of chunky nearest-neighbor pixels
	# (game world stays on nearest-neighbor for crisp pixel art sprites)
	for node in get_children():
		if node is CanvasItem:
			node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

# === UI STYLING ===
func _apply_ui_style():
	# Style bottom panel with frame texture
	# Panel is 512x128 — big margins protect the ornate borders from stretching
	var panel_tex = _load_tex("res://assets/sprites/ui/panel_frame.png")
	if panel_tex:
		var panel_style = StyleBoxTexture.new()
		panel_style.texture = panel_tex
		# Large margins = ornate corners/edges stay pixel-perfect, only center stretches
		panel_style.texture_margin_left = 64
		panel_style.texture_margin_right = 64
		panel_style.texture_margin_top = 48
		panel_style.texture_margin_bottom = 48
		panel_style.content_margin_left = 12
		panel_style.content_margin_right = 12
		panel_style.content_margin_top = 8
		panel_style.content_margin_bottom = 8
		bottom_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Style ESC menu panel (256x256 — generous margins for all corners)
	var info_tex = _load_tex("res://assets/sprites/ui/info_frame.png")
	if info_tex:
		var esc_style = StyleBoxTexture.new()
		esc_style.texture = info_tex
		esc_style.texture_margin_left = 48
		esc_style.texture_margin_right = 48
		esc_style.texture_margin_top = 48
		esc_style.texture_margin_bottom = 48
		esc_style.content_margin_left = 16
		esc_style.content_margin_right = 16
		esc_style.content_margin_top = 16
		esc_style.content_margin_bottom = 16
		esc_menu.add_theme_stylebox_override("panel", esc_style)
	
	# Style top bar background (512x64 — wide margins for edge details)
	var topbar_tex = _load_tex("res://assets/sprites/ui/topbar_frame.png")
	if topbar_tex:
		var topbar_style = StyleBoxTexture.new()
		topbar_style.texture = topbar_tex
		topbar_style.texture_margin_left = 64
		topbar_style.texture_margin_right = 64
		topbar_style.texture_margin_top = 24
		topbar_style.texture_margin_bottom = 24
		topbar_style.content_margin_left = 12
		topbar_style.content_margin_right = 12
		# Wrap top_bar in a panel
		if top_bar.get_parent():
			var top_panel = PanelContainer.new()
			var parent = top_bar.get_parent()
			var idx = top_bar.get_index()
			parent.remove_child(top_bar)
			top_panel.add_child(top_bar)
			top_panel.add_theme_stylebox_override("panel", topbar_style)
			parent.add_child(top_panel)
			parent.move_child(top_panel, idx)
			top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
			top_panel.offset_left = 0
			top_panel.offset_top = 0
			top_panel.offset_right = 0
			top_panel.offset_bottom = 44
			top_panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	
	# Style buttons with textures
	_style_all_buttons()

func _style_all_buttons():
	var btn_normal = _load_tex("res://assets/sprites/ui/button_normal.png")
	var btn_hover = _load_tex("res://assets/sprites/ui/button_hover.png")
	var btn_pressed = _load_tex("res://assets/sprites/ui/button_pressed.png")
	if not btn_normal:
		return
	
	var normal_style = _make_btn_stylebox(btn_normal)
	var hover_style = _make_btn_stylebox(btn_hover if btn_hover else btn_normal)
	var pressed_style = _make_btn_stylebox(btn_pressed if btn_pressed else btn_normal)
	var disabled_style = _make_btn_stylebox(btn_normal)
	disabled_style.modulate_color = Color(0.5, 0.5, 0.5, 0.7)
	
	# Apply to specific buttons
	for btn in [resume_btn, restart_btn, settings_btn, main_menu_btn, start_wave_btn]:
		_apply_btn_style(btn, normal_style, hover_style, pressed_style, disabled_style)

func _make_btn_stylebox(tex: Texture2D) -> StyleBoxTexture:
	# Buttons are 256x64 — use big margins to protect ornate edges
	var style = StyleBoxTexture.new()
	style.texture = tex
	style.texture_margin_left = 24
	style.texture_margin_right = 24
	style.texture_margin_top = 16
	style.texture_margin_bottom = 16
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _apply_btn_style(btn: Button, normal: StyleBoxTexture, hover: StyleBoxTexture, pressed: StyleBoxTexture, disabled: StyleBoxTexture):
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

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
