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
var enemy_type: String = "basic"

# Enemy type data
var enemy_types: Dictionary = {
	"basic": {"health": 50, "speed": 80, "reward": 10},
	"fast": {"health": 30, "speed": 150, "reward": 15},
	"tank": {"health": 200, "speed": 40, "reward": 30},
	"boss": {"health": 500, "speed": 50, "reward": 100}
}

# Sprite sheet paths per type
var sprite_sheets: Dictionary = {
	"basic": "res://assets/sprites/enemies/basic_walk_sheet.png",
	"fast": "res://assets/sprites/enemies/fast_walk_sheet.png",
	"tank": "res://assets/sprites/enemies/tank_walk_sheet.png",
	"boss": "res://assets/sprites/enemies/basic_walk_sheet.png"  # reuse pig for boss for now
}

# Animation speeds per type (FPS)
var anim_speeds: Dictionary = {
	"basic": 6.0,
	"fast": 10.0,
	"tank": 4.0,
	"boss": 5.0
}

func setup(type: String):
	enemy_type = type
	if type in enemy_types:
		var data = enemy_types[type]
		max_health = data["health"]
		health = max_health
		speed = data["speed"]
		reward = data["reward"]

func _ready():
	health_bar.max_value = max_health
	health_bar.value = health
	
	# Load sprite sheet and create animation
	_setup_animation()

func _setup_animation():
	var frames = SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("walk")
	
	var sheet_path = sprite_sheets.get(enemy_type, sprite_sheets["basic"])
	var sheet_texture = load(sheet_path)
	
	if sheet_texture:
		var sheet_image = sheet_texture.get_image()
		var frame_width = 32
		var frame_height = 32
		var frame_count = sheet_image.get_width() / frame_width
		
		for i in range(frame_count):
			# Extract each frame from the sprite sheet
			var frame_image = Image.create(frame_width, frame_height, false, sheet_image.get_format())
			frame_image.blit_rect(sheet_image, Rect2i(i * frame_width, 0, frame_width, frame_height), Vector2i(0, 0))
			var frame_texture = ImageTexture.create_from_image(frame_image)
			frames.add_frame("walk", frame_texture)
		
		frames.set_animation_speed("walk", anim_speeds.get(enemy_type, 6.0))
		frames.set_animation_loop("walk", true)
	
	animated_sprite.sprite_frames = frames
	animated_sprite.play("walk")

func _process(delta: float):
	# Handle slow effect
	if slow_timer > 0:
		slow_timer -= delta
		if slow_timer <= 0:
			slow_multiplier = 1.0
	
	# Move along path
	var path_follow = get_parent() as PathFollow2D
	if path_follow:
		path_follow.progress += speed * slow_multiplier * delta
		
		# Check if reached the end
		if path_follow.progress_ratio >= 1.0:
			GameManager.enemy_reached_end()
			reached_end.emit()
			queue_free()

func take_damage(amount: int):
	health -= amount
	health_bar.value = health
	
	# Flash white on hit
	animated_sprite.modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		animated_sprite.modulate = Color(1, 1, 1, 1)
	
	if health <= 0:
		die()

func apply_slow(amount: float, duration: float):
	slow_multiplier = amount
	slow_timer = duration

func die():
	GameManager.enemy_killed(reward)
	died.emit()
	queue_free()
