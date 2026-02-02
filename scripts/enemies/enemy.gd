extends Area2D

## Base enemy script
## Follows a Path2D and takes damage from towers

signal died()
signal reached_end()

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

var max_health: int = 50
var health: int = 50
var speed: float = 80.0
var reward: int = 10
var slow_multiplier: float = 1.0
var slow_timer: float = 0.0
var enemy_type: String = "imp"
var is_flying: bool = false

# DoT effects
var poison_damage: float = 0.0
var poison_timer: float = 0.0
var burn_damage: float = 0.0
var burn_timer: float = 0.0
var dot_tick_timer: float = 0.0

# All 10 demon enemy types with stats
var enemy_types: Dictionary = {
	"imp": {"health": 40, "speed": 80, "reward": 5},
	"hell_hound": {"health": 25, "speed": 160, "reward": 8},
	"brute_demon": {"health": 200, "speed": 40, "reward": 20},
	"wraith": {"health": 60, "speed": 90, "reward": 12, "flying": true},
	"fire_elemental": {"health": 80, "speed": 70, "reward": 15},
	"shadow_stalker": {"health": 50, "speed": 100, "reward": 12},
	"bone_golem": {"health": 400, "speed": 25, "reward": 35},
	"succubus": {"health": 70, "speed": 75, "reward": 20},
	"hell_knight": {"health": 250, "speed": 50, "reward": 30},
	"demon_lord": {"health": 1000, "speed": 30, "reward": 100},
	# Legacy types (fallback to new equivalents)
	"basic": {"health": 40, "speed": 80, "reward": 5},
	"fast": {"health": 25, "speed": 160, "reward": 8},
	"tank": {"health": 200, "speed": 40, "reward": 20},
	"boss": {"health": 1000, "speed": 30, "reward": 100},
}

# Sprite sheet paths per type
var sprite_sheets: Dictionary = {
	"imp": "res://assets/sprites/enemies/imp_walk_sheet.png",
	"hell_hound": "res://assets/sprites/enemies/hell_hound_walk_sheet.png",
	"brute_demon": "res://assets/sprites/enemies/brute_demon_walk_sheet.png",
	"wraith": "res://assets/sprites/enemies/wraith_walk_sheet.png",
	"fire_elemental": "res://assets/sprites/enemies/fire_elemental_walk_sheet.png",
	"shadow_stalker": "res://assets/sprites/enemies/shadow_stalker_walk_sheet.png",
	"bone_golem": "res://assets/sprites/enemies/bone_golem_walk_sheet.png",
	"succubus": "res://assets/sprites/enemies/succubus_walk_sheet.png",
	"hell_knight": "res://assets/sprites/enemies/hell_knight_walk_sheet.png",
	"demon_lord": "res://assets/sprites/enemies/demon_lord_walk_sheet.png",
	# Legacy fallbacks
	"basic": "res://assets/sprites/enemies/imp_walk_sheet.png",
	"fast": "res://assets/sprites/enemies/hell_hound_walk_sheet.png",
	"tank": "res://assets/sprites/enemies/brute_demon_walk_sheet.png",
	"boss": "res://assets/sprites/enemies/demon_lord_walk_sheet.png",
}

# Default sprite facing direction (true = faces right in the sheet)
var default_faces_right: Dictionary = {
	"imp": true,
	"hell_hound": false,
	"brute_demon": false,
	"wraith": true,
	"fire_elemental": true,
	"shadow_stalker": false,
	"bone_golem": false,
	"succubus": true,  # Faces forward, doesn't matter (flying)
	"hell_knight": false,
	"demon_lord": true,
	"basic": true,
	"fast": false,
	"tank": false,
	"boss": true,
}

# Animation speeds per type (FPS)
var anim_speeds: Dictionary = {
	"imp": 6.0,
	"hell_hound": 10.0,
	"brute_demon": 5.0,
	"wraith": 5.0,
	"fire_elemental": 7.0,
	"shadow_stalker": 8.0,
	"bone_golem": 3.0,
	"succubus": 6.0,
	"hell_knight": 5.0,
	"demon_lord": 4.0,
	"basic": 6.0,
	"fast": 10.0,
	"tank": 4.0,
	"boss": 4.0,
}

func setup(type: String):
	enemy_type = type
	if type in enemy_types:
		var data = enemy_types[type]
		max_health = data["health"]
		health = max_health
		speed = data["speed"]
		reward = data["reward"]
		is_flying = data.get("flying", false)

func _ready():
	health_bar.max_value = max_health
	health_bar.value = health
	_setup_animation()

func _setup_animation():
	var frames = SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("walk")
	
	var sheet_path = sprite_sheets.get(enemy_type, sprite_sheets["imp"])
	var sheet_texture = load(sheet_path)
	
	if sheet_texture:
		var sheet_image = sheet_texture.get_image()
		var frame_width = 64
		var frame_height = 64
		var frame_count = sheet_image.get_width() / frame_width
		
		for i in range(frame_count):
			var frame_image = Image.create(frame_width, frame_height, false, sheet_image.get_format())
			frame_image.blit_rect(sheet_image, Rect2i(i * frame_width, 0, frame_width, frame_height), Vector2i(0, 0))
			var frame_texture = ImageTexture.create_from_image(frame_image)
			frames.add_frame("walk", frame_texture)
		
		frames.set_animation_speed("walk", anim_speeds.get(enemy_type, 6.0))
		frames.set_animation_loop("walk", true)
	else:
		# Fallback: create a colored placeholder if sprite not found
		_create_placeholder_frames(frames)
	
	animated_sprite.sprite_frames = frames
	animated_sprite.play("walk")

func _create_placeholder_frames(frames: SpriteFrames):
	# Generate a colored rectangle as placeholder
	var colors = {
		"imp": Color.RED,
		"hell_hound": Color.ORANGE_RED,
		"brute_demon": Color.DARK_RED,
		"wraith": Color(0.5, 0.3, 0.8),
		"fire_elemental": Color.ORANGE,
		"shadow_stalker": Color(0.2, 0.2, 0.3),
		"bone_golem": Color(0.9, 0.9, 0.8),
		"succubus": Color(0.7, 0.2, 0.5),
		"hell_knight": Color(0.5, 0.1, 0.1),
		"demon_lord": Color(0.8, 0.0, 0.0),
	}
	var color = colors.get(enemy_type, Color.RED)
	
	for i in range(4):
		var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(color)
		# Draw a simple border
		for x in range(64):
			img.set_pixel(x, 0, Color.BLACK)
			img.set_pixel(x, 63, Color.BLACK)
		for y in range(64):
			img.set_pixel(0, y, Color.BLACK)
			img.set_pixel(63, y, Color.BLACK)
		frames.add_frame("walk", ImageTexture.create_from_image(img))
	
	frames.set_animation_speed("walk", 6.0)
	frames.set_animation_loop("walk", true)

var last_h_facing_right: bool = true

func _process(delta: float):
	# Handle slow effect
	if slow_timer > 0:
		slow_timer -= delta
		if slow_timer <= 0:
			slow_multiplier = 1.0
	
	# Handle DoT effects (poison + burn)
	dot_tick_timer += delta
	if dot_tick_timer >= 0.5:  # Tick every 0.5 seconds
		dot_tick_timer -= 0.5
		var dot_total: float = 0.0
		if poison_timer > 0:
			poison_timer -= 0.5
			dot_total += poison_damage * 0.5
			animated_sprite.modulate = Color(0.6, 1.0, 0.6, 1)  # Green tint
		if burn_timer > 0:
			burn_timer -= 0.5
			dot_total += burn_damage * 0.5
			animated_sprite.modulate = Color(1.0, 0.7, 0.5, 1)  # Orange tint
		if dot_total > 0:
			health -= int(dot_total)
			health_bar.value = health
			if health <= 0:
				die()
				return
		elif poison_timer <= 0 and burn_timer <= 0:
			animated_sprite.modulate = Color(1, 1, 1, 1)  # Reset tint
	
	# Move along path
	var path_follow = get_parent() as PathFollow2D
	if path_follow:
		var prev_pos = path_follow.global_position
		path_follow.progress += speed * slow_multiplier * delta
		var new_pos = path_follow.global_position
		
		# Determine facing direction based on movement and sprite's default facing
		var move_dir = new_pos - prev_pos
		var faces_right = default_faces_right.get(enemy_type, true)
		
		# Only update facing when there's clear horizontal dominance
		# Prevents flickering on diagonal/transitional movements
		if move_dir.length() > 0.1 and abs(move_dir.x) > abs(move_dir.y) * 1.5:
			var moving_right = move_dir.x > 0
			animated_sprite.flip_h = (moving_right != faces_right)
			last_h_facing_right = moving_right
		# When moving vertically or diagonally, keep the last horizontal flip state
		
		# Check if reached the end
		if path_follow.progress_ratio >= 1.0:
			GameManager.enemy_reached_end()
			reached_end.emit()
			queue_free()

func take_damage(amount: int):
	health -= amount
	health_bar.value = health
	AudioManager.play_sfx("enemy_hit", -6.0)
	
	# Flash white on hit
	animated_sprite.modulate = Color(2, 2, 2, 1)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		animated_sprite.modulate = Color(1, 1, 1, 1)
	
	if health <= 0:
		die()

func apply_slow(amount: float, duration: float):
	slow_multiplier = amount
	slow_timer = duration

func apply_poison(damage: float, duration: float):
	poison_damage = damage
	poison_timer = duration

func apply_burn(damage: float, duration: float):
	burn_damage = damage
	burn_timer = duration

func _get_death_sound() -> String:
	match enemy_type:
		"brute_demon", "bone_golem", "tank":
			return "enemy_death_ogre"
		"wraith", "shadow_stalker":
			return "enemy_death_shade"
		_:
			return "enemy_death"

func die():
	GameManager.enemy_killed(reward)
	AudioManager.play_sfx(_get_death_sound())
	AudioManager.play_sfx("gold_pickup", -4.0)
	# Spawn death effect and gold text
	GameParticles.spawn_death_poof(get_tree(), global_position)
	GameParticles.spawn_gold_text(get_tree(), global_position, reward)
	died.emit()
	queue_free()
