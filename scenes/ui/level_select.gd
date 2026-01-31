extends Control

## Level Select — Choose which level to play

@onready var grid: GridContainer = $VBoxContainer/LevelGrid
@onready var back_btn: Button = $VBoxContainer/BackBtn

func _ready():
	back_btn.pressed.connect(_on_back_pressed)
	# Load saved progress
	GameManager.max_level_unlocked = max(GameManager.max_level_unlocked, SaveManager.load_progress())
	_create_level_buttons()

func _create_level_buttons():
	for level in range(1, 6):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(200, 80)
		var level_name = LevelData.get_level_name(level)
		btn.text = "Level %d\n%s" % [level, level_name]
		
		if level > GameManager.max_level_unlocked:
			btn.disabled = true
			btn.text += "\n🔒"
		else:
			var best = SaveManager.get_highscore(level)
			if best.has("score"):
				btn.text += "\n★ %d" % best["score"]
		
		btn.pressed.connect(_on_level_pressed.bind(level))
		grid.add_child(btn)

func _on_level_pressed(level: int):
	GameManager.start_level(level)
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
