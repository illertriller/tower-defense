extends RefCounted
class_name LevelData

## Static level definitions for all 5 levels
## Each level has: name, path points, and wave definitions

# Level path points (packed as Vector2 arrays for Curve2D)
# Viewport: 1280x720, grid: 32px cells
# All coordinates snapped to 32px grid cell centers (x*32+16, y*32+16)

static func get_level_count() -> int:
	return 5

static func get_level_name(level: int) -> String:
	var names = {
		1: "The Valley",
		2: "The Crossing",
		3: "The Spiral",
		4: "The Serpent",
		5: "The Gauntlet"
	}
	return names.get(level, "Unknown")

static func get_path_points(level: int) -> PackedVector2Array:
	match level:
		1:
			# Simple S-curve — easy intro, lots of tower space
			return PackedVector2Array([
				Vector2(-48, 208),
				Vector2(208, 208),
				Vector2(208, 400),
				Vector2(496, 400),
				Vector2(496, 144),
				Vector2(784, 144),
				Vector2(784, 496),
				Vector2(1104, 496),
				Vector2(1328, 304)
			])
		2:
			# The Crossing — enters from top, crosses the map
			return PackedVector2Array([
				Vector2(-48, 112),
				Vector2(176, 112),
				Vector2(176, 368),
				Vector2(560, 368),
				Vector2(560, 112),
				Vector2(880, 112),
				Vector2(880, 528),
				Vector2(1328, 528)
			])
		3:
			# The Spiral — clockwise spiral inward, exits right
			return PackedVector2Array([
				Vector2(-48, 336),
				Vector2(144, 336),
				Vector2(144, 80),
				Vector2(1104, 80),
				Vector2(1104, 592),
				Vector2(336, 592),
				Vector2(336, 272),
				Vector2(848, 272),
				Vector2(848, 432),
				Vector2(1328, 432)
			])
		4:
			# The Serpent — tight zigzag, narrow corridors
			return PackedVector2Array([
				Vector2(-48, 80),
				Vector2(304, 80),
				Vector2(304, 592),
				Vector2(624, 592),
				Vector2(624, 80),
				Vector2(944, 80),
				Vector2(944, 592),
				Vector2(1328, 592)
			])
		5:
			# The Gauntlet — maximum length, complex routing
			return PackedVector2Array([
				Vector2(-48, 176),
				Vector2(208, 176),
				Vector2(208, 560),
				Vector2(464, 560),
				Vector2(464, 112),
				Vector2(720, 112),
				Vector2(720, 432),
				Vector2(560, 432),
				Vector2(560, 304),
				Vector2(880, 304),
				Vector2(880, 560),
				Vector2(1104, 560),
				Vector2(1104, 176),
				Vector2(1328, 176)
			])
		_:
			return get_path_points(1)  # fallback

static func get_waves(level: int) -> Array:
	match level:
		1:
			return _level_1_waves()
		2:
			return _level_2_waves()
		3:
			return _level_3_waves()
		4:
			return _level_4_waves()
		5:
			return _level_5_waves()
		_:
			return _level_1_waves()

static func get_total_waves(_level: int) -> int:
	return 10

# === LEVEL 1 — The Valley (Easy Intro) ===
static func _level_1_waves() -> Array:
	return [
		# Wave 1: Just imps
		[{"type": "imp", "count": 5, "delay": 1.2}],
		# Wave 2: More imps
		[{"type": "imp", "count": 8, "delay": 1.0}],
		# Wave 3: Introduce hell hounds
		[{"type": "imp", "count": 5, "delay": 1.0},
		 {"type": "hell_hound", "count": 3, "delay": 0.7}],
		# Wave 4: Mixed
		[{"type": "imp", "count": 6, "delay": 0.9},
		 {"type": "hell_hound", "count": 5, "delay": 0.6}],
		# Wave 5: Introduce brute
		[{"type": "imp", "count": 8, "delay": 0.8},
		 {"type": "brute_demon", "count": 2, "delay": 2.0}],
		# Wave 6: Fast rush
		[{"type": "hell_hound", "count": 10, "delay": 0.4}],
		# Wave 7: Heavy mixed
		[{"type": "imp", "count": 10, "delay": 0.7},
		 {"type": "hell_hound", "count": 5, "delay": 0.5},
		 {"type": "brute_demon", "count": 3, "delay": 1.5}],
		# Wave 8: Introduce shadow stalker
		[{"type": "shadow_stalker", "count": 4, "delay": 1.0},
		 {"type": "imp", "count": 8, "delay": 0.6}],
		# Wave 9: Big push
		[{"type": "imp", "count": 12, "delay": 0.5},
		 {"type": "hell_hound", "count": 8, "delay": 0.4},
		 {"type": "brute_demon", "count": 4, "delay": 1.2}],
		# Wave 10: Mini boss
		[{"type": "imp", "count": 10, "delay": 0.6},
		 {"type": "brute_demon", "count": 5, "delay": 1.0},
		 {"type": "hell_knight", "count": 1, "delay": 3.0}],
	]

# === LEVEL 2 — The Crossing (Medium) ===
static func _level_2_waves() -> Array:
	return [
		[{"type": "imp", "count": 8, "delay": 0.9}],
		[{"type": "imp", "count": 6, "delay": 0.8},
		 {"type": "hell_hound", "count": 4, "delay": 0.6}],
		[{"type": "hell_hound", "count": 8, "delay": 0.5},
		 {"type": "shadow_stalker", "count": 2, "delay": 1.0}],
		[{"type": "imp", "count": 10, "delay": 0.7},
		 {"type": "brute_demon", "count": 3, "delay": 1.5}],
		[{"type": "fire_elemental", "count": 5, "delay": 1.0},
		 {"type": "hell_hound", "count": 6, "delay": 0.5}],
		[{"type": "shadow_stalker", "count": 6, "delay": 0.8},
		 {"type": "imp", "count": 8, "delay": 0.6}],
		[{"type": "brute_demon", "count": 5, "delay": 1.2},
		 {"type": "fire_elemental", "count": 4, "delay": 1.0}],
		[{"type": "hell_hound", "count": 12, "delay": 0.3},
		 {"type": "brute_demon", "count": 4, "delay": 1.0},
		 {"type": "hell_knight", "count": 2, "delay": 2.0}],
		[{"type": "imp", "count": 15, "delay": 0.4},
		 {"type": "fire_elemental", "count": 6, "delay": 0.8},
		 {"type": "bone_golem", "count": 2, "delay": 3.0}],
		[{"type": "hell_knight", "count": 3, "delay": 2.0},
		 {"type": "brute_demon", "count": 6, "delay": 1.0},
		 {"type": "hell_hound", "count": 10, "delay": 0.3},
		 {"type": "demon_lord", "count": 1, "delay": 5.0}],
	]

# === LEVEL 3 — The Spiral (Hard) ===
static func _level_3_waves() -> Array:
	return [
		[{"type": "imp", "count": 10, "delay": 0.7}],
		[{"type": "hell_hound", "count": 8, "delay": 0.5},
		 {"type": "fire_elemental", "count": 3, "delay": 1.0}],
		[{"type": "shadow_stalker", "count": 5, "delay": 0.8},
		 {"type": "brute_demon", "count": 4, "delay": 1.3}],
		[{"type": "succubus", "count": 3, "delay": 1.5},
		 {"type": "imp", "count": 12, "delay": 0.5}],
		[{"type": "bone_golem", "count": 3, "delay": 2.0},
		 {"type": "hell_hound", "count": 10, "delay": 0.4}],
		[{"type": "wraith", "count": 6, "delay": 0.8},
		 {"type": "fire_elemental", "count": 5, "delay": 0.9}],
		[{"type": "hell_knight", "count": 4, "delay": 1.5},
		 {"type": "shadow_stalker", "count": 6, "delay": 0.7},
		 {"type": "succubus", "count": 2, "delay": 2.0}],
		[{"type": "brute_demon", "count": 8, "delay": 0.9},
		 {"type": "wraith", "count": 5, "delay": 0.7},
		 {"type": "bone_golem", "count": 3, "delay": 1.5}],
		[{"type": "hell_knight", "count": 5, "delay": 1.2},
		 {"type": "fire_elemental", "count": 8, "delay": 0.6},
		 {"type": "succubus", "count": 4, "delay": 1.0}],
		[{"type": "demon_lord", "count": 2, "delay": 4.0},
		 {"type": "hell_knight", "count": 6, "delay": 1.0},
		 {"type": "bone_golem", "count": 4, "delay": 1.5},
		 {"type": "hell_hound", "count": 15, "delay": 0.25}],
	]

# === LEVEL 4 — The Serpent (Very Hard) ===
static func _level_4_waves() -> Array:
	return [
		[{"type": "hell_hound", "count": 12, "delay": 0.4}],
		[{"type": "fire_elemental", "count": 6, "delay": 0.8},
		 {"type": "shadow_stalker", "count": 4, "delay": 0.7}],
		[{"type": "brute_demon", "count": 6, "delay": 1.0},
		 {"type": "succubus", "count": 3, "delay": 1.5}],
		[{"type": "wraith", "count": 8, "delay": 0.6},
		 {"type": "hell_knight", "count": 3, "delay": 1.5}],
		[{"type": "bone_golem", "count": 4, "delay": 1.5},
		 {"type": "fire_elemental", "count": 8, "delay": 0.6}],
		[{"type": "hell_hound", "count": 20, "delay": 0.2},
		 {"type": "shadow_stalker", "count": 5, "delay": 0.6}],
		[{"type": "hell_knight", "count": 6, "delay": 1.0},
		 {"type": "succubus", "count": 4, "delay": 1.2},
		 {"type": "bone_golem", "count": 3, "delay": 2.0}],
		[{"type": "demon_lord", "count": 1, "delay": 3.0},
		 {"type": "brute_demon", "count": 8, "delay": 0.8},
		 {"type": "wraith", "count": 8, "delay": 0.5}],
		[{"type": "hell_knight", "count": 8, "delay": 0.8},
		 {"type": "fire_elemental", "count": 10, "delay": 0.5},
		 {"type": "bone_golem", "count": 5, "delay": 1.2}],
		[{"type": "demon_lord", "count": 3, "delay": 3.0},
		 {"type": "hell_knight", "count": 8, "delay": 0.7},
		 {"type": "succubus", "count": 5, "delay": 1.0},
		 {"type": "bone_golem", "count": 6, "delay": 1.0}],
	]

# === LEVEL 5 — The Gauntlet (Brutal) ===
static func _level_5_waves() -> Array:
	return [
		[{"type": "hell_hound", "count": 15, "delay": 0.3},
		 {"type": "fire_elemental", "count": 5, "delay": 0.7}],
		[{"type": "brute_demon", "count": 8, "delay": 0.8},
		 {"type": "shadow_stalker", "count": 6, "delay": 0.6}],
		[{"type": "wraith", "count": 10, "delay": 0.5},
		 {"type": "succubus", "count": 4, "delay": 1.2}],
		[{"type": "bone_golem", "count": 5, "delay": 1.5},
		 {"type": "hell_knight", "count": 5, "delay": 1.0},
		 {"type": "hell_hound", "count": 10, "delay": 0.3}],
		[{"type": "demon_lord", "count": 1, "delay": 3.0},
		 {"type": "fire_elemental", "count": 10, "delay": 0.5},
		 {"type": "shadow_stalker", "count": 8, "delay": 0.5}],
		[{"type": "hell_knight", "count": 8, "delay": 0.8},
		 {"type": "bone_golem", "count": 6, "delay": 1.0},
		 {"type": "succubus", "count": 5, "delay": 1.0}],
		[{"type": "hell_hound", "count": 25, "delay": 0.15},
		 {"type": "wraith", "count": 10, "delay": 0.4}],
		[{"type": "demon_lord", "count": 2, "delay": 3.0},
		 {"type": "hell_knight", "count": 10, "delay": 0.6},
		 {"type": "brute_demon", "count": 10, "delay": 0.7}],
		[{"type": "bone_golem", "count": 8, "delay": 0.8},
		 {"type": "succubus", "count": 6, "delay": 0.8},
		 {"type": "fire_elemental", "count": 12, "delay": 0.4},
		 {"type": "wraith", "count": 8, "delay": 0.5}],
		# Wave 10: HELL UNLEASHED
		[{"type": "demon_lord", "count": 5, "delay": 2.0},
		 {"type": "hell_knight", "count": 10, "delay": 0.5},
		 {"type": "bone_golem", "count": 8, "delay": 0.8},
		 {"type": "succubus", "count": 6, "delay": 0.7},
		 {"type": "hell_hound", "count": 20, "delay": 0.2}],
	]
