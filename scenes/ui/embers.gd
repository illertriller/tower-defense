extends Node2D

## Floating ember particles for atmospheric menus

var particles: Array = []

func _ready():
	for i in range(30):
		particles.append({
			"pos": Vector2(randf() * 1280, randf() * 720),
			"speed": randf_range(10, 40),
			"size": randf_range(1.5, 4.0),
			"alpha": randf_range(0.2, 0.7),
			"drift": randf_range(-15, 15),
			"color": Color(1.0, randf_range(0.3, 0.7), 0.1)
		})

func _process(delta: float):
	for p in particles:
		p["pos"].y -= p["speed"] * delta
		p["pos"].x += p["drift"] * delta
		p["alpha"] += randf_range(-0.5, 0.5) * delta
		p["alpha"] = clampf(p["alpha"], 0.1, 0.8)
		
		if p["pos"].y < -10:
			p["pos"].y = 730
			p["pos"].x = randf() * 1280
	
	queue_redraw()

func _draw():
	for p in particles:
		var color = p["color"]
		color.a = p["alpha"]
		draw_circle(p["pos"], p["size"], color)
