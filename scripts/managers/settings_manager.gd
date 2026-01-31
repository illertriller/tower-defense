extends Node
class_name SettingsManager

## Settings Manager — handles resolution, map size, camera prefs
## Autoloaded singleton

signal resolution_changed(width: int, height: int)
signal settings_changed()

# Resolution presets (viewport size)
const RESOLUTIONS: Array = [
	{"label": "1280×720 (HD)", "width": 1280, "height": 720},
	{"label": "1600×900 (HD+)", "width": 1600, "height": 900},
	{"label": "1920×1080 (Full HD)", "width": 1920, "height": 1080},
	{"label": "2560×1440 (QHD)", "width": 2560, "height": 1440},
]

# Map size presets (game world size in pixels)
const MAP_SIZES: Array = [
	{"label": "Standard (2560×1440)", "width": 2560, "height": 1440},
	{"label": "Large (3840×2160)", "width": 3840, "height": 2160},
	{"label": "Massive (5120×2880)", "width": 5120, "height": 2880},
]

const SAVE_PATH = "user://settings.json"

# Current settings
var resolution_index: int = 2  # Default: 1920x1080
var map_size_index: int = 0    # Default: Standard
var fullscreen: bool = false
var camera_edge_pan: bool = true
var camera_edge_speed: float = 600.0
var camera_keyboard_speed: float = 800.0
var camera_edge_margin: int = 30  # pixels from screen edge to start panning
var show_minimap: bool = true

# Computed properties
var viewport_width: int:
	get: return RESOLUTIONS[resolution_index]["width"]

var viewport_height: int:
	get: return RESOLUTIONS[resolution_index]["height"]

var map_width: int:
	get: return MAP_SIZES[map_size_index]["width"]

var map_height: int:
	get: return MAP_SIZES[map_size_index]["height"]

var map_grid_width: int:
	get: return map_width / 32

var map_grid_height: int:
	get: return map_height / 32

func _ready():
	load_settings()

func apply_resolution():
	var w = viewport_width
	var h = viewport_height
	
	# Update project viewport
	get_tree().root.content_scale_size = Vector2i(w, h)
	
	# Update window size (windowed mode)
	if not fullscreen:
		DisplayServer.window_set_size(Vector2i(w, h))
		# Center window
		var screen_size = DisplayServer.screen_get_size()
		var win_pos = (screen_size - Vector2i(w, h)) / 2
		DisplayServer.window_set_position(win_pos)
	
	# Fullscreen toggle
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	resolution_changed.emit(w, h)
	settings_changed.emit()

func set_resolution(index: int):
	resolution_index = clampi(index, 0, RESOLUTIONS.size() - 1)
	apply_resolution()
	save_settings()

func set_map_size(index: int):
	map_size_index = clampi(index, 0, MAP_SIZES.size() - 1)
	save_settings()
	settings_changed.emit()

func set_fullscreen(enabled: bool):
	fullscreen = enabled
	apply_resolution()
	save_settings()

func save_settings():
	var data = {
		"resolution_index": resolution_index,
		"map_size_index": map_size_index,
		"fullscreen": fullscreen,
		"camera_edge_pan": camera_edge_pan,
		"camera_edge_speed": camera_edge_speed,
		"camera_keyboard_speed": camera_keyboard_speed,
		"show_minimap": show_minimap,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_settings():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(text) != OK:
		return
	var data: Dictionary = json.data
	
	resolution_index = clampi(data.get("resolution_index", 2), 0, RESOLUTIONS.size() - 1)
	map_size_index = clampi(data.get("map_size_index", 0), 0, MAP_SIZES.size() - 1)
	fullscreen = data.get("fullscreen", false)
	camera_edge_pan = data.get("camera_edge_pan", true)
	camera_edge_speed = data.get("camera_edge_speed", 600.0)
	camera_keyboard_speed = data.get("camera_keyboard_speed", 800.0)
	show_minimap = data.get("show_minimap", true)
