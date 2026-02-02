extends Control

## Lose Screen — shown when lives reach 0

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var retry_btn: Button = $VBoxContainer/ButtonRow/RetryBtn
@onready var menu_btn: Button = $VBoxContainer/ButtonRow/MenuBtn

func _ready():
	retry_btn.pressed.connect(_on_retry_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	
	# Button SFX
	for btn in [retry_btn, menu_btn]:
		btn.pressed.connect(func(): AudioManager.play_sfx("button_click"))
		btn.mouse_entered.connect(func(): AudioManager.play_sfx("button_hover", -8.0))
	
	# Defeat audio — stop battle music, play defeat sound
	AudioManager.stop_music(0.5)
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
