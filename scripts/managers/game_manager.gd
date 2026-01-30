extends Node

## Game Manager - Autoloaded singleton
## Handles game state, money, lives, wave tracking

signal money_changed(new_amount: int)
signal lives_changed(new_amount: int)
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal game_over()
signal game_won()

# Game state
var money: int = 100:
	set(value):
		money = value
		money_changed.emit(money)

var lives: int = 20:
	set(value):
		lives = max(0, value)
		lives_changed.emit(lives)
		if lives <= 0:
			game_over.emit()

var current_wave: int = 0
var is_wave_active: bool = false
var game_active: bool = true

# Tower definitions - cost, damage, range, fire rate
var tower_data: Dictionary = {
	"arrow_tower": {
		"name": "Arrow Tower",
		"cost": 50,
		"damage": 10,
		"range": 150.0,
		"fire_rate": 1.0,  # shots per second
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

func start_wave():
	current_wave += 1
	is_wave_active = true
	wave_started.emit(current_wave)

func complete_wave():
	is_wave_active = false
	wave_completed.emit(current_wave)
	# Bonus money per wave
	money += 25 + (current_wave * 5)

func reset():
	money = 100
	lives = 20
	current_wave = 0
	is_wave_active = false
	game_active = true
