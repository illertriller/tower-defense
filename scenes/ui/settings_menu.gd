extends Control

## Settings Menu — resolution, map size, camera, display options
## Can be opened from start menu or ESC menu

signal closed()

@onready var resolution_option: OptionButton = $Panel/VBox/ResolutionRow/OptionButton
@onready var map_size_option: OptionButton = $Panel/VBox/MapSizeRow/OptionButton
@onready var fullscreen_check: CheckButton = $Panel/VBox/FullscreenRow/CheckButton
@onready var edge_pan_check: CheckButton = $Panel/VBox/EdgePanRow/CheckButton
@onready var minimap_check: CheckButton = $Panel/VBox/MinimapRow/CheckButton
@onready var back_btn: Button = $Panel/VBox/BackBtn

func _ready():
	_style_panel()
	_populate_options()
	_load_current()
	
	resolution_option.item_selected.connect(_on_resolution_changed)
	map_size_option.item_selected.connect(_on_map_size_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	edge_pan_check.toggled.connect(_on_edge_pan_toggled)
	minimap_check.toggled.connect(_on_minimap_toggled)
	back_btn.pressed.connect(_on_back)

func _populate_options():
	resolution_option.clear()
	for res in Settings.RESOLUTIONS:
		resolution_option.add_item(res["label"])
	
	map_size_option.clear()
	for ms in Settings.MAP_SIZES:
		map_size_option.add_item(ms["label"])

func _load_current():
	resolution_option.selected = Settings.resolution_index
	map_size_option.selected = Settings.map_size_index
	fullscreen_check.button_pressed = Settings.fullscreen
	edge_pan_check.button_pressed = Settings.camera_edge_pan
	minimap_check.button_pressed = Settings.show_minimap

func _on_resolution_changed(index: int):
	Settings.set_resolution(index)

func _on_map_size_changed(index: int):
	Settings.set_map_size(index)

func _on_fullscreen_toggled(pressed: bool):
	Settings.set_fullscreen(pressed)

func _on_edge_pan_toggled(pressed: bool):
	Settings.camera_edge_pan = pressed
	Settings.save_settings()

func _on_minimap_toggled(pressed: bool):
	Settings.show_minimap = pressed
	Settings.save_settings()

func _style_panel():
	var panel = $Panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.05, 0.95)
	style.border_color = Color(0.75, 0.60, 0.22)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(20)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", style)
	
	var normal = _make_btn(Color(0.12, 0.09, 0.06, 0.95), Color(0.75, 0.60, 0.22))
	var hover = _make_btn(Color(0.16, 0.12, 0.08, 0.95), Color(1.0, 0.85, 0.32))
	var pressed = _make_btn(Color(0.06, 0.04, 0.02, 0.95), Color(0.75, 0.60, 0.22))
	back_btn.add_theme_stylebox_override("normal", normal)
	back_btn.add_theme_stylebox_override("hover", hover)
	back_btn.add_theme_stylebox_override("pressed", pressed)
	back_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _make_btn(bg: Color, border: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(3)
	s.set_content_margin_all(6)
	return s

func _on_back():
	closed.emit()

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_back()
		get_viewport().set_input_as_handled()
