extends Sprite2D

var source
var active = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(2).timeout
	visible = false
	await get_tree().create_timer(0.2).timeout
	queue_free()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func set_direction(angle : float):
	var dir := roundi(angle/PI*4)
	if dir % 2 == 0:
		texture = preload("res://Assets/Images/OrthogonalShield.png")
		$Area2D/OrthogonalCollision.disabled = false
	else:
		texture = preload("res://Assets/Images/DiagonalShield.png")
		dir -= 1
		$Area2D/DiagonalCollision.disabled = false
	rotation = dir*PI/4 + PI/2
