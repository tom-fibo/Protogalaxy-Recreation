extends Panel

var cooldown := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	cooldown -= delta
	if Input.is_action_just_pressed("select_part") or Input.is_action_just_pressed("view_part_info"):
		if cooldown <= 0:
			position = Vector2(10000, 10000)
