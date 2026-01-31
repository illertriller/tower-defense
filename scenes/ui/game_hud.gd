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

func _ready():
	# ESC menu
	esc_menu.visible = false
	resume_btn.pressed.connect(_on_resume)
	restart_btn.pressed.connect(_on_restart)
	settings_btn.pressed.connect(_on_settings)
	main_menu_btn.pressed.connect(_on_main_menu)
	start_wave_btn.pressed.connect(func(): wave_start_requested.emit())
	
	_apply_ui_style()
	_build_tower_buttons()
	_clear_info_panel()

# === UI STYLING ===
func _apply_ui_style():
	# Style bottom panel with frame texture
	var panel_tex = _load_tex("res://assets/sprites/ui/panel_frame.png")
	if panel_tex:
		var panel_style = StyleBoxTexture.new()
		panel_style.texture = panel_tex
		panel_style.texture_margin_left = 16
		panel_style.texture_margin_right = 16
		panel_style.texture_margin_top = 16
		panel_style.texture_margin_bottom = 16
		panel_style.content_margin_left = 12
		panel_style.content_margin_right = 12
		panel_style.content_margin_top = 8
		panel_style.content_margin_bottom = 8
		bottom_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Style ESC menu panel
	var info_tex = _load_tex("res://assets/sprites/ui/info_frame.png")
	if info_tex:
		var esc_style = StyleBoxTexture.new()
		esc_style.texture = info_tex
		esc_style.texture_margin_left = 12
		esc_style.texture_margin_right = 12
		esc_style.texture_margin_top = 12
		esc_style.texture_margin_bottom = 12
		esc_style.content_margin_left = 16
		esc_style.content_margin_right = 16
		esc_style.content_margin_top = 16
		esc_style.content_margin_bottom = 16
		esc_menu.add_theme_stylebox_override("panel", esc_style)
	
	# Style top bar background
	var topbar_tex = _load_tex("res://assets/sprites/ui/topbar_frame.png")
	if topbar_tex:
		var topbar_style = StyleBoxTexture.new()
		topbar_style.texture = topbar_tex
		topbar_style.texture_margin_left = 16
		topbar_style.texture_margin_right = 16
		topbar_style.texture_margin_top = 8
		topbar_style.texture_margin_bottom = 8
		topbar_style.content_margin_left = 12
		topbar_style.content_margin_right = 12
		# Wrap top_bar in a panel if needed
		if top_bar.get_parent():
			var top_panel = PanelContainer.new()
			var parent = top_bar.get_parent()
			var idx = top_bar.get_index()
			parent.remove_child(top_bar)
			top_panel.add_child(top_bar)
			top_panel.add_theme_stylebox_override("panel", topbar_style)
			parent.add_child(top_panel)
			parent.move_child(top_panel, idx)
			# Position it
			top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
			top_panel.offset_left = 10
			top_panel.offset_top = 8
			top_panel.offset_right = -10
			top_panel.offset_bottom = 40
	
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
	var style = StyleBoxTexture.new()
	style.texture = tex
	style.texture_margin_left = 8
	style.texture_margin_right = 8
	style.texture_margin_top = 6
	style.texture_margin_bottom = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
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

# === TOWER BUTTONS ===
func _build_tower_buttons():
	for child in tower_grid.get_children():
		child.queue_free()
	
	for i in range(tower_types.size()):
		var type = tower_types[i]
		var data = GameManager.tower_data.get(type, {})
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 64)
		
		var hotkey = ""
		if i < 10:
			hotkey = "[%d]" % ((i + 1) % 10)
		
		btn.text = "%s\n%s\n%dg" % [hotkey, data.get("name", type).substr(0, 8), data.get("cost", 0)]
		btn.tooltip_text = "%s — %s" % [data.get("name", ""), data.get("description", "")]
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
		buttons[i].disabled = not GameManager.can_afford(tower_types[i])
	
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
	pass

func _on_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
