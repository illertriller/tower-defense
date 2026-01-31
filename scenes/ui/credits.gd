extends Control

## Credits roll — shown after beating the final level

@onready var credits_label: Label = $CreditsLabel
@onready var back_btn: Button = $BackBtn

var scroll_speed: float = 40.0

func _ready():
	back_btn.pressed.connect(_on_back)
	
	credits_label.text = """




TOWER DEFENSE
Demons from Hell



— CREATED BY —

Martin
Creative Director



— BUILT BY —

EDI
Lead Developer & Architect



— ART BY —

Leonard of Quirm
Pixel Art & Design Specialist
(Named after Terry Pratchett's character)



— TOOLS —

Godot Engine 4.6
PixelLab AI (Sprite Generation)
Clawdbot (AI Assistant Platform)



— SPECIAL THANKS —

Terry Pratchett
For Discworld and all the inspiration

Martin's Brother
First playtester — loved it



— MUSIC —

Coming soon...



— BUILT IN —

Under 48 hours
From zero to full game



Thank you for playing!




"""
	
	# Start credits off-screen at bottom
	credits_label.position.y = 720

func _process(delta: float):
	credits_label.position.y -= scroll_speed * delta
	
	# Reset when fully scrolled
	if credits_label.position.y + credits_label.size.y < -50:
		_on_back()

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
