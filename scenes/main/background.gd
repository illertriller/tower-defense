extends Node2D

## Draws continuous terrain background using procedural noise
## PRD: "Grass field as continuous background layer (NOT grid-tied squares/circles)"
## Each level has a unique terrain theme — no tile stamping

var terrain_texture: Texture2D

func _ready():
	var theme = LevelData.get_terrain_theme(GameManager.current_level)
	_generate_terrain(theme)
	queue_redraw()

func _generate_terrain(theme: Dictionary):
	# Generate at quarter resolution, scale up for smooth continuous look
	var w = 320
	var h = 180
	var img = Image.create(w, h, false, Image.FORMAT_RGB8)
	
	var noise = FastNoiseLite.new()
	noise.seed = GameManager.current_level * 42
	noise.frequency = 0.025
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	# Second noise layer for subtle detail
	var detail_noise = FastNoiseLite.new()
	detail_noise.seed = GameManager.current_level * 137
	detail_noise.frequency = 0.06
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	var base_color: Color = theme.grass
	var var_color: Color = theme.grass_var
	
	for x in range(w):
		for y in range(h):
			# Blend two noise layers for natural terrain variation
			var n1 = (noise.get_noise_2d(x, y) + 1.0) * 0.5
			var n2 = (detail_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var blend = clampf(n1 * 0.7 + n2 * 0.3, 0.0, 1.0)
			var color = base_color.lerp(var_color, blend)
			img.set_pixel(x, y, color)
	
	# Scale up to full resolution with bilinear interpolation for smoothness
	img.resize(1280, 720, Image.INTERPOLATE_BILINEAR)
	terrain_texture = ImageTexture.create_from_image(img)

func _draw():
	if terrain_texture:
		draw_texture(terrain_texture, Vector2.ZERO)
	else:
		# Fallback: solid color fill
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.28, 0.55, 0.22))
