extends Node2D

## Draws tiled grass background

var grass_texture: Texture2D

func _ready():
	grass_texture = load("res://assets/sprites/terrain/grass_tile.png")
	queue_redraw()

func _draw():
	if not grass_texture:
		return
	var tile_w = grass_texture.get_width()
	var tile_h = grass_texture.get_height()
	
	for x in range(0, 1280, tile_w):
		for y in range(0, 720, tile_h):
			draw_texture(grass_texture, Vector2(x, y))
