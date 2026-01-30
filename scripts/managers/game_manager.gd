extends Node

## Game Manager - Autoloaded singleton
## Handles game state, money, lives, wave tracking, level progression, scoring

signal money_changed(new_amount: int)
signal lives_changed(new_amount: int)
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal game_over()
signal game_won()
signal level_complete(level: int)

# Game state
var money: int = 100:
	set(value):
		money = value
		money_changed.emit(money)

var lives: int = 20:
	set(value):
		lives = max(0, value)
		lives_changed.emit(lives)
		if lives <= 0 and game_active:
			game_active = false
			game_over.emit()

var current_wave: int = 0
var total_waves: int = 10
var is_wave_active: bool = false
var game_active: bool = true

# Level tracking
var current_level: int = 1
var max_level_unlocked: int = 1

# Scoring
var enemies_killed: int = 0
var total_gold_earned: int = 0
var level_start_time: float = 0.0
var level_elapsed_time: float = 0.0

# Tower definitions - cost, damage, range, fire rate
var tower_data: Dictionary = {
	"arrow_tower": {
		"name": "Arrow Tower",
		"cost": 50,
		"damage": 10,
		"range": 150.0,
		"fire_rate": 1.0,
		"projectile_speed": 300.0,
		"description": "Basic tower. Fires arrows at enemies."
	},
	"cannon_tower": {
		"name": "Cannon Tower",
		"cost": 100,
		"damage": 30,
		"range": 120.0,
		"fire_rate": 0.5,
		"projectile_speed": 200.0,
		"description": "Slow but powerful. Deals splash damage."
	},
	"magic_tower": {
		"name": "Magic Tower",
		"cost": 75,
		"damage": 15,
		"range": 180.0,
		"fire_rate": 0.8,
		"projectile_speed": 250.0,
		"description": "Long range. Slows enemies."
	},
	"tesla_tower": {
		"name": "Tesla Tower",
		"cost": 125,
		"damage": 5,
		"range": 140.0,
		"fire_rate": 4.0,
		"projectile_speed": 0.0,
		"description": "Electric zap. Hits up to 3 enemies at once."
	}
}

func can_afford(tower_type: String) -> bool:
	return money >= tower_data[tower_type]["cost"]

func buy_tower(tower_type: String) -> bool:
	if can_afford(tower_type):
		money -= tower_data[tower_type]["cost"]
		return true
	return false

func enemy_reached_end():
	lives -= 1

func enemy_killed(reward: int):
	money += reward
	enemies_killed += 1
	total_gold_earned += reward

func start_wave():
	current_wave += 1
	is_wave_active = true
	wave_started.emit(current_wave)

func complete_wave():
	is_wave_active = false
	wave_completed.emit(current_wave)
	# Bonus money per wave
	var bonus = 25 + (current_wave * 5)
	money += bonus
	total_gold_earned += bonus
	
	# Check if all waves completed
	if current_wave >= total_waves:
		_on_level_complete()

func _on_level_complete():
	level_elapsed_time = (Time.get_ticks_msec() / 1000.0) - level_start_time
	if current_level >= max_level_unlocked:
		max_level_unlocked = min(current_level + 1, 5)
	game_active = false
	level_complete.emit(current_level)

func start_level(level: int):
	current_level = level
	reset_level()

func reset_level():
	money = 100 + (current_level - 1) * 25  # Slightly more gold for harder levels
	lives = 20
	current_wave = 0
	total_waves = 10
	is_wave_active = false
	game_active = true
	enemies_killed = 0
	total_gold_earned = 0
	level_start_time = Time.get_ticks_msec() / 1000.0
	level_elapsed_time = 0.0

func get_score() -> Dictionary:
	if level_elapsed_time <= 0:
		level_elapsed_time = (Time.get_ticks_msec() / 1000.0) - level_start_time
	return {
		"level": current_level,
		"lives_remaining": lives,
		"enemies_killed": enemies_killed,
		"gold_earned": total_gold_earned,
		"time_seconds": level_elapsed_time,
		"score": _calculate_score()
	}

func _calculate_score() -> int:
	# Score formula: lives * 100 + kills * 10 + time bonus
	var time_bonus = max(0, 300 - int(level_elapsed_time))  # Faster = more points
	return (lives * 100) + (enemies_killed * 10) + time_bonus

func reset():
	money = 100
	lives = 20
	current_wave = 0
	is_wave_active = false
	game_active = true
	enemies_killed = 0
	total_gold_earned = 0
