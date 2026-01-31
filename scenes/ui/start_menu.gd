extends Control

## Start Menu — Main menu screen

@onready var start_btn: Button = $VBoxContainer/StartBtn
@onready var settings_btn: Button = $VBoxContainer/SettingsBtn
@onready var exit_btn: Button = $VBoxContainer/ExitBtn
@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel

var settings_scene: PackedScene = preload("res://scenes/ui/settings_menu.tscn")
var _settings_instance: Control = null

func _ready():
	start_btn.pressed.connect(_on_start_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	settings_btn.disabled = false  # Settings now works!
	_style_menu_buttons()
	
	# Animate title fade in
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.8)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.6)

func _style_menu_buttons():
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.09, 0.06, 0.9)
	normal.border_color = Color(0.75, 0.60, 0.22)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(8)
	
	var hover = normal.duplicate()
	hover.border_color = Color(1.0, 0.85, 0.32)
	hover.bg_color = Color(0.18, 0.14, 0.08, 0.95)
	
	var pressed = normal.duplicate()
	pressed.bg_color = Color(0.06, 0.04, 0.02, 0.95)
	
	var disabled = normal.duplicate()
	disabled.border_color = Color(0.35, 0.30, 0.15, 0.5)
	disabled.bg_color = Color(0.08, 0.07, 0.06, 0.7)
	
	for btn in [start_btn, settings_btn, exit_btn]:
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_stylebox_override("disabled", disabled)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

func _on_settings_pressed():
	if _settings_instance:
		return
	_settings_instance = settings_scene.instantiate()
	_settings_instance.closed.connect(_on_settings_closed)
	add_child(_settings_instance)

func _on_settings_closed():
	if _settings_instance:
		_settings_instance.queue_free()
		_settings_instance = null

func _on_exit_pressed():
	get_tree().quit()
