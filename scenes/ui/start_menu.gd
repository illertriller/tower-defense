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
	
	# Animate title fade in
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.8)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.6)

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
