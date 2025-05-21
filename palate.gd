extends Node2D

@export var selected_indicator : Sprite2D
var selected_ship_element = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var spawnpos := Vector2()
	for type in ["none", "frame", "core", "cannon", "underbelly", "engine", "reflector", "shield", "cluster", "battery1", "volatile2", "solar", "missilelauncher"]:
		var new_element = preload("res://ship_element.tscn").instantiate()
		new_element.state = Ship_Element.Ship_Element_State.PALATE
		new_element.type(type)
		new_element.update_texture()
		add_child(new_element)
		new_element.set_position(spawnpos)
		spawnpos += Vector2(0, 180)
		if spawnpos.y >= 960:
			spawnpos.y = 0
			spawnpos += Vector2(180, 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
