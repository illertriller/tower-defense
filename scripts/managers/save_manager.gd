extends Node
class_name SaveManager

## Handles saving and loading highscores and game progress

const SAVE_PATH = "user://save_data.json"

static func save_highscore(level: int, score_data: Dictionary):
	var data = _load_all()
	var key = "level_%d" % level
	
	if not data.has("highscores"):
		data["highscores"] = {}
	
	var existing = data["highscores"].get(key, {})
	var new_score = score_data.get("score", 0)
	
	# Only save if it's a new high score
	if new_score > existing.get("score", 0):
		data["highscores"][key] = {
			"score": new_score,
			"lives": score_data.get("lives_remaining", 0),
			"kills": score_data.get("enemies_killed", 0),
			"gold": score_data.get("gold_earned", 0),
			"time": score_data.get("time_seconds", 0),
			"date": Time.get_datetime_string_from_system(),
		}
	
	_save_all(data)

static func get_highscore(level: int) -> Dictionary:
	var data = _load_all()
	var key = "level_%d" % level
	return data.get("highscores", {}).get(key, {})

static func get_all_highscores() -> Dictionary:
	var data = _load_all()
	return data.get("highscores", {})

static func save_progress(max_level: int):
	var data = _load_all()
	data["max_level_unlocked"] = max(data.get("max_level_unlocked", 1), max_level)
	_save_all(data)

static func load_progress() -> int:
	var data = _load_all()
	return data.get("max_level_unlocked", 1)

static func _load_all() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return {}
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(text) == OK:
		return json.data
	return {}

static func _save_all(data: Dictionary):
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
