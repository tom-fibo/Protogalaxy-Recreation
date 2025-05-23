extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("zoom_in"):
		Global.camera_zoom *= pow(2, delta)
	if Input.is_action_pressed("zoom_out"):
		Global.camera_zoom *= pow(.5, delta)
	if Input.is_action_just_pressed("restart"):
		get_tree().change_scene_to_file("res://ship_editor.tscn")
