extends RefCounted
class_name LevelData

## Static level definitions for all 5 levels
## Each level has: name, path points, and wave definitions
## Map size: 2560x1440 (80x45 grid cells at 32px each)
## All coordinates snapped to 32px grid cell centers (x*32+16, y*32+16)

static func get_level_count() -> int:
	return 5

static func get_terrain_theme(level: int) -> Dictionary:
	match level:
		1: # The Valley — lush green meadow
			return {
				"grass": Color(0.28, 0.55, 0.22),
				"grass_var": Color(0.22, 0.45, 0.17),
				"road": Color(0.55, 0.43, 0.28),
				"road_edge": Color(0.35, 0.26, 0.15),
				"road_center": Color(0.50, 0.40, 0.26),
			}
		2: # The Crossing — golden autumn fields
			return {
				"grass": Color(0.62, 0.55, 0.25),
				"grass_var": Color(0.52, 0.44, 0.18),
				"road": Color(0.50, 0.45, 0.35),
				"road_edge": Color(0.35, 0.30, 0.20),
				"road_center": Color(0.46, 0.42, 0.32),
			}
		3: # The Spiral — dark mossy cavern
			return {
				"grass": Color(0.16, 0.32, 0.20),
				"grass_var": Color(0.10, 0.22, 0.14),
				"road": Color(0.38, 0.36, 0.30),
				"road_edge": Color(0.22, 0.20, 0.16),
				"road_center": Color(0.34, 0.32, 0.27),
			}
		4: # The Serpent — scorched desert
			return {
				"grass": Color(0.72, 0.62, 0.38),
				"grass_var": Color(0.62, 0.52, 0.30),
				"road": Color(0.60, 0.48, 0.32),
				"road_edge": Color(0.45, 0.34, 0.22),
				"road_center": Color(0.56, 0.44, 0.30),
			}
		5: # The Gauntlet — volcanic ashlands
			return {
				"grass": Color(0.28, 0.22, 0.22),
				"grass_var": Color(0.18, 0.13, 0.13),
				"road": Color(0.35, 0.26, 0.24),
				"road_edge": Color(0.18, 0.10, 0.08),
				"road_center": Color(0.32, 0.24, 0.22),
			}
		_:
			return get_terrain_theme(1)

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
	# Map size: 2560x1440
	# Grid: 80 x 45 cells (32px each)
	# Paths use the full map — much longer routes for bigger strategy
	match level:
		1:
			# The Valley — gentle S-curve across the map, good intro
			# Enters left, sweeps through wide open spaces
			return PackedVector2Array([
				Vector2(-48, 400),
				Vector2(336, 400),
				Vector2(336, 800),
				Vector2(816, 800),
				Vector2(816, 240),
				Vector2(1360, 240),
				Vector2(1360, 960),
				Vector2(1904, 960),
				Vector2(1904, 400),
				Vector2(2608, 400)
			])
		2:
			# The Crossing — enters top-left, zigzags down then across
			# Longer path with more bends
			return PackedVector2Array([
				Vector2(-48, 208),
				Vector2(400, 208),
				Vector2(400, 720),
				Vector2(880, 720),
				Vector2(880, 208),
				Vector2(1360, 208),
				Vector2(1360, 1040),
				Vector2(1840, 1040),
				Vector2(1840, 480),
				Vector2(2608, 480)
			])
		3:
			# The Spiral — massive clockwise spiral, enters left exits right
			# Uses the full map space for a grand sweeping spiral
			return PackedVector2Array([
				Vector2(-48, 720),
				Vector2(240, 720),
				Vector2(240, 160),
				Vector2(2320, 160),
				Vector2(2320, 1280),
				Vector2(560, 1280),
				Vector2(560, 480),
				Vector2(1840, 480),
				Vector2(1840, 960),
				Vector2(880, 960),
				Vector2(880, 640),
				Vector2(1520, 640),
				Vector2(1520, 800),
				Vector2(2608, 800)
			])
		4:
			# The Serpent — tight zigzag across the whole map
			# Maximum path length through narrow corridors
			return PackedVector2Array([
				Vector2(-48, 160),
				Vector2(480, 160),
				Vector2(480, 1280),
				Vector2(960, 1280),
				Vector2(960, 160),
				Vector2(1440, 160),
				Vector2(1440, 1280),
				Vector2(1920, 1280),
				Vector2(1920, 160),
				Vector2(2608, 160)
			])
		5:
			# The Gauntlet — maximum complexity, uses every corner
			# The ultimate maze with switchbacks and loops
			return PackedVector2Array([
				Vector2(-48, 336),
				Vector2(368, 336),
				Vector2(368, 1200),
				Vector2(720, 1200),
				Vector2(720, 240),
				Vector2(1120, 240),
				Vector2(1120, 880),
				Vector2(800, 880),
				Vector2(800, 560),
				Vector2(1440, 560),
				Vector2(1440, 1200),
				Vector2(1840, 1200),
				Vector2(1840, 336),
				Vector2(2160, 336),
				Vector2(2160, 1040),
				Vector2(2608, 1040)
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
		[{"type": "imp", "count": 5, "delay": 1.2}],
		[{"type": "imp", "count": 8, "delay": 1.0}],
		[{"type": "imp", "count": 5, "delay": 1.0},
		 {"type": "hell_hound", "count": 3, "delay": 0.7}],
		[{"type": "imp", "count": 6, "delay": 0.9},
		 {"type": "hell_hound", "count": 5, "delay": 0.6}],
		[{"type": "imp", "count": 8, "delay": 0.8},
		 {"type": "brute_demon", "count": 2, "delay": 2.0}],
		[{"type": "hell_hound", "count": 10, "delay": 0.4}],
		[{"type": "imp", "count": 10, "delay": 0.7},
		 {"type": "hell_hound", "count": 5, "delay": 0.5},
		 {"type": "brute_demon", "count": 3, "delay": 1.5}],
		[{"type": "shadow_stalker", "count": 4, "delay": 1.0},
		 {"type": "imp", "count": 8, "delay": 0.6}],
		[{"type": "imp", "count": 12, "delay": 0.5},
		 {"type": "hell_hound", "count": 8, "delay": 0.4},
		 {"type": "brute_demon", "count": 4, "delay": 1.2}],
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
