extends Control

## Lose Screen — shown when lives reach 0
## Plays lose cinematic first, then shows stats

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var retry_btn: Button = $VBoxContainer/ButtonRow/RetryBtn
@onready var menu_btn: Button = $VBoxContainer/ButtonRow/MenuBtn

var cinematic_scene: PackedScene = preload("res://scenes/ui/cinematic_player.tscn")
var _cinematic_instance: Control = null

func _ready():
	retry_btn.pressed.connect(_on_retry_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	
	# Button SFX
	for btn in [retry_btn, menu_btn]:
		btn.pressed.connect(func(): AudioManager.play_sfx("button_click"))
		btn.mouse_entered.connect(func(): AudioManager.play_sfx("button_hover", -8.0))
	
	# Stop battle music
	AudioManager.stop_music(0.5)
	
	# Hide UI elements and play lose cinematic first
	$VBoxContainer.visible = false
	$Background.visible = false
	_play_lose_cinematic()

func _play_lose_cinematic():
	_cinematic_instance = cinematic_scene.instantiate()
	add_child(_cinematic_instance)
	_cinematic_instance.cinematic_finished.connect(_on_cinematic_finished)
	
	var lose_stream = load("res://assets/cinematic/lose_cinematic.ogv")
	_cinematic_instance.play_cinematic(lose_stream)

func _on_cinematic_finished():
	if _cinematic_instance:
		_cinematic_instance.queue_free()
		_cinematic_instance = null
	
	# Now show the stats screen
	$VBoxContainer.visible = true
	$Background.visible = true
	
	# Defeat audio
	AudioManager.play_sfx("defeat")
	
	_show_stats()
	
	# Fade in
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _show_stats():
	var score = GameManager.get_score()
	var level_name = LevelData.get_level_name(score["level"])
	
	title_label.text = "DEFEAT"
	
	stats_label.text = """Level %d — %s

Waves Survived: %d / 10
Enemies Killed: %d
Gold Earned: %d

The demons have overrun your defenses...""" % [
		score["level"], level_name,
		GameManager.current_wave,
		score["enemies_killed"],
		score["gold_earned"]
	]

func _on_retry_pressed():
	GameManager.start_level(GameManager.current_level)
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
