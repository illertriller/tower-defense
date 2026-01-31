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
signal tower_upgraded(tower: Node2D)

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

# Attack types
enum AttackType { PROJECTILE, BEAM, AOE, SPAWN, PASSIVE }

# Tower definitions
# attack_type: how the tower deals damage
# specials: array of special effect strings
# targets_air: whether it can hit flying enemies
# targets_ground: whether it can hit ground enemies
var tower_data: Dictionary = {
	# === EXISTING TOWERS ===
	"arrow_tower": {
		"name": "Arrow Tower",
		"cost": 50,
		"damage": 10,
		"range": 150.0,
		"fire_rate": 1.0,
		"projectile_speed": 300.0,
		"attack_type": AttackType.PROJECTILE,
		"specials": [],
		"targets_air": true,
		"targets_ground": true,
		"description": "Basic tower. Fires arrows at enemies.",
		"projectile_type": "arrow",
	},
	"cannon_tower": {
		"name": "Cannon Tower",
		"cost": 100,
		"damage": 30,
		"range": 120.0,
		"fire_rate": 0.5,
		"projectile_speed": 200.0,
		"attack_type": AttackType.PROJECTILE,
		"specials": ["splash"],
		"splash_radius": 50.0,
		"targets_air": false,
		"targets_ground": true,
		"description": "Slow but powerful. Deals splash damage.",
		"projectile_type": "cannon",
	},
	"magic_tower": {
		"name": "Magic Tower",
		"cost": 75,
		"damage": 15,
		"range": 180.0,
		"fire_rate": 0.8,
		"projectile_speed": 250.0,
		"attack_type": AttackType.PROJECTILE,
		"specials": ["slow"],
		"slow_amount": 0.5,
		"slow_duration": 1.5,
		"targets_air": true,
		"targets_ground": true,
		"description": "Long range magic. Slows enemies.",
		"projectile_type": "magic",
	},
	"tesla_tower": {
		"name": "Tesla Tower",
		"cost": 125,
		"damage": 5,
		"range": 140.0,
		"fire_rate": 4.0,
		"projectile_speed": 0.0,
		"attack_type": AttackType.BEAM,
		"specials": ["chain"],
		"max_targets": 3,
		"targets_air": true,
		"targets_ground": true,
		"description": "Electric zap. Hits up to 3 enemies.",
		"projectile_type": "",
	},
	# === NEW TOWERS ===
	"frost_tower": {
		"name": "Frost Tower",
		"cost": 100,
		"damage": 5,
		"range": 130.0,
		"fire_rate": 0.8,
		"projectile_speed": 200.0,
		"attack_type": AttackType.PROJECTILE,
		"specials": ["slow"],
		"slow_amount": 0.3,
		"slow_duration": 3.0,
		"targets_air": true,
		"targets_ground": true,
		"description": "Low damage but heavy slow. Freezes enemies.",
		"projectile_type": "frost",
	},
	"flame_tower": {
		"name": "Flame Tower",
		"cost": 125,
		"damage": 8,
		"range": 100.0,
		"fire_rate": 3.0,
		"projectile_speed": 0.0,
		"attack_type": AttackType.AOE,
		"specials": ["burn"],
		"burn_damage": 3,
		"burn_duration": 2.0,
		"targets_air": false,
		"targets_ground": true,
		"description": "Burns all nearby enemies. AoE fire damage.",
		"projectile_type": "",
	},
	"antiair_tower": {
		"name": "Anti-Air Tower",
		"cost": 75,
		"damage": 25,
		"range": 200.0,
		"fire_rate": 0.7,
		"projectile_speed": 400.0,
		"attack_type": AttackType.PROJECTILE,
		"specials": ["air_bonus"],
		"air_damage_mult": 2.0,
		"targets_air": true,
		"targets_ground": true,
		"description": "Long range. Double damage to flying enemies.",
		"projectile_type": "arrow",
	},
	"sniper_tower": {
		"name": "Sniper Tower",
		"cost": 150,
		"damage": 80,
		"range": 300.0,
		"fire_rate": 0.3,
		"projectile_speed": 600.0,
		"attack_type": AttackType.PROJECTILE,
		"specials": [],
		"targets_air": true,
		"targets_ground": true,
		"description": "Extreme range, high damage, very slow fire rate.",
		"projectile_type": "arrow",
	},
	"poison_tower": {
		"name": "Poison Tower",
		"cost": 100,
		"damage": 5,
		"range": 140.0,
		"fire_rate": 0.6,
		"projectile_speed": 180.0,
		"attack_type": AttackType.PROJECTILE,
		"specials": ["poison"],
		"poison_damage": 4,
		"poison_duration": 4.0,
		"targets_air": false,
		"targets_ground": true,
		"description": "Applies deadly poison. Damage over time.",
		"projectile_type": "poison",
	},
	"bomb_tower": {
		"name": "Bomb Tower",
		"cost": 150,
		"damage": 50,
		"range": 110.0,
		"fire_rate": 0.35,
		"projectile_speed": 150.0,
		"attack_type": AttackType.PROJECTILE,
		"specials": ["splash"],
		"splash_radius": 80.0,
		"targets_air": false,
		"targets_ground": true,
		"description": "Massive splash damage. Slow but devastating.",
		"projectile_type": "cannon",
	},
	"holy_tower": {
		"name": "Holy Tower",
		"cost": 125,
		"damage": 20,
		"range": 160.0,
		"fire_rate": 0.7,
		"projectile_speed": 350.0,
		"attack_type": AttackType.PROJECTILE,
		"specials": ["holy"],
		"holy_bonus_types": ["demon_lord", "hell_knight", "succubus", "wraith"],
		"holy_damage_mult": 2.5,
		"targets_air": true,
		"targets_ground": true,
		"description": "Divine damage. Extra effective vs elite demons.",
		"projectile_type": "holy",
	},
	"barracks_tower": {
		"name": "Barracks",
		"cost": 100,
		"damage": 0,
		"range": 0.0,
		"fire_rate": 0.0,
		"projectile_speed": 0.0,
		"attack_type": AttackType.SPAWN,
		"specials": ["spawn_soldiers"],
		"soldier_count": 2,
		"soldier_hp": 50,
		"soldier_damage": 8,
		"soldier_respawn": 15.0,
		"targets_air": false,
		"targets_ground": true,
		"description": "Spawns soldiers that block and fight enemies.",
		"projectile_type": "",
	},
	"gold_mine": {
		"name": "Gold Mine",
		"cost": 200,
		"damage": 0,
		"range": 0.0,
		"fire_rate": 0.0,
		"projectile_speed": 0.0,
		"attack_type": AttackType.PASSIVE,
		"specials": ["generate_gold"],
		"gold_per_wave": 30,
		"targets_air": false,
		"targets_ground": false,
		"description": "Generates 30 gold per wave. Investment tower.",
		"projectile_type": "",
	},
	"storm_tower": {
		"name": "Storm Tower",
		"cost": 200,
		"damage": 12,
		"range": 160.0,
		"fire_rate": 3.5,
		"projectile_speed": 0.0,
		"attack_type": AttackType.BEAM,
		"specials": ["chain"],
		"max_targets": 5,
		"targets_air": true,
		"targets_ground": true,
		"description": "Upgraded Tesla. Chain lightning hits 5 targets.",
		"projectile_type": "",
	},
}

# Upgrade definitions per tower type
# Each tower has 3 upgrade paths, each with 3 levels
# Format: { path_name: [level1, level2, level3] }
# Each level: { cost, stat_changes: {stat: new_value}, description }
var upgrade_data: Dictionary = {
	"arrow_tower": {
		"path_a": {"name": "Sharp Tips", "upgrades": [
			{"cost": 30, "changes": {"damage": 15}, "desc": "+5 damage"},
			{"cost": 60, "changes": {"damage": 22}, "desc": "+7 damage"},
			{"cost": 100, "changes": {"damage": 35}, "desc": "+13 damage"},
		]},
		"path_b": {"name": "Quick Draw", "upgrades": [
			{"cost": 25, "changes": {"fire_rate": 1.3}, "desc": "+30% fire rate"},
			{"cost": 50, "changes": {"fire_rate": 1.7}, "desc": "+30% fire rate"},
			{"cost": 90, "changes": {"fire_rate": 2.2}, "desc": "+30% fire rate"},
		]},
		"path_c": {"name": "Eagle Eye", "upgrades": [
			{"cost": 25, "changes": {"range": 180.0}, "desc": "+20% range"},
			{"cost": 50, "changes": {"range": 220.0}, "desc": "+22% range"},
			{"cost": 80, "changes": {"range": 270.0}, "desc": "+23% range"},
		]},
	},
	"cannon_tower": {
		"path_a": {"name": "Heavy Shells", "upgrades": [
			{"cost": 50, "changes": {"damage": 45}, "desc": "+15 damage"},
			{"cost": 100, "changes": {"damage": 65}, "desc": "+20 damage"},
			{"cost": 175, "changes": {"damage": 100}, "desc": "+35 damage"},
		]},
		"path_b": {"name": "Wide Blast", "upgrades": [
			{"cost": 40, "changes": {"splash_radius": 65.0}, "desc": "+30% splash"},
			{"cost": 80, "changes": {"splash_radius": 85.0}, "desc": "+30% splash"},
			{"cost": 140, "changes": {"splash_radius": 110.0}, "desc": "+30% splash"},
		]},
		"path_c": {"name": "Rapid Fire", "upgrades": [
			{"cost": 40, "changes": {"fire_rate": 0.65}, "desc": "+30% fire rate"},
			{"cost": 75, "changes": {"fire_rate": 0.85}, "desc": "+30% fire rate"},
			{"cost": 120, "changes": {"fire_rate": 1.1}, "desc": "+30% fire rate"},
		]},
	},
	"magic_tower": {
		"path_a": {"name": "Arcane Power", "upgrades": [
			{"cost": 40, "changes": {"damage": 22}, "desc": "+7 damage"},
			{"cost": 75, "changes": {"damage": 32}, "desc": "+10 damage"},
			{"cost": 130, "changes": {"damage": 50}, "desc": "+18 damage"},
		]},
		"path_b": {"name": "Deep Freeze", "upgrades": [
			{"cost": 35, "changes": {"slow_amount": 0.35}, "desc": "Stronger slow"},
			{"cost": 65, "changes": {"slow_amount": 0.2}, "desc": "Stronger slow"},
			{"cost": 110, "changes": {"slow_amount": 0.1, "slow_duration": 2.5}, "desc": "Near freeze"},
		]},
		"path_c": {"name": "Far Sight", "upgrades": [
			{"cost": 30, "changes": {"range": 210.0}, "desc": "+17% range"},
			{"cost": 55, "changes": {"range": 250.0}, "desc": "+19% range"},
			{"cost": 90, "changes": {"range": 300.0}, "desc": "+20% range"},
		]},
	},
	"tesla_tower": {
		"path_a": {"name": "Voltage", "upgrades": [
			{"cost": 50, "changes": {"damage": 8}, "desc": "+3 damage"},
			{"cost": 90, "changes": {"damage": 13}, "desc": "+5 damage"},
			{"cost": 150, "changes": {"damage": 20}, "desc": "+7 damage"},
		]},
		"path_b": {"name": "Chain Link", "upgrades": [
			{"cost": 60, "changes": {"max_targets": 4}, "desc": "+1 target"},
			{"cost": 110, "changes": {"max_targets": 5}, "desc": "+1 target"},
			{"cost": 175, "changes": {"max_targets": 7}, "desc": "+2 targets"},
		]},
		"path_c": {"name": "Overcharge", "upgrades": [
			{"cost": 45, "changes": {"fire_rate": 5.0}, "desc": "+25% zap rate"},
			{"cost": 80, "changes": {"fire_rate": 6.5}, "desc": "+30% zap rate"},
			{"cost": 130, "changes": {"fire_rate": 8.0}, "desc": "+23% zap rate"},
		]},
	},
	# New towers get simpler upgrades for now
	"frost_tower": {
		"path_a": {"name": "Ice Shards", "upgrades": [
			{"cost": 40, "changes": {"damage": 8}, "desc": "+3 damage"},
			{"cost": 75, "changes": {"damage": 14}, "desc": "+6 damage"},
			{"cost": 120, "changes": {"damage": 22}, "desc": "+8 damage"},
		]},
		"path_b": {"name": "Permafrost", "upgrades": [
			{"cost": 45, "changes": {"slow_amount": 0.2}, "desc": "Heavier slow"},
			{"cost": 85, "changes": {"slow_amount": 0.1, "slow_duration": 4.0}, "desc": "Near freeze"},
			{"cost": 140, "changes": {"slow_amount": 0.05, "slow_duration": 5.0}, "desc": "Deep freeze"},
		]},
		"path_c": {"name": "Cold Snap", "upgrades": [
			{"cost": 35, "changes": {"fire_rate": 1.1}, "desc": "+38% fire rate"},
			{"cost": 65, "changes": {"fire_rate": 1.5}, "desc": "+36% fire rate"},
			{"cost": 110, "changes": {"fire_rate": 2.0}, "desc": "+33% fire rate"},
		]},
	},
	"flame_tower": {
		"path_a": {"name": "Inferno", "upgrades": [
			{"cost": 50, "changes": {"damage": 12}, "desc": "+4 AoE damage"},
			{"cost": 95, "changes": {"damage": 18}, "desc": "+6 AoE damage"},
			{"cost": 160, "changes": {"damage": 28}, "desc": "+10 AoE damage"},
		]},
		"path_b": {"name": "Wildfire", "upgrades": [
			{"cost": 45, "changes": {"burn_damage": 5, "burn_duration": 3.0}, "desc": "Stronger burn"},
			{"cost": 85, "changes": {"burn_damage": 8, "burn_duration": 3.5}, "desc": "Stronger burn"},
			{"cost": 140, "changes": {"burn_damage": 12, "burn_duration": 4.0}, "desc": "Infernal burn"},
		]},
		"path_c": {"name": "Heat Wave", "upgrades": [
			{"cost": 40, "changes": {"range": 120.0}, "desc": "+20% range"},
			{"cost": 75, "changes": {"range": 145.0}, "desc": "+21% range"},
			{"cost": 120, "changes": {"range": 175.0}, "desc": "+21% range"},
		]},
	},
	"antiair_tower": {
		"path_a": {"name": "Piercing Bolts", "upgrades": [
			{"cost": 35, "changes": {"damage": 35}, "desc": "+10 damage"},
			{"cost": 70, "changes": {"damage": 50}, "desc": "+15 damage"},
			{"cost": 120, "changes": {"damage": 75}, "desc": "+25 damage"},
		]},
		"path_b": {"name": "Sky Hunter", "upgrades": [
			{"cost": 40, "changes": {"air_damage_mult": 2.5}, "desc": "+25% air bonus"},
			{"cost": 80, "changes": {"air_damage_mult": 3.0}, "desc": "+20% air bonus"},
			{"cost": 130, "changes": {"air_damage_mult": 4.0}, "desc": "+33% air bonus"},
		]},
		"path_c": {"name": "Rapid Reload", "upgrades": [
			{"cost": 30, "changes": {"fire_rate": 0.9}, "desc": "+29% fire rate"},
			{"cost": 60, "changes": {"fire_rate": 1.2}, "desc": "+33% fire rate"},
			{"cost": 100, "changes": {"fire_rate": 1.6}, "desc": "+33% fire rate"},
		]},
	},
	"sniper_tower": {
		"path_a": {"name": "Armor Piercing", "upgrades": [
			{"cost": 75, "changes": {"damage": 120}, "desc": "+40 damage"},
			{"cost": 140, "changes": {"damage": 180}, "desc": "+60 damage"},
			{"cost": 225, "changes": {"damage": 280}, "desc": "+100 damage"},
		]},
		"path_b": {"name": "Hawk Eye", "upgrades": [
			{"cost": 50, "changes": {"range": 380.0}, "desc": "+27% range"},
			{"cost": 100, "changes": {"range": 480.0}, "desc": "+26% range"},
			{"cost": 160, "changes": {"range": 600.0}, "desc": "+25% range"},
		]},
		"path_c": {"name": "Quick Scope", "upgrades": [
			{"cost": 60, "changes": {"fire_rate": 0.4}, "desc": "+33% fire rate"},
			{"cost": 110, "changes": {"fire_rate": 0.55}, "desc": "+38% fire rate"},
			{"cost": 180, "changes": {"fire_rate": 0.75}, "desc": "+36% fire rate"},
		]},
	},
	"poison_tower": {
		"path_a": {"name": "Virulence", "upgrades": [
			{"cost": 40, "changes": {"poison_damage": 6}, "desc": "+2 poison/sec"},
			{"cost": 75, "changes": {"poison_damage": 10}, "desc": "+4 poison/sec"},
			{"cost": 125, "changes": {"poison_damage": 16}, "desc": "+6 poison/sec"},
		]},
		"path_b": {"name": "Lingering", "upgrades": [
			{"cost": 35, "changes": {"poison_duration": 5.5}, "desc": "+1.5s duration"},
			{"cost": 65, "changes": {"poison_duration": 7.0}, "desc": "+1.5s duration"},
			{"cost": 110, "changes": {"poison_duration": 10.0}, "desc": "+3s duration"},
		]},
		"path_c": {"name": "Toxic Cloud", "upgrades": [
			{"cost": 40, "changes": {"range": 170.0}, "desc": "+21% range"},
			{"cost": 75, "changes": {"range": 200.0}, "desc": "+18% range"},
			{"cost": 120, "changes": {"range": 240.0, "fire_rate": 0.8}, "desc": "+20% range, +33% rate"},
		]},
	},
	"bomb_tower": {
		"path_a": {"name": "Mega Bomb", "upgrades": [
			{"cost": 60, "changes": {"damage": 70}, "desc": "+20 damage"},
			{"cost": 120, "changes": {"damage": 100}, "desc": "+30 damage"},
			{"cost": 200, "changes": {"damage": 150}, "desc": "+50 damage"},
		]},
		"path_b": {"name": "Wide Blast", "upgrades": [
			{"cost": 50, "changes": {"splash_radius": 100.0}, "desc": "+25% splash"},
			{"cost": 100, "changes": {"splash_radius": 130.0}, "desc": "+30% splash"},
			{"cost": 170, "changes": {"splash_radius": 170.0}, "desc": "+31% splash"},
		]},
		"path_c": {"name": "Quick Fuse", "upgrades": [
			{"cost": 50, "changes": {"fire_rate": 0.45}, "desc": "+29% fire rate"},
			{"cost": 95, "changes": {"fire_rate": 0.6}, "desc": "+33% fire rate"},
			{"cost": 155, "changes": {"fire_rate": 0.8}, "desc": "+33% fire rate"},
		]},
	},
	"holy_tower": {
		"path_a": {"name": "Divine Wrath", "upgrades": [
			{"cost": 50, "changes": {"damage": 30}, "desc": "+10 damage"},
			{"cost": 95, "changes": {"damage": 45}, "desc": "+15 damage"},
			{"cost": 155, "changes": {"damage": 70}, "desc": "+25 damage"},
		]},
		"path_b": {"name": "Purify", "upgrades": [
			{"cost": 45, "changes": {"holy_damage_mult": 3.0}, "desc": "+20% holy bonus"},
			{"cost": 85, "changes": {"holy_damage_mult": 3.5}, "desc": "+17% holy bonus"},
			{"cost": 140, "changes": {"holy_damage_mult": 4.5}, "desc": "+29% holy bonus"},
		]},
		"path_c": {"name": "Radiance", "upgrades": [
			{"cost": 40, "changes": {"range": 190.0}, "desc": "+19% range"},
			{"cost": 75, "changes": {"range": 230.0}, "desc": "+21% range"},
			{"cost": 120, "changes": {"fire_rate": 1.0, "range": 260.0}, "desc": "+43% rate, +13% range"},
		]},
	},
	"barracks_tower": {
		"path_a": {"name": "Veterans", "upgrades": [
			{"cost": 40, "changes": {"soldier_damage": 12}, "desc": "+4 soldier damage"},
			{"cost": 80, "changes": {"soldier_damage": 18}, "desc": "+6 soldier damage"},
			{"cost": 130, "changes": {"soldier_damage": 28}, "desc": "+10 soldier damage"},
		]},
		"path_b": {"name": "Reinforced", "upgrades": [
			{"cost": 35, "changes": {"soldier_hp": 75}, "desc": "+25 soldier HP"},
			{"cost": 70, "changes": {"soldier_hp": 110}, "desc": "+35 soldier HP"},
			{"cost": 115, "changes": {"soldier_hp": 160}, "desc": "+50 soldier HP"},
		]},
		"path_c": {"name": "Garrison", "upgrades": [
			{"cost": 50, "changes": {"soldier_count": 3}, "desc": "+1 soldier"},
			{"cost": 100, "changes": {"soldier_count": 4, "soldier_respawn": 12.0}, "desc": "+1 soldier, faster"},
			{"cost": 175, "changes": {"soldier_count": 5, "soldier_respawn": 10.0}, "desc": "+1 soldier, faster"},
		]},
	},
	"gold_mine": {
		"path_a": {"name": "Rich Vein", "upgrades": [
			{"cost": 100, "changes": {"gold_per_wave": 45}, "desc": "+15 gold/wave"},
			{"cost": 175, "changes": {"gold_per_wave": 65}, "desc": "+20 gold/wave"},
			{"cost": 300, "changes": {"gold_per_wave": 100}, "desc": "+35 gold/wave"},
		]},
		"path_b": {"name": "Efficiency", "upgrades": [
			{"cost": 75, "changes": {}, "desc": "No stat change yet"},
			{"cost": 125, "changes": {}, "desc": "No stat change yet"},
			{"cost": 200, "changes": {}, "desc": "No stat change yet"},
		]},
		"path_c": {"name": "Deep Mining", "upgrades": [
			{"cost": 75, "changes": {}, "desc": "No stat change yet"},
			{"cost": 125, "changes": {}, "desc": "No stat change yet"},
			{"cost": 200, "changes": {}, "desc": "No stat change yet"},
		]},
	},
	"storm_tower": {
		"path_a": {"name": "Thunder", "upgrades": [
			{"cost": 75, "changes": {"damage": 18}, "desc": "+6 damage"},
			{"cost": 140, "changes": {"damage": 28}, "desc": "+10 damage"},
			{"cost": 220, "changes": {"damage": 42}, "desc": "+14 damage"},
		]},
		"path_b": {"name": "Supercell", "upgrades": [
			{"cost": 80, "changes": {"max_targets": 6}, "desc": "+1 target"},
			{"cost": 150, "changes": {"max_targets": 8}, "desc": "+2 targets"},
			{"cost": 250, "changes": {"max_targets": 10}, "desc": "+2 targets"},
		]},
		"path_c": {"name": "Tempest", "upgrades": [
			{"cost": 70, "changes": {"fire_rate": 4.5, "range": 180.0}, "desc": "+29% rate, +12% range"},
			{"cost": 130, "changes": {"fire_rate": 6.0, "range": 200.0}, "desc": "+33% rate, +11% range"},
			{"cost": 210, "changes": {"fire_rate": 8.0, "range": 230.0}, "desc": "+33% rate, +15% range"},
		]},
	},
}

func can_afford(tower_type: String) -> bool:
	if not tower_data.has(tower_type):
		return false
	return money >= tower_data[tower_type]["cost"]

func buy_tower(tower_type: String) -> bool:
	if can_afford(tower_type):
		money -= tower_data[tower_type]["cost"]
		return true
	return false

func can_afford_upgrade(tower_type: String, path: String, level: int) -> bool:
	if not upgrade_data.has(tower_type):
		return false
	if not upgrade_data[tower_type].has(path):
		return false
	var upgrades = upgrade_data[tower_type][path]["upgrades"]
	if level < 0 or level >= upgrades.size():
		return false
	return money >= upgrades[level]["cost"]

func buy_upgrade(tower_type: String, path: String, level: int) -> Dictionary:
	if not can_afford_upgrade(tower_type, path, level):
		return {}
	var upgrade = upgrade_data[tower_type][path]["upgrades"][level]
	money -= upgrade["cost"]
	return upgrade.get("changes", {})

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
	# Gold mine income
	_apply_gold_mine_income()

func _apply_gold_mine_income():
	var towers_container = get_tree().get_first_node_in_group("towers_container")
	if not towers_container:
		return
	for tower in towers_container.get_children():
		if tower.has_method("get_tower_type") and tower.get_tower_type() == "gold_mine":
			var gold = tower.get_gold_per_wave()
			money += gold
			total_gold_earned += gold

func complete_wave():
	is_wave_active = false
	wave_completed.emit(current_wave)
	var bonus = 25 + (current_wave * 5)
	money += bonus
	total_gold_earned += bonus
	
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
	money = 100 + (current_level - 1) * 25
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
	var time_bonus = max(0, 300 - int(level_elapsed_time))
	return (lives * 100) + (enemies_killed * 10) + time_bonus

func reset():
	money = 100
	lives = 20
	current_wave = 0
	is_wave_active = false
	game_active = true
	enemies_killed = 0
	total_gold_earned = 0
