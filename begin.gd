extends Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_button_down() -> void:
	var ship : Array[Array] = $"/root/Ship_Editor/Ship".ship
	var extra_height = len(ship) - Global.player_ship_size
	if extra_height > 0:
		ship = ship.slice(floori(extra_height/2), len(ship)-ceili(extra_height/2))
	var extra_width = len(ship[0]) - Global.player_ship_size
	if extra_width > 0:
		var low_bound = floori(extra_width/2)
		var high_bound = len(ship[0])-ceili(extra_width/2)
		for i in range(len(ship)):
			ship[i] = ship[i].slice(low_bound, high_bound)
	Global.player_ship = ship
	get_tree().change_scene_to_file("res://space.tscn")
