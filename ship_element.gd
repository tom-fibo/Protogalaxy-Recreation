extends Sprite2D

class_name Ship_Element

enum Ship_Element_State {NONE, ONSHIP, PALATE}

@export var x := 0
@export var y := 0
@export var state : Ship_Element_State = Ship_Element_State.NONE
@export var internal_type := ""

var my_ship : Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	my_ship = get_parent()
	if state == Ship_Element_State.PALATE or my_ship.state == Ship.Ship_State.EDITOR:
		var expanded_shape = RectangleShape2D.new()
		expanded_shape.size = Vector2(8, 8)
		$"Area2D/CollisionShape2D".shape = expanded_shape
	elif type() == "missile":
		var mini_shape = RectangleShape2D.new()
		mini_shape.size = Vector2(5, 5)
		$"Area2D/CollisionShape2D".shape = mini_shape
	update_texture()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func type(new_type : String = ""):
	if state == Ship_Element_State.ONSHIP:
		if new_type == "":
			return my_ship.read_ship(x, y)
		my_ship.write_ship(new_type, x, y)
		update_texture()
	else:
		if new_type == "":
			return internal_type
		internal_type = new_type
		update_texture()

func update_texture():
	if state == Ship_Element_State.ONSHIP:
		set_position(Vector2(x*my_ship.ship_spacing*15, y*my_ship.ship_spacing*15))
	if type() == "none":
		if state == Ship_Element_State.PALATE or my_ship.state == Ship.Ship_State.EDITOR:
			if state == Ship_Element_State.ONSHIP:
				texture = preload("res://Assets/Images/ShipElements/EmptyPart.png")
			else:
				texture = preload("res://Assets/Images/ShipElements/ClearPart.png")
			return
		queue_free()
	texture = Global.PART_TEXTURES[type()]

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("select_part"):
		match state:
			Ship_Element_State.ONSHIP:
				if my_ship.state == Ship.Ship_State.EDITOR:
					var new_type = $"../%Palate".selected_ship_element
					if new_type == "":
						return
					if new_type == "engine" and my_ship.read_ship(x, y+1) != "none":
						new_type = "backwardengine"
					if (new_type == "cannon" || new_type == "backwardengine" ) and my_ship.read_ship(x, y-1) != "none":
						return
					if type() == "none":
						if my_ship.read_ship(x, y-1) == "engine":
							my_ship.get_element(x, y-1).type("frame")
						var above = my_ship.read_ship(x, y+1)
						if above == "cannon" or above == "backwardengine":
							my_ship.get_element(x, y+1).type("frame")
					type(new_type)
				update_texture()
			Ship_Element_State.PALATE:
				my_ship.selected_ship_element = type()
				my_ship.selected_indicator.set_position(position) #get_node("/root/Ship_Editor/SelectedIndicator")
	elif event.is_action_pressed("view_part_info"):
		if state == Ship_Element_State.PALATE or my_ship.state == Ship.Ship_State.EDITOR:
			var part_info = "Part info not found!"
			if type() in Global.PART_DESCRIPTIONS:
				part_info = Global.PART_DESCRIPTIONS[type()]
			$"../%InfoPanel".set_text(part_info, global_position + Vector2(4.5*15, -3.5*15))
			$"../%Palate".selected_ship_element = ""
			$"../%Palate".selected_indicator.position = Vector2(10000, 10000)

func _on_area_2d_area_entered(area: Area2D) -> void:
	destroy_self(area)

func destroy_self(area: Area2D = null):
	if area:
		var area_parent = area.get_parent()
		if "shooter" in area_parent and area_parent.shooter == my_ship:
			return
		if "source" in area_parent and area_parent.source == my_ship:
			return
		var area_ship = area_parent.get_parent()
		if area_ship == my_ship:
			return
		if "active" in area_parent:
			if not area_parent.active:
				return
			area_parent.active = false
		if (type() == "reflector") and ("shooter" in area_parent):
			var proj = preload("res://projectile.tscn").instantiate()
			$/root/Space.add_child(proj)
			if area_parent.animation == "ClusterShot" or area_parent.animation == "ClusterSplit":
				proj.play("ClusterSplit")
			proj.position = global_position
			proj.velocity = 1200 * (area_parent.shooter.global_position+area_parent.shooter.ship_center_of_mass-my_ship.global_position).normalized()
			proj.rotation = proj.velocity.angle()+PI/2
			proj.shooter = my_ship
			
			#Old bounce (didn't work)
			#var proj_vel = area_parent.velocity - my_ship.velocity
			#var proj_angle = abs(global_position.angle_to_point(area_parent.global_position) - my_ship.rotation)
			#var reflect_axis = Vector2(0, 1)
			#if (proj_angle >= PI/4 and proj_angle <= 3*PI/4):
			#	reflect_axis = Vector2(1, 0)
			#proj_vel = proj_vel.reflect(reflect_axis.rotated(my_ship.rotation))
			#my_ship.launch_projectile([x, y], proj_vel)
			#if randf() < .9:
				#return
		if "source" in area_parent:
			var pos_offset = my_ship.position - area_ship.position
			var vel_offset = my_ship.velocity - area_ship.velocity
			vel_offset = vel_offset.project(pos_offset)*((my_ship.ship_mass+area_ship.ship_mass)/2)
			#vel_offset += vel_offset.normalized() * 20
			area_ship.velocity += vel_offset/area_ship.ship_mass
			my_ship.velocity -= vel_offset/my_ship.ship_mass
			area_parent.queue_free()
	var explosion = preload("res://destroyed_explosion.tscn").instantiate()
	$/root/Space.add_child(explosion)
	explosion.position = global_position
	explosion.rotation = global_rotation
	explosion.velocity = my_ship.velocity
	var old_type = type()
	my_ship.write_ship("none", x, y)
	if old_type.ends_with("engine"):
		my_ship.engine_fire[Vector2(x, y)].queue_free()
		my_ship.engine_fire.erase(Vector2(x, y))
	if old_type.begins_with("volatile"):
		explosion.play("explosion")
		explosion.z_index = 1
		my_ship.dont_update += 1
		await get_tree().create_timer(0.1).timeout
		for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
			var element = my_ship.get_element(x+direction.x, y+direction.y)
			if element and element.is_processing():
				element.destroy_self(null)
		my_ship.dont_update -= 1
	if my_ship.dont_update == 0:
		my_ship.split_ship()
	queue_free()
