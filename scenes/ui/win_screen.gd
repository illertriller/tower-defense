extends Control

## Win Screen — shown when all waves are cleared
## Plays win cinematic first, then shows score

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var next_btn: Button = $VBoxContainer/ButtonRow/NextLevelBtn
@onready var menu_btn: Button = $VBoxContainer/ButtonRow/MenuBtn

var cinematic_scene: PackedScene = preload("res://scenes/ui/cinematic_player.tscn")
var _cinematic_instance: Control = null

func _ready():
	next_btn.pressed.connect(_on_next_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	
	# Button SFX
	for btn in [next_btn, menu_btn]:
		btn.pressed.connect(func(): AudioManager.play_sfx("button_click"))
		btn.mouse_entered.connect(func(): AudioManager.play_sfx("button_hover", -8.0))
	
	# Stop battle music
	AudioManager.stop_music(0.5)
	
	# Hide UI elements and play win cinematic first
	$VBoxContainer.visible = false
	$Background.visible = false
	_play_win_cinematic()

func _play_win_cinematic():
	_cinematic_instance = cinematic_scene.instantiate()
	add_child(_cinematic_instance)
	_cinematic_instance.cinematic_finished.connect(_on_cinematic_finished)
	
	var win_stream = load("res://assets/cinematic/win_cinematic.ogv")
	_cinematic_instance.play_cinematic(win_stream)

func _on_cinematic_finished():
	if _cinematic_instance:
		_cinematic_instance.queue_free()
		_cinematic_instance = null
	
	# Now show the score screen
	$VBoxContainer.visible = true
	$Background.visible = true
	
	# Victory audio — play fanfare then victory theme
	AudioManager.play_sfx("victory_fanfare")
	get_tree().create_timer(1.5).timeout.connect(func(): AudioManager.play_music("victory_theme", 0.5))
	
	_show_score()
	
	# Fade in
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _show_score():
	var score = GameManager.get_score()
	var level_name = LevelData.get_level_name(score["level"])
	
	title_label.text = "VICTORY!"
	
	var time_str = "%d:%02d" % [int(score["time_seconds"]) / 60, int(score["time_seconds"]) % 60]
	var best = SaveManager.get_highscore(score["level"])
	var best_str = ""
	if best.has("score"):
		best_str = "\n★ Best: %d" % best["score"]
		if score["score"] >= best.get("score", 0):
			best_str = "\n★ NEW HIGH SCORE! ★"
	
	stats_label.text = """Level %d — %s

Lives Remaining: %d
Enemies Killed: %d
Gold Earned: %d
Time: %s

SCORE: %d%s""" % [
		score["level"], level_name,
		score["lives_remaining"],
		score["enemies_killed"],
		score["gold_earned"],
		time_str,
		score["score"],
		best_str
	]
	
	# Show credits button if this was the last level
	if score["level"] >= 5:
		next_btn.text = "Watch Credits"
		next_btn.pressed.disconnect(_on_next_pressed)
		next_btn.pressed.connect(_on_credits)

func _on_next_pressed():
	var next_level = GameManager.current_level + 1
	if next_level <= 5:
		GameManager.start_level(next_level)
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_credits():
	get_tree().change_scene_to_file("res://scenes/ui/credits.tscn")

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
