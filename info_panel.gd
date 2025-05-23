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
			%Begin.visible = true

func set_text(text: String, new_position: Vector2, font_size := 32, center := false) -> void:
	position = new_position
	cooldown = 0.1
	$Label.text = text
	$Label.add_theme_font_size_override("font_size", font_size)
	$Label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	$Label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER if center else VERTICAL_ALIGNMENT_TOP
	size = $Label.get_theme_font("font").get_multiline_string_size(text, 0, -1, font_size) + Vector2(0, (len(text.split("\n"))-1)*3)
	$ReferenceRect.size = size
	if center:
		position -= size/2
	if position.y + size.y + 30 > get_viewport().content_scale_size.y:
		position.y = get_viewport().content_scale_size.y - size.y - 30
