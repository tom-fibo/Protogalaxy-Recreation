extends AnimatedSprite2D

class_name Projectile

const PROJ_INERTIA = 1.001

@export var velocity := Vector2()
var shooter
@export var lifespan := 15.0
@export var explodes := false
var active = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += velocity * delta
	velocity *= PROJ_INERTIA
	lifespan -= delta
	if lifespan < 0:
		queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.get_parent().get_parent() != shooter:
		if explodes:
			for i in range(8):
				var angle = i*PI/8
				var chain_bullet : AnimatedSprite2D = preload("res://projectile.tscn").instantiate()
				$/root/Space.add_child(chain_bullet)
				chain_bullet.position = position
				chain_bullet.rotation = rotation + angle
				chain_bullet.velocity = velocity + Vector2.RIGHT.rotated(angle)*40
				chain_bullet.shooter = shooter
		queue_free()
