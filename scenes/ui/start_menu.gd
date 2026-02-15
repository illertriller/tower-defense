extends Control

## Start Menu — Main menu screen

@onready var start_btn: Button = $VBoxContainer/StartBtn
@onready var settings_btn: Button = $VBoxContainer/SettingsBtn
@onready var exit_btn: Button = $VBoxContainer/ExitBtn
@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel

var settings_scene: PackedScene = preload("res://scenes/ui/settings_menu.tscn")
var cinematic_scene: PackedScene = preload("res://scenes/ui/cinematic_player.tscn")
var _settings_instance: Control = null
var _cinematic_instance: Control = null

# Track if intro has played this session (only play once)
static var _intro_played: bool = false

func _ready():
	start_btn.pressed.connect(_on_start_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	settings_btn.disabled = false
	_style_menu_buttons()
	
	# Play intro cinematic on first launch
	if not _intro_played:
		_intro_played = true
		_play_intro_cinematic()
		return  # Don't start music yet — cinematic has its own audio
	
	# Audio: menu music + button sounds
	_setup_audio()

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
	
	for btn in [start_btn, settings_btn, exit_btn]:
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _setup_audio():
	AudioManager.play_music("menu_theme")
	for btn in [start_btn, settings_btn, exit_btn]:
		btn.pressed.connect(func(): AudioManager.play_sfx("button_click"))
		btn.mouse_entered.connect(func(): AudioManager.play_sfx("button_hover", -8.0))
	
	# Animate title fade in
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.8)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.6)

func _play_intro_cinematic():
	# Hide menu elements during cinematic
	$VBoxContainer.visible = false
	$TitleLabel.visible = false
	$SubtitleLabel.visible = false
	$VersionLabel.visible = false
	$Embers.visible = false
	
	_cinematic_instance = cinematic_scene.instantiate()
	add_child(_cinematic_instance)
	_cinematic_instance.cinematic_finished.connect(_on_intro_finished)
	
	var intro_stream = load("res://assets/cinematic/intro_cinematic.ogv")
	_cinematic_instance.play_cinematic(intro_stream)

func _on_intro_finished():
	if _cinematic_instance:
		_cinematic_instance.queue_free()
		_cinematic_instance = null
	
	# Show menu elements
	$VBoxContainer.visible = true
	$TitleLabel.visible = true
	$SubtitleLabel.visible = true
	$VersionLabel.visible = true
	$Embers.visible = true
	
	# Now start the menu music and animations
	_setup_audio()

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
