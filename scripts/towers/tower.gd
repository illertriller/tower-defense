extends Node2D

## Universal tower script — handles all tower types via data-driven behavior
## Projectile, beam (chain lightning), AoE, and passive towers

@onready var range_area: Area2D = $RangeArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var barrel: Marker2D = $Barrel

@export var projectile_scene: PackedScene

var tower_type: String = "arrow_tower"
var damage: int = 10
var attack_range: float = 150.0
var fire_rate: float = 1.0
var projectile_speed: float = 300.0
var current_target: Area2D = null
var enemies_in_range: Array = []
var can_shoot: bool = true
var _pending_type: String = ""

# Tower data cache (from GameManager)
var _tower_data: Dictionary = {}

# Upgrade tracking
var upgrade_levels: Dictionary = {"path_a": 0, "path_b": 0, "path_c": 0}

# Beam tower vars
var max_targets: int = 3
var lightning_lines: Array = []

# AoE vars (flame tower)
var aoe_active: bool = false

# Passive vars (gold mine)
var gold_per_wave: int = 30

func setup(type: String):
	_pending_type = type

func _ready():
	if not _pending_type.is_empty():
		_apply_setup(_pending_type)

func _apply_setup(type: String):
	tower_type = type
	_tower_data = GameManager.tower_data.get(type, {})
	if _tower_data.is_empty():
		push_warning("Unknown tower type: " + type)
		return
	
	damage = _tower_data.get("damage", 10)
	attack_range = _tower_data.get("range", 150.0)
	fire_rate = _tower_data.get("fire_rate", 1.0)
	projectile_speed = _tower_data.get("projectile_speed", 300.0)
	max_targets = _tower_data.get("max_targets", 3)
	gold_per_wave = _tower_data.get("gold_per_wave", 0)
	
	# Set tower sprite
	var texture_path = "res://assets/sprites/towers/%s.png" % type
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
	
	# Set range collision shape (skip for passive towers)
	if attack_range > 0:
		var shape = CircleShape2D.new()
		shape.radius = attack_range
		$RangeArea/CollisionShape2D.shape = shape
	
	# Set fire rate
	if fire_rate > 0:
		shoot_timer.wait_time = 1.0 / fire_rate
	
	# AoE towers are always "shooting" when enemies are in range
	var attack_type = _tower_data.get("attack_type", 0)
	aoe_active = (attack_type == GameManager.AttackType.AOE)

func get_tower_type() -> String:
	return tower_type

func get_gold_per_wave() -> int:
	return gold_per_wave

func _process(_delta: float):
	var attack_type = _tower_data.get("attack_type", 0)
	
	match attack_type:
		GameManager.AttackType.PROJECTILE:
			_update_target()
			if can_shoot and current_target and is_instance_valid(current_target):
				_shoot_projectile()
		GameManager.AttackType.BEAM:
			_update_beam_targets()
			_update_lightning()
			if can_shoot and not _get_current_beam_targets().is_empty():
				_zap()
		GameManager.AttackType.AOE:
			if can_shoot and not enemies_in_range.is_empty():
				_aoe_damage()
		GameManager.AttackType.PASSIVE, GameManager.AttackType.SPAWN:
			pass  # No active attack

func _update_target():
	# Remove invalid enemies
	_clean_enemies()
	
	if enemies_in_range.is_empty():
		current_target = null
		return
	
	# Filter by targeting rules
	var valid = _get_valid_targets()
	if valid.is_empty():
		current_target = null
		return
	
	# Target enemy furthest along the path (closest to exit)
	var best_target: Area2D = null
	var best_progress: float = 0.0
	
	for enemy in valid:
		var path_follow = enemy.get_parent() as PathFollow2D
		if path_follow and path_follow.progress_ratio > best_progress:
			best_progress = path_follow.progress_ratio
			best_target = enemy
	
	current_target = best_target

func _get_valid_targets() -> Array:
	var targets_air = _tower_data.get("targets_air", true)
	var targets_ground = _tower_data.get("targets_ground", true)
	var valid: Array = []
	for e in enemies_in_range:
		if not is_instance_valid(e):
			continue
		if e.is_flying and not targets_air:
			continue
		if not e.is_flying and not targets_ground:
			continue
		valid.append(e)
	return valid

func _clean_enemies():
	var valid: Array = []
	for e in enemies_in_range:
		if is_instance_valid(e):
			valid.append(e)
	enemies_in_range = valid

func _shoot_projectile():
	if not projectile_scene:
		return
	
	can_shoot = false
	shoot_timer.start()
	
	var projectile = projectile_scene.instantiate()
	if barrel:
		projectile.global_position = barrel.global_position
	else:
		projectile.global_position = global_position
	projectile.target = current_target
	projectile.speed = projectile_speed
	
	# Calculate damage with specials
	var final_damage = damage
	var specials = _tower_data.get("specials", [])
	
	# Air bonus
	if "air_bonus" in specials and current_target and current_target.is_flying:
		final_damage = int(final_damage * _tower_data.get("air_damage_mult", 2.0))
	
	# Holy bonus
	if "holy" in specials and current_target:
		var holy_types = _tower_data.get("holy_bonus_types", [])
		if current_target.enemy_type in holy_types:
			final_damage = int(final_damage * _tower_data.get("holy_damage_mult", 2.5))
	
	projectile.damage = final_damage
	
	# Pass special effects to projectile
	if "splash" in specials:
		projectile.splash_radius = _tower_data.get("splash_radius", 50.0)
	if "slow" in specials:
		projectile.apply_slow_on_hit = true
		projectile.slow_amount = _tower_data.get("slow_amount", 0.5)
		projectile.slow_duration = _tower_data.get("slow_duration", 1.5)
	if "poison" in specials:
		projectile.apply_poison_on_hit = true
		projectile.poison_damage = _tower_data.get("poison_damage", 4)
		projectile.poison_duration = _tower_data.get("poison_duration", 4.0)
	
	# Set projectile visual type
	var proj_type = _tower_data.get("projectile_type", "arrow")
	if not proj_type.is_empty():
		projectile.projectile_type = proj_type
	
	get_tree().root.add_child(projectile)

# === BEAM (Chain Lightning) ===
func _update_beam_targets():
	_clean_enemies()

func _get_current_beam_targets() -> Array:
	var valid = _get_valid_targets()
	if valid.is_empty():
		return []
	
	valid.sort_custom(func(a, b):
		var da = global_position.distance_squared_to(a.global_position)
		var db = global_position.distance_squared_to(b.global_position)
		return da < db
	)
	
	var targets: Array = []
	for i in range(min(max_targets, valid.size())):
		targets.append(valid[i])
	return targets

func _update_lightning():
	for line in lightning_lines:
		if is_instance_valid(line):
			line.queue_free()
	lightning_lines.clear()
	
	var targets = _get_current_beam_targets()
	for target in targets:
		if is_instance_valid(target):
			var line = Line2D.new()
			line.width = 2.0
			line.default_color = Color(0.4, 0.7, 1.0, 0.9)
			line.z_index = 10
			
			var start = Vector2.ZERO
			var end = target.global_position - global_position
			var points = _generate_lightning_points(start, end)
			for p in points:
				line.add_point(p)
			add_child(line)
			lightning_lines.append(line)

func _generate_lightning_points(start: Vector2, end: Vector2) -> Array:
	var points: Array = [start]
	var segments = 6
	var direction = end - start
	for i in range(1, segments):
		var t = float(i) / segments
		var base_point = start + direction * t
		var perpendicular = Vector2(-direction.y, direction.x).normalized()
		var offset = perpendicular * randf_range(-12.0, 12.0)
		points.append(base_point + offset)
	points.append(end)
	return points

func _zap():
	can_shoot = false
	shoot_timer.start()
	var targets = _get_current_beam_targets()
	for target in targets:
		if is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(damage)
			GameParticles.spawn_frost_hit(get_tree(), target.global_position)  # Electric spark

# === AOE (Flame Tower) ===
func _aoe_damage():
	can_shoot = false
	shoot_timer.start()
	GameParticles.spawn_fire_burst(get_tree(), global_position)
	var targets = _get_valid_targets()
	for target in targets:
		if is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(damage)
			if "burn" in _tower_data.get("specials", []) and target.has_method("apply_burn"):
				target.apply_burn(
					_tower_data.get("burn_damage", 3),
					_tower_data.get("burn_duration", 2.0)
				)

# === UPGRADE SYSTEM ===
func get_upgrade_info() -> Dictionary:
	if not GameManager.upgrade_data.has(tower_type):
		return {}
	var info = {}
	var paths = GameManager.upgrade_data[tower_type]
	for path_key in paths:
		var path_data = paths[path_key]
		var current_level = upgrade_levels.get(path_key, 0)
		var upgrades = path_data["upgrades"]
		info[path_key] = {
			"name": path_data["name"],
			"current_level": current_level,
			"max_level": upgrades.size(),
			"can_upgrade": current_level < upgrades.size(),
			"next_cost": upgrades[current_level]["cost"] if current_level < upgrades.size() else 0,
			"next_desc": upgrades[current_level]["desc"] if current_level < upgrades.size() else "MAX",
		}
	return info

func apply_upgrade(path: String) -> bool:
	var current_level = upgrade_levels.get(path, 0)
	var changes = GameManager.buy_upgrade(tower_type, path, current_level)
	if changes.is_empty():
		return false
	
	# Apply stat changes
	for stat in changes:
		match stat:
			"damage": damage = changes[stat]
			"range":
				attack_range = changes[stat]
				var shape = CircleShape2D.new()
				shape.radius = attack_range
				$RangeArea/CollisionShape2D.shape = shape
			"fire_rate":
				fire_rate = changes[stat]
				shoot_timer.wait_time = 1.0 / fire_rate
			"splash_radius": _tower_data["splash_radius"] = changes[stat]
			"slow_amount": _tower_data["slow_amount"] = changes[stat]
			"slow_duration": _tower_data["slow_duration"] = changes[stat]
			"max_targets": max_targets = changes[stat]
			"burn_damage": _tower_data["burn_damage"] = changes[stat]
			"burn_duration": _tower_data["burn_duration"] = changes[stat]
			"poison_damage": _tower_data["poison_damage"] = changes[stat]
			"poison_duration": _tower_data["poison_duration"] = changes[stat]
			"air_damage_mult": _tower_data["air_damage_mult"] = changes[stat]
			"holy_damage_mult": _tower_data["holy_damage_mult"] = changes[stat]
			"soldier_count": _tower_data["soldier_count"] = changes[stat]
			"soldier_hp": _tower_data["soldier_hp"] = changes[stat]
			"soldier_damage": _tower_data["soldier_damage"] = changes[stat]
			"soldier_respawn": _tower_data["soldier_respawn"] = changes[stat]
			"gold_per_wave": gold_per_wave = changes[stat]
			"projectile_speed": projectile_speed = changes[stat]
	
	upgrade_levels[path] = current_level + 1
	GameManager.tower_upgraded.emit(self)
	return true

# Signal handlers
func _on_range_area_area_entered(area: Area2D):
	if area.is_in_group("enemies"):
		enemies_in_range.append(area)

func _on_range_area_area_exited(area: Area2D):
	enemies_in_range.erase(area)

func _on_shoot_timer_timeout():
	can_shoot = true
