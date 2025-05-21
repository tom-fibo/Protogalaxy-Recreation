extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var star_texture = load("res://Assets/Images/BackgroundElements/Star.png")
	var objects = [
		{"scale": 0.5, "size_max": Vector2(1600,1600), "texture": load("res://Assets/Images/BackgroundElements/Earth.png")},
		{"scale": 0.65, "size_max": Vector2(2000,2000), "texture": load("res://Assets/Images/BackgroundElements/Moon.png")},
		{"scale": 0.55, "size_max": Vector2(1600,1600), "texture": load("res://Assets/Images/BackgroundElements/Mars.png")},
		{"scale": 0.45, "size_max": Vector2(1600,1600), "texture": load("res://Assets/Images/BackgroundElements/RingedPlanet.png")},
		{"scale": 0.35, "size_max": Vector2(1200,1200), "texture": load("res://Assets/Images/BackgroundElements/Sun.png")},
		{"scale": 0.3, "size_max": Vector2(1200,1200), "texture": load("res://Assets/Images/BackgroundElements/BlackHole.png")},
		#{"scale": 0.2, "size": Vector2(960, 720), "texture": load("res://Assets/Images/BackgroundElements/StarBackground.png")},
	]
	for i in range(400):
		objects.append({
			"scale": randf_range(0.05,0.3), "size_max": Vector2(500,500), "texture": star_texture,
		})
	for object in objects:
		object.scale *= randf_range(1.2,0.8)
		var bgobject = preload("res://background_object.tscn").instantiate()
		var bgtexture = bgobject.get_child(0)
		add_child(bgobject)
		bgtexture.texture = object.texture
		bgobject.scroll_scale = Vector2(object.scale,object.scale)
		bgtexture.scale = Vector2(5,5)
		if "size" in object:
			bgobject.repeat_size = object.size * bgtexture.scale
		else:
			bgobject.repeat_size = Vector2(randf_range(360,object.size_max.x),randf_range(360,object.size_max.y))*15
		bgobject.scroll_offset = Vector2(randf_range(0,bgobject.repeat_size.x),randf_range(0,bgobject.repeat_size.y))
		bgobject.z_index = -100 + object.scale*100

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
