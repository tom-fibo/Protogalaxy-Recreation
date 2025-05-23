extends Node2D

class_name Ship

const SPACE_FRICTION = pow(.995,120)
const SPACE_ROT_FRICTION = pow(.5,120)
const ENGINE_POWER = 2.1*120
const CANNON_FIRE_VELOCITY = 600
const CANNON_FIRE_MASS = 0.3
const MISSILE_VELOCITY = 200
const MISSILE_MASS = 3
const INERTIA = 0.075
const ROT_INERTIA = 0.02

const CANNON_COOLDOWN = 1.0
const SHIELD_COOLDOWN = 2.0
const SOLAR_PANEL_COOLDOWN = 15.0
const MISSILE_COOLDOWN = 1.5

enum Set_Ship_Options {NONE, PLAYER, ENEMY, DEFAULT}
enum Ship_State {NONE, EDITOR, PLAYER, ENEMY, MISSILE, NOAI}

@export var state : Ship_State = Ship_State.NONE
@export var set_ship : Set_Ship_Options = Set_Ship_Options.NONE
@export var target : Ship
@export var camera_enabled = false

@export var ship_spacing := 7
var active : bool

@export var ship : Array[Array] = [
	["frame", "frame", "frame"],
	["frame", "core",  "frame"],
	["frame", "frame", "frame"],
]
var ship_elements : Array[Array]
var ship_mass := 5
var ship_center_of_mass := Vector2()
var ship_moment_of_inertia := 0.0
var engine_directions := {}

var dont_update := 0

var velocity := Vector2()
var rot_velocity := 0.0
var velocity_change := Vector2()
var rot_velocity_change := 0.0
var camera_velocity := Vector2()
var current_scene

var target_directions : Dictionary
var rot_error_integral := 0.0

var cannon_cooldown := 0.0
var shield_cooldown := 0.0
var solar_panel_cooldown := 0.0
var cluster_cooldown := 0.0
var missile_cooldown := 0.0
var engine_fire := {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	active = not (state == Ship_State.EDITOR or state == Ship_State.NONE)
	if set_ship == Set_Ship_Options.PLAYER and not Global.player_ship:
		%InfoPanel.set_text("Use " + Global.keybind("select_part") + " to select a ship part,\nthen click a spot on your ship\nto place it (X represents empty).\nUse " + Global.keybind("view_part_info") + " to view each part's effect.\nAfter starting, use " + Global.keybind("restart") + " to return to the editor.", Vector2(930, 903), 40, true)
		%Begin.visible = false
		set_ship = Set_Ship_Options.DEFAULT
	match set_ship:
		Set_Ship_Options.PLAYER:
			ship = Global.player_ship.duplicate(true)
		Set_Ship_Options.ENEMY:
			gen_ship(3, 1)
		Set_Ship_Options.DEFAULT:
			gen_ship(Global.player_ship_size, -1)
	var scale_down = 1
	if state == Ship_State.EDITOR:
		while ship_spacing*15*scale_down*len(ship) > 800:
			scale_down *= .9
		ship_spacing *= scale_down
	ship_elements = []
	for y in range(len(ship)):
		var ship_row = []
		for x in range(len(ship[y])):
			var new_element : Ship_Element = preload("res://ship_element.tscn").instantiate()
			new_element.x = x - ((len(ship[y])-1)/2)
			new_element.y = y - ((len(ship)-1)/2)
			new_element.state = Ship_Element.Ship_Element_State.ONSHIP
			new_element.scale = Vector2(15, 15) * scale_down
			add_child(new_element)
			ship_row.append(new_element)
		ship_elements.append(ship_row)
	$"Camera2D".enabled = camera_enabled
	if active:
		split_ship()
		for loc in locate_part_in_ship(["engine", "backwardengine", "missile"]):
			var fire = preload("res://engine_fire.tscn").instantiate()
			add_child(fire)
			fire.position = loc*15*ship_spacing
			if read_ship(loc.x, loc.y) == "backwardengine":
				fire.rotate(PI)
			fire.visible = false
			engine_fire[loc] = fire

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if active:
		target_directions = get_target_directions(delta)
		
		#Attack
		cannon_cooldown -= delta
		if cannon_cooldown <= 0 and target_directions.shoot:
			var cannons = locate_part_in_ship("cannon")
			for loc in cannons:
				launch_projectile(loc, Vector2(0, -CANNON_FIRE_VELOCITY))
				apply_force(Vector2(0, CANNON_FIRE_VELOCITY)*CANNON_FIRE_MASS, loc, false, true)
			var ucannons = locate_part_in_ship("underbelly")
			for loc in ucannons:
				if randf() < .8:
					var dir = Vector2(0, CANNON_FIRE_VELOCITY*randf_range(-1,-.6)) \
							.rotated(randfn(0, .8))
					launch_projectile(loc, dir)
					apply_force(-dir*CANNON_FIRE_MASS, loc, false, true)
			cannon_cooldown = CANNON_COOLDOWN
		
		#Cluster Attack
		cluster_cooldown -= delta
		if cluster_cooldown <= 0 and target_directions.cluster:
			for loc in locate_part_in_ship("cluster"):
				if not spend_power(2):
					break
				var cluster_bullet = launch_projectile(loc, Vector2(0, -2*CANNON_FIRE_VELOCITY))
				apply_force(Vector2(0, 2*CANNON_FIRE_VELOCITY)*2*CANNON_FIRE_MASS, loc, false, true)
				cluster_bullet.play("ClusterShot")
				cluster_bullet.explodes = true
				cluster_bullet.lifespan *= 2
			cluster_cooldown = CANNON_COOLDOWN
		
		#Launch missile
		missile_cooldown -= delta
		if missile_cooldown <= 0 and target_directions.missile:
			for loc in locate_part_in_ship("missilelauncher"):
				if not (target and spend_power(2)):
					break
				var missile : Ship = preload("res://ship.tscn").instantiate()
				missile.position = position + (loc+Vector2(0,-1)).rotated(rotation)*15*ship_spacing
				missile.rotation = rotation
				missile.velocity = velocity + Vector2(0, -MISSILE_VELOCITY).rotated(rotation)
				missile.ship = [["missile"]]
				missile.state = Ship_State.ENEMY
				missile.target = target
				get_parent().add_child(missile)
				apply_force(Vector2(0, MISSILE_VELOCITY)*MISSILE_MASS, loc, false, true, 0.5)
			missile_cooldown = MISSILE_COOLDOWN
		
		#Defend
		shield_cooldown -= delta
		if shield_cooldown <= 0 and target_directions.shield:
			for shield_loc in locate_part_in_ship("shield"):
				if not spend_power():
					break
				var shield = preload("res://projected_shield.tscn").instantiate()
				add_child(shield)
				shield.source = self
				var shield_direction = (shield_loc-ship_center_of_mass).normalized()
				if shield_direction.is_zero_approx():
					shield_direction = Vector2(0, -1)
				shield.set_direction(shield_direction.angle())
				var check_loc : Vector2 = shield_loc
				while read_ship(roundi(check_loc.x), roundi(check_loc.y)) != "none":
					check_loc += shield_direction
				shield.position = check_loc*15*ship_spacing - shield_direction*30*ship_spacing
			shield_cooldown = SHIELD_COOLDOWN
		
		#Move
		for fire_loc in engine_fire:
			engine_fire[fire_loc].visible = false
		var engine_key = ""
		if target_directions.forward:
			engine_key = "up"
		elif target_directions.backward:
			engine_key = "down"
		if target_directions.left:
			engine_key = engine_key + "left"
		elif target_directions.right:
			engine_key = engine_key + "right"
		if engine_key in engine_directions:
			for loc in engine_directions[engine_key]:
				var engine_direction = Vector2.UP
				var loc_offset = Vector2()
				var rotation_mult = 8
				if read_ship(loc.x, loc.y) == "backwardengine":
					engine_direction = Vector2.DOWN
				if read_ship(loc.x, loc.y) == "missile":
					if target_directions.left:
						loc_offset.x += 0.5
						rotation_mult *= .00005
					if target_directions.right:
						loc_offset.x -= 0.5
						rotation_mult *= .00005
				if loc in engine_fire:
					engine_fire[loc].visible = true
				apply_force(engine_direction*ENGINE_POWER*delta, loc+loc_offset, false, true, rotation_mult)
		position += velocity * delta
		#goal: <x, y> goes to CoM + (<x,y>-CoM).rotated
		#actual: <x, y> goes to <x, y>.rotated
		#goal = CoM + <x,y>.rotated - CoM.rotated
		#add CoM-CoM.rotated
		position += ship_center_of_mass.rotated(rotation) - ship_center_of_mass.rotated(rotation+rot_velocity*delta)
		rotation += rot_velocity * delta
		velocity *= pow(SPACE_FRICTION, delta)
		rot_velocity *= pow(SPACE_ROT_FRICTION, delta)
		velocity += velocity_change
		rot_velocity += rot_velocity_change
		velocity_change = Vector2()
		rot_velocity_change = 0
		
		#Recharge
		solar_panel_cooldown -= delta * len(locate_part_in_ship("solar"))
		if solar_panel_cooldown <= 0:
			spend_power(-1)
			solar_panel_cooldown = SOLAR_PANEL_COOLDOWN
		
		#Adjust camera
		$"Camera2D".position += camera_velocity * delta
		camera_velocity = camera_velocity.move_toward(ship_center_of_mass - $"Camera2D".position, 1000*delta)
		$"Camera2D".zoom = Vector2(Global.camera_zoom, Global.camera_zoom)

func gen_ship(size : int, difficulty : int) -> void:
	ship = []
	for y in range(size):
		var ship_row = []
		for x in range(size):
			var ele = "frame"
			if difficulty == -1:
				ele = "none"
			if x*2 == size-1 and y*2 == size-1:
				ele = "core"
			elif difficulty > 0:
				ele = "battery1"
				if randf() < .2:
					ele = "volatile2"
				if randf() < .3:
					ele = "solar"
				if randf() < .6:
					ele = "reflector"
				if randf() < .3:
					ele = "underbelly"
				if y == 0:
					ele = "cannon"
					if randf() < .05:
						ele = "cluster"
					if randf() < .2:
						ele = "backwardengine"
				if y*2 == size-3 and x*2 == size-1 and randf() < .9:
					ele = "shield"
				if y == size-1:
					if randf() < .95:
						ele = "engine"
			ship_row.append(ele)
		ship.append(ship_row)

func apply_force(force : Vector2, relative_loc : Vector2, absolute_rotation := false, mult_loc := false, rot_mult := 1.0) -> void:
	if mult_loc:
		relative_loc *= 15 * ship_spacing
	if (not absolute_rotation):
		force = force.rotated(rotation)
		relative_loc = relative_loc.rotated(rotation)
	velocity_change += force / ship_mass / INERTIA
	rot_velocity_change += (relative_loc-ship_center_of_mass.rotated(rotation)).cross(force) / ship_moment_of_inertia / ROT_INERTIA * rot_mult

func spend_power(amount := 1) -> bool:
	var batteries : Array = locate_part_in_ship("battery"+str(1 if amount>0 else 0))
	var double = locate_part_in_ship("volatile"+str(2 if amount>0 else 0))
	batteries.append_array(double)
	batteries.append_array(double)
	batteries.append_array(locate_part_in_ship("volatile1"))
	batteries.sort_custom(func(a, b): \
			return a[0]*a[0] + a[1]*a[1] > b[0]*b[0] + b[1]*b[1])
	if len(batteries) < amount:
		return false
	for i in range(min(abs(amount),len(batteries))):
		var loc = batteries[i]
		var old_battery = read_ship(loc[0],loc[1])
		write_ship(old_battery.substr(0,len(old_battery)-1) + str(int(old_battery[-1]) + (-1 if amount>0 else 1)), loc[0], loc[1])
		update_part(loc[0], loc[1])
	return true

func split_ship():
	var groups = []
	var used_cells = {}
	for y in range(len(ship)):
		for x in range(len(ship[0])):
			if Vector2(x, y) in used_cells or ship[y][x] == "none":
				continue
			var group : PackedVector2Array = []
			var tocheck = [Vector2(x, y)]
			while len(tocheck) > 0:
				var curcheck = tocheck.pop_back()
				if curcheck.x < 0 or curcheck.y < 0 or curcheck.y >= len(ship) or curcheck.x >= len(ship[0]):
					continue
				if not curcheck in used_cells and ship[curcheck.y][curcheck.x] != "none":
					group.append(curcheck)
					used_cells[curcheck] = 1
					for offset in [Vector2.UP, Vector2(-1, -1), Vector2.LEFT, Vector2(-1, 1), Vector2.DOWN, Vector2(1, 1), Vector2.RIGHT, Vector2(1, -1)]:
						tocheck.append(curcheck + offset)
			groups.append(group)
	print(len(groups))
	while len(groups) > 1:
		var new_ship_blocks = groups.pop_back()
		var new_ship = preload("res://ship.tscn").instantiate()
		new_ship.state = state
		new_ship.ship = ship.duplicate(true)
		new_ship.camera_enabled = true
		for y in range(len(ship)):
			for x in range(len(ship[0])):
				if Vector2(x, y) in new_ship_blocks:
					if x>=0 and y>=0 and y<len(ship_elements) and x<len(ship_elements[y]) and ship_elements[y][x]:
						ship_elements[y][x].type("none")
				else:
					new_ship.ship[y][x] = "none"
		new_ship.position = position
		new_ship.velocity = velocity
		new_ship.rotation = rotation
		new_ship.rot_velocity = rot_velocity
		new_ship.target_directions = target_directions
		$"/root/Space/".add_child.call_deferred(new_ship)
	if len(groups) == 0:
		queue_free()
		return
	update_mass()

func update_mass() -> void:
	ship_mass = 0
	ship_moment_of_inertia = 1
	ship_center_of_mass = Vector2()
	for c in range(len(ship)):
		for r in range(len(ship[c])):
			var loc = Vector2(r-(len(ship[0])-1)/2, c-(len(ship)-1)/2)
			var part = read_ship(loc.x, loc.y)
			var part_mass = 1
			match part:
				"core":
					part_mass = 5
				"none":
					part_mass = 0
			ship_mass += part_mass
			ship_center_of_mass += loc * 15 * ship_spacing * part_mass
	if ship_mass > 0:
		ship_center_of_mass /= ship_mass
	for c in range(len(ship)):
		for r in range(len(ship[c])):
			var loc = Vector2(r-(len(ship[0])-1)/2, c-(len(ship)-1)/2)
			var part = read_ship(loc.x, loc.y)
			var part_mass = 1
			match part:
				"core":
					part_mass = 5
				"none":
					part_mass = 0
			ship_moment_of_inertia += (loc*15*ship_spacing-ship_center_of_mass).length_squared() * part_mass
	calc_engine_directions()

func calc_engine_directions() -> void:
	if len(locate_part_in_ship(["core", "missile"])) < 0:
		return
	var engines := locate_part_in_ship(["engine", "backwardengine", "missile"])
	engine_directions = {}
	for dir in ["up","upright","right","downright","down","downleft","left","upleft"]:
		engine_directions[dir] = []
	if len(engines) == 0:
		return
	var engine_forces = []
	var engine_rot_forces = []
	var engines_sorted_by_direction = []
	var sorted_rot_forces = []
	for i in range(len(engines)):
		var engine_loc = engines[i]
		var engine_force = -1
		if read_ship(engine_loc.x, engine_loc.y) == "backwardengine":
			engine_force = 1
		var engine_rot_force = (engine_loc - ship_center_of_mass/15/ship_spacing) \
				.cross(Vector2(0, engine_force))
		var rot_index = binsearch(engine_rot_force, sorted_rot_forces)
		sorted_rot_forces.insert(rot_index,engine_rot_force)
		engines_sorted_by_direction.insert(rot_index,i)
		engine_forces.append(engine_force)
		engine_rot_forces.append(engine_rot_force)
		#left / right: focus on relative to "center of mass" of <rot_direction, direction>
		#forward / backward: maximize movement
		#sideways: focus forward/backward, add/remove engines if they make a big (relative) impact to rotation at a low (relative) impact to speed
		if engine_rot_force > 0.1:
			engine_directions["right"].append(engine_loc)
		elif engine_rot_force < -0.1:
			engine_directions["left"].append(engine_loc)
		if engine_force < -0.01:
			engine_directions["up"].append(engine_loc)
		elif engine_force > 0.01:
			engine_directions["down"].append(engine_loc)
	if len(engine_directions["right"]) == 0:
		engine_directions["right"].append(engines[engines_sorted_by_direction[-1]])
	if len(engine_directions["left"]) == 0:
		engine_directions["left"].append(engines[engines_sorted_by_direction[0]])
	var diagonal_up_engines = int((len(engine_directions["up"])-1)*.75 +1)
	var diagonal_down_engines = int((len(engine_directions["down"])-1)*.75 +1)
	var remaining_up_engines = diagonal_up_engines
	var remaining_down_engines = diagonal_down_engines
	for i in engines_sorted_by_direction:
		if engine_forces[i] < 0 and remaining_up_engines > 0:
			engine_directions["upleft"].append(engines[i])
			remaining_up_engines -= 1
		elif engine_forces[i] > 0 and remaining_down_engines > 0:
			engine_directions["downleft"].append(engines[i])
			remaining_down_engines -= 1
	remaining_up_engines = diagonal_up_engines
	remaining_down_engines = diagonal_down_engines
	for i in range(len(engines_sorted_by_direction)):
		i = engines_sorted_by_direction[-1-i]
		if engine_forces[i] < 0 and remaining_up_engines > 0:
			engine_directions["upright"].append(engines[i])
			remaining_up_engines -= 1
		elif engine_forces[i] > 0 and remaining_down_engines > 0:
			engine_directions["downright"].append(engines[i])
			remaining_down_engines -= 1

func get_target_directions(delta := 0) -> Dictionary:
	if len(locate_part_in_ship(["core", "missile"])) == 0:
		if target_directions:
			return target_directions
	var default_directions = {
		"forward": false,
		"backward": false,
		"left": false,
		"right": false,
		"shoot": false,
		"shield": false,
		"cluster": false,
		"missile": false,
	}
	var dist = 0
	var angle_to_target = 0
	var abs_angle_to_target = 0
	var predicted_angle = 0
	var rot_total = 0
	if not target:
		if state == Ship_State.ENEMY or state == Ship_State.PLAYER:
			var nearest_ship = null
			var nearest_distance = -1
			var target_type = Ship_State.ENEMY
			if state == Ship_State.ENEMY:
				target_type = Ship_State.PLAYER
			for child in get_parent().get_children():
				if child is Ship and child.state == target_type and \
						(nearest_distance < 0 or (position - child.position).length_squared()<nearest_distance):
					nearest_distance = (position - child.position).length_squared()
					nearest_ship = child
			target = nearest_ship
	if target:
		dist = position.distance_to(target.position)
		angle_to_target = fmod((position.angle_to_point(target.position)) - rotation + PI + PI/2, TAU) - PI
		rot_error_integral += angle_to_target * delta
		abs_angle_to_target = abs(angle_to_target)
		predicted_angle = angle_to_target + (rot_velocity / -log(ROT_INERTIA))
		rot_total = predicted_angle + rot_error_integral/20 + rot_velocity / 5
	match state:
		Ship_State.PLAYER:
			return {
				"forward": Input.is_action_pressed("thrust_forward"),
				"backward": Input.is_action_pressed("thrust_backward"),
				"left": Input.is_action_pressed("thrust_left"),
				"right": Input.is_action_pressed("thrust_right"),
				"shoot": Input.is_action_pressed("shoot_cannons"),
				"shield": Input.is_action_pressed("activate_shields"),
				"cluster": Input.is_action_pressed("shoot_cluster"),
				"missile": Input.is_action_pressed("shoot_missile"),
			}
		Ship_State.ENEMY:
			if not target:
				return default_directions
			return {
				"forward": (dist>1350 and abs_angle_to_target<PI/4) or (dist<1000 and abs_angle_to_target>PI/2),
				"backward":dist<750 and abs_angle_to_target<PI/4,
				"left": rot_total<-.5,
				"right":rot_total> .5,
				"shoot": dist*abs_angle_to_target<1000*PI and abs_angle_to_target<1.5*PI,
				"shield": abs_angle_to_target < 1 and dist < 1500,
				"cluster": dist<1250 and abs_angle_to_target<PI/8,
				"missile": true,
			}
		Ship_State.MISSILE:
			if not target:
				return default_directions
			return {
				"forward": abs(angle_to_target)<PI/4 or dist<500,
				"backward":false,
				"left": rot_total<-.6,
				"right":rot_total> .6,
				"shoot": true,
				"shield": false,
				"cluster": true,
				"missile": true,
			}
		_:
			return default_directions

func launch_projectile(ship_loc : Vector2, velocity_addition : Vector2) -> Projectile:
	var proj = preload("res://projectile.tscn").instantiate()
	$/root/Space.add_child(proj)
	proj.position = global_position + \
			(ship_loc*15*ship_spacing).rotated(rotation)
	proj.rotation = rotation
	proj.velocity = velocity/2 + velocity_addition.rotated(rotation)
	proj.shooter = self
	return proj

func locate_part_in_ship(part) -> PackedVector2Array:
	var parts = PackedVector2Array()
	for c in range(len(ship)):
		for r in range(len(ship[c])):
			if (part is String and ship[c][r] == part) or (part is Array and ship[c][r] in part):
				parts.append(Vector2(r-(ship[0].size()-1)/2, c-(ship.size()-1)/2))
	return parts

func binsearch(val, arr : Array) -> int:
	#first index in arr which is larger than val
	var min = 0
	var max = len(arr)
	while min < max:
		var mid = int((min+max)/2)
		if val >= arr[mid]:
			min = mid + 1
		else:
			max = mid
	return min

func expand_ship(x : int, y : int) -> void:
	var missing_ship_height = abs(y) - (ship.size()-1)/2
	if missing_ship_height > 0:
		var ship_width = ship[0].size()
		for i in range(missing_ship_height):
			var new_row = []
			new_row.resize(ship_width)
			new_row.fill("none")
			ship.append(new_row)
			new_row = []
			new_row.resize(ship_width)
			new_row.fill("none")
			ship.insert(0, new_row)
	var missing_ship_width = abs(x) - (ship[0].size()-1)/2
	if missing_ship_width > 0:
		for i in range(ship.size()):
			var new_left = []
			new_left.resize(missing_ship_width)
			new_left.fill("none")
			var new_right = []
			new_right.resize(missing_ship_width)
			new_right.fill("none")
			ship[i] = new_left + ship[i] + new_right

func get_element(x : int, y : int) -> Ship_Element:
	if read_ship(x, y) == "none":
		return null
	y += (len(ship_elements)-1)/2
	x += (len(ship_elements[0])-1)/2
	return ship_elements[y][x]

func read_ship(x : int, y : int) -> String:
	expand_ship(x, y)
	return ship[y + (ship.size()-1)/2][x + (ship[0].size()-1)/2]

func write_ship(val : String, x : int, y : int) -> void:
	expand_ship(x, y)
	ship[y + (ship.size()-1)/2][x + (ship[0].size()-1)/2] = val

func update_part(x : int, y : int) -> void:
	for child in get_children():
		if "state" in child and child.state == Ship_Element.Ship_Element_State.ONSHIP:
			if child.x == x and child.y == y:
				child.update_texture()
