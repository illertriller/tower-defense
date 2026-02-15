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
	# Fit video to screen maintaining aspect ratio (letterbox/pillarbox)
	_fit_video_to_screen()

func _fit_video_to_screen():
	# Wait one frame for the video to start and report its size
	await get_tree().process_frame
	var video_w = video_player.get_video_texture().get_width() if video_player.get_video_texture() else 848
	var video_h = video_player.get_video_texture().get_height() if video_player.get_video_texture() else 480
	var screen_size = get_viewport_rect().size
	var video_aspect = float(video_w) / float(video_h)
	var screen_aspect = screen_size.x / screen_size.y
	
	var target_w: float
	var target_h: float
	if video_aspect > screen_aspect:
		# Video is wider — fit to width, letterbox top/bottom
		target_w = screen_size.x
		target_h = screen_size.x / video_aspect
	else:
		# Video is taller — fit to height, pillarbox left/right
		target_h = screen_size.y
		target_w = screen_size.y * video_aspect
	
	video_player.offset_left = -target_w / 2.0
	video_player.offset_right = target_w / 2.0
	video_player.offset_top = -target_h / 2.0
	video_player.offset_bottom = target_h / 2.0

func _skip():
	video_player.stop()
	_on_video_finished()

func _on_video_finished():
	cinematic_finished.emit()
	if _next_scene != "":
		get_tree().change_scene_to_file(_next_scene)
