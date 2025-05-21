extends AnimatedSprite2D

const INERTIA = pow(.992, 120)

@export var velocity := Vector2()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += velocity * delta
	velocity *= pow(INERTIA, delta)

func _on_animation_finished() -> void:
	queue_free()
