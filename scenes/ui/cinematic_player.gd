extends Control

## Cinematic Player — Plays video cinematics with skip support
## Used for intro, win, and lose cinematics

signal cinematic_finished

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var skip_label: Label = $SkipLabel

var _next_scene: String = ""
var _on_finished_callback: Callable

func _ready():
	video_player.finished.connect(_on_video_finished)
	
	# Fade in the skip hint after a short delay
	skip_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(skip_label, "modulate:a", 0.6, 0.5)

func _input(event):
	# Skip on any key press, mouse click, or screen tap
	if event is InputEventKey and event.pressed:
		_skip()
	elif event is InputEventMouseButton and event.pressed:
		_skip()

func play_cinematic(stream: VideoStream, next_scene: String = ""):
	_next_scene = next_scene
	video_player.stream = stream
	video_player.play()

func _skip():
	video_player.stop()
	_on_video_finished()

func _on_video_finished():
	cinematic_finished.emit()
	if _next_scene != "":
		get_tree().change_scene_to_file(_next_scene)
