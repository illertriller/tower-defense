extends Control

## Settings Menu — resolution, map size, camera, display, audio options
## Can be opened from start menu or ESC menu

signal closed()

@onready var resolution_option: OptionButton = $Panel/VBox/ResolutionRow/OptionButton
@onready var map_size_option: OptionButton = $Panel/VBox/MapSizeRow/OptionButton
@onready var fullscreen_check: CheckButton = $Panel/VBox/FullscreenRow/CheckButton
@onready var edge_pan_check: CheckButton = $Panel/VBox/EdgePanRow/CheckButton
@onready var minimap_check: CheckButton = $Panel/VBox/MinimapRow/CheckButton

# Audio controls
@onready var master_slider: HSlider = $Panel/VBox/MasterVolRow/HSlider
@onready var master_label: Label = $Panel/VBox/MasterVolRow/ValueLabel
@onready var music_slider: HSlider = $Panel/VBox/MusicVolRow/HSlider
@onready var music_label: Label = $Panel/VBox/MusicVolRow/ValueLabel
@onready var sfx_slider: HSlider = $Panel/VBox/SFXVolRow/HSlider
@onready var sfx_label: Label = $Panel/VBox/SFXVolRow/ValueLabel
@onready var mute_check: CheckButton = $Panel/VBox/MuteRow/CheckButton

@onready var back_btn: Button = $Panel/VBox/BackBtn

func _ready():
	_style_panel()
	_populate_options()
	_load_current()
	_load_audio_settings()
	
	resolution_option.item_selected.connect(_on_resolution_changed)
	map_size_option.item_selected.connect(_on_map_size_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	edge_pan_check.toggled.connect(_on_edge_pan_toggled)
	minimap_check.toggled.connect(_on_minimap_toggled)
	
	# Audio connections
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	mute_check.toggled.connect(_on_mute_toggled)
	
	back_btn.pressed.connect(_on_back)
	
	# Button SFX
	back_btn.pressed.connect(func(): AudioManager.play_sfx("button_click"))
	back_btn.mouse_entered.connect(func(): AudioManager.play_sfx("button_hover", -8.0))

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

func _load_audio_settings():
	# Load current values from AudioManager
	master_slider.value = AudioManager.master_volume * 100.0
	music_slider.value = AudioManager.music_volume * 100.0
	sfx_slider.value = AudioManager.sfx_volume * 100.0
	master_label.text = "%d%%" % int(master_slider.value)
	music_label.text = "%d%%" % int(music_slider.value)
	sfx_label.text = "%d%%" % int(sfx_slider.value)
	mute_check.button_pressed = AudioServer.is_bus_mute(0)

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

# ── Audio callbacks ──

func _on_master_volume_changed(value: float):
	AudioManager.set_master_volume(value / 100.0)
	master_label.text = "%d%%" % int(value)

func _on_music_volume_changed(value: float):
	AudioManager.set_music_volume(value / 100.0)
	music_label.text = "%d%%" % int(value)

func _on_sfx_volume_changed(value: float):
	AudioManager.set_sfx_volume(value / 100.0)
	sfx_label.text = "%d%%" % int(value)
	# Play a sample click so the player hears the new level
	AudioManager.play_sfx("button_click")

func _on_mute_toggled(pressed: bool):
	AudioServer.set_bus_mute(0, pressed)

# ── Styling ──

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
	var btn_pressed = _make_btn(Color(0.06, 0.04, 0.02, 0.95), Color(0.75, 0.60, 0.22))
	back_btn.add_theme_stylebox_override("normal", normal)
	back_btn.add_theme_stylebox_override("hover", hover)
	back_btn.add_theme_stylebox_override("pressed", btn_pressed)
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
	AudioManager.play_sfx("button_click")
	closed.emit()

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_back()
		get_viewport().set_input_as_handled()
