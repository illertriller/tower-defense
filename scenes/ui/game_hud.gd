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
	
	# Button audio for ESC menu and controls
	for btn in [resume_btn, restart_btn, settings_btn, main_menu_btn, start_wave_btn]:
		btn.pressed.connect(func(): AudioManager.play_sfx("button_click"))
		btn.mouse_entered.connect(func(): AudioManager.play_sfx("button_hover", -8.0))
	
	_apply_ui_style()
	_build_tower_buttons()
	_clear_info_panel()

# === UI PALETTE ===
const UI_BG = Color(0.08, 0.06, 0.04, 0.92)
const UI_BG_LIGHT = Color(0.12, 0.09, 0.06, 0.95)
const UI_GOLD = Color(0.75, 0.60, 0.22)
const UI_GOLD_BRIGHT = Color(1.0, 0.85, 0.32)
const UI_GOLD_DIM = Color(0.50, 0.40, 0.15)
const UI_SHADOW = Color(0.0, 0.0, 0.0, 0.5)

const DECO_PATH = "res://assets/sprites/ui/decorations/"
const UI_TEX = "res://assets/sprites/ui/"

# === UI STYLING — Texture-based panels + ornate decorations ===
func _apply_ui_style():
	_style_bottom_panel()
	_style_info_panel()
	_style_top_bar()
	_style_esc_menu()
	_style_all_buttons()
	_add_minimap_frame()

func _style_bottom_panel():
	# Texture-based panel background (dark brick pattern)
	var tex = _load_tex(UI_TEX + "ui_panel_bg.png")
	if tex:
		var style = _make_tex_style(tex, 20, 12, 20, 12, 10, 10, 10, 6)
		style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		bottom_panel.add_theme_stylebox_override("panel", style)
	else:
		# Fallback flat style
		var style = StyleBoxFlat.new()
		style.bg_color = UI_BG
		style.border_color = UI_GOLD
		style.border_width_top = 3
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 10
		style.content_margin_bottom = 6
		style.shadow_color = UI_SHADOW
		style.shadow_size = 6
		style.shadow_offset = Vector2(0, -2)
		bottom_panel.add_theme_stylebox_override("panel", style)
	
	# Decorative overlays at native size (no stretching!)
	_add_panel_decorations()

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
	
	# Texture-based top bar frame (gold border with gem studs)
	var tex = _load_tex(UI_TEX + "topbar_frame.png")
	if tex:
		var style = _make_tex_style(tex, 48, 8, 48, 8, 16, 6, 16, 6)
		style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		top_panel.add_theme_stylebox_override("panel", style)
	else:
		var style = StyleBoxFlat.new()
		style.bg_color = UI_BG
		style.border_color = UI_GOLD
		style.border_width_bottom = 2
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		style.shadow_color = UI_SHADOW
		style.shadow_size = 4
		style.shadow_offset = Vector2(0, 2)
		top_panel.add_theme_stylebox_override("panel", style)
	
	# Emblem decoration on top bar
	var emblem_tex = _load_tex(DECO_PATH + "topbar_emblem.png")
	if emblem_tex:
		var emblem = _make_deco_rect(emblem_tex)
		add_child(emblem)
		emblem.position = Vector2(6, (40 - emblem_tex.get_height()) / 2.0)

func _add_panel_decorations():
	# Place decorations as direct children of a Control overlay on the CanvasLayer
	# so PanelContainer doesn't force-resize them
	var vp_size = get_viewport().get_visible_rect().size
	var panel_top_y = vp_size.y - 175  # bottom panel offset_top
	
	# Center gem at top of bottom panel
	var gem_tex = _load_tex(DECO_PATH + "panel_gem.png")
	if gem_tex:
		var gem = _make_deco_rect(gem_tex)
		add_child(gem)
		gem.position = Vector2(vp_size.x / 2.0 - gem_tex.get_width() / 2.0, panel_top_y - gem_tex.get_height() / 2.0)
	
	# Corner ornaments at top corners of bottom panel
	var corner_tex = _load_tex(DECO_PATH + "panel_corner_ornament.png")
	if corner_tex:
		var left = _make_deco_rect(corner_tex)
		add_child(left)
		left.position = Vector2(4, panel_top_y - 4)
		
		var right = _make_deco_rect(corner_tex)
		right.flip_h = true
		add_child(right)
		right.position = Vector2(vp_size.x - corner_tex.get_width() - 4, panel_top_y - 4)
	
	# Decorative frame border strip at top of bottom panel
	var border_tex = _load_tex(UI_TEX + "ui_frame_border.png")
	if border_tex:
		var border = _make_deco_rect(border_tex)
		border.stretch_mode = TextureRect.STRETCH_SCALE
		border.size = Vector2(vp_size.x, border_tex.get_height())
		add_child(border)
		border.position = Vector2(0, panel_top_y - border_tex.get_height() + 1)

func _make_deco_rect(tex: Texture2D) -> TextureRect:
	var rect = TextureRect.new()
	rect.texture = tex
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.stretch_mode = TextureRect.STRETCH_KEEP
	rect.z_index = 5
	return rect

func _style_esc_menu():
	# Texture-based ESC menu panel (ornate frame)
	var tex = _load_tex(UI_TEX + "panel_frame.png")
	if tex:
		var style = _make_tex_style(tex, 40, 20, 40, 20, 24, 24, 24, 24)
		esc_menu.add_theme_stylebox_override("panel", style)
	else:
		var style = StyleBoxFlat.new()
		style.bg_color = UI_BG_LIGHT
		style.border_color = UI_GOLD
		style.set_border_width_all(3)
		style.set_corner_radius_all(6)
		style.set_content_margin_all(24)
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
		style.shadow_size = 12
		style.shadow_offset = Vector2(0, 4)
		esc_menu.add_theme_stylebox_override("panel", style)

func _style_all_buttons():
	# Texture-based buttons (stone tablet with gold corners)
	var tex_n = _load_tex(UI_TEX + "button_normal.png")
	var tex_h = _load_tex(UI_TEX + "button_hover.png")
	var tex_p = _load_tex(UI_TEX + "button_pressed.png")
	
	var normal: StyleBox
	var hover: StyleBox
	var pressed: StyleBox
	var disabled: StyleBox
	
	if tex_n and tex_h and tex_p:
		normal = _make_tex_style(tex_n, 20, 16, 20, 16, 8, 6, 8, 6)
		hover = _make_tex_style(tex_h, 20, 16, 20, 16, 8, 6, 8, 6)
		pressed = _make_tex_style(tex_p, 20, 16, 20, 16, 8, 6, 8, 6)
		disabled = _make_tex_style(tex_n, 20, 16, 20, 16, 8, 6, 8, 6)
		disabled.modulate_color = Color(0.5, 0.5, 0.5, 0.7)
	else:
		normal = _make_flat_btn(UI_BG_LIGHT, UI_GOLD)
		hover = _make_flat_btn(Color(0.16, 0.12, 0.08, 0.95), UI_GOLD_BRIGHT)
		pressed = _make_flat_btn(Color(0.06, 0.04, 0.02, 0.95), UI_GOLD)
		disabled = _make_flat_btn(Color(0.08, 0.07, 0.06, 0.7), UI_GOLD_DIM)
	
	for btn in [resume_btn, restart_btn, settings_btn, main_menu_btn, start_wave_btn]:
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_stylebox_override("disabled", disabled)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _make_flat_btn(bg: Color, border: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(6)
	return style

# === DECORATION HELPERS ===

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _make_tex_style(tex: Texture2D, tl: float, tt: float, tr: float, tb: float,
		cl: float = 8, ct: float = 8, cr: float = 8, cb: float = 8) -> StyleBoxTexture:
	var s = StyleBoxTexture.new()
	s.texture = tex
	s.texture_margin_left = tl
	s.texture_margin_top = tt
	s.texture_margin_right = tr
	s.texture_margin_bottom = tb
	s.content_margin_left = cl
	s.content_margin_top = ct
	s.content_margin_right = cr
	s.content_margin_bottom = cb
	return s

# === INFO PANEL TEXTURE WRAP ===
func _style_info_panel():
	var tex = _load_tex(UI_TEX + "ui_info_panel_bg.png")
	if not tex:
		return
	var wrapper = PanelContainer.new()
	wrapper.name = "InfoPanelBg"
	var parent = info_panel.get_parent()
	var idx = info_panel.get_index()
	# Transfer layout properties to wrapper
	wrapper.size_flags_horizontal = info_panel.size_flags_horizontal
	wrapper.size_flags_stretch_ratio = info_panel.size_flags_stretch_ratio
	info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_panel.size_flags_stretch_ratio = 1.0
	parent.remove_child(info_panel)
	wrapper.add_child(info_panel)
	parent.add_child(wrapper)
	parent.move_child(wrapper, idx)
	var style = _make_tex_style(tex, 20, 14, 20, 14, 6, 4, 6, 4)
	wrapper.add_theme_stylebox_override("panel", style)

# === MINIMAP FRAME ===
func _add_minimap_frame():
	var tex = _load_tex(UI_TEX + "ui_minimap_frame.png")
	if not tex:
		return
	var minimap_margin = get_node_or_null("MinimapMargin")
	if not minimap_margin:
		return
	var frame = NinePatchRect.new()
	frame.name = "MinimapFrame"
	frame.texture = tex
	frame.patch_margin_left = 16
	frame.patch_margin_right = 16
	frame.patch_margin_top = 16
	frame.patch_margin_bottom = 16
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap_margin.add_child(frame)
	minimap_margin.move_child(frame, 0)

# === TOWER SLOT STYLES ===
func _make_tower_slot_style(border_color: Color, bg_color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(5)
	return style

var _slot_normal: StyleBox
var _slot_hover: StyleBox
var _slot_pressed: StyleBox
var _slot_disabled: StyleBox

func _init_tower_slot_styles():
	# Texture-based tower slots (stone with blue-purple frame + gold corners)
	var tex_normal = _load_tex(UI_TEX + "ui_tower_slot_bg.png")
	var tex_selected = _load_tex(UI_TEX + "ui_tower_slot_selected.png")
	
	if tex_normal and tex_selected:
		_slot_normal = _make_tex_style(tex_normal, 8, 8, 8, 8, 5, 5, 5, 5)
		_slot_hover = _make_tex_style(tex_selected, 8, 8, 8, 8, 5, 5, 5, 5)
		_slot_pressed = _make_tex_style(tex_selected, 8, 8, 8, 8, 5, 5, 5, 5)
		_slot_pressed.modulate_color = Color(0.85, 0.80, 0.70)
		_slot_disabled = _make_tex_style(tex_normal, 8, 8, 8, 8, 5, 5, 5, 5)
		_slot_disabled.modulate_color = Color(0.4, 0.4, 0.4, 0.6)
	else:
		# Fallback flat styles
		_slot_normal = _make_tower_slot_style(
			Color(0.70, 0.55, 0.20), Color(0.12, 0.10, 0.08, 0.9))
		_slot_hover = _make_tower_slot_style(
			Color(1.0, 0.85, 0.30), Color(0.18, 0.15, 0.10, 0.95))
		_slot_pressed = _make_tower_slot_style(
			Color(0.90, 0.70, 0.20), Color(0.08, 0.06, 0.04, 0.95))
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
		btn.pressed.connect(func(): AudioManager.play_sfx("select"))
		btn.mouse_entered.connect(func(): AudioManager.play_sfx("button_hover", -8.0))
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
	AudioManager.play_sfx("menu_open" if esc_menu.visible else "menu_close")

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
