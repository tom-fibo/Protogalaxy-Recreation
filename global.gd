extends Node

var PART_TEXTURES = {
	"core": load("res://Assets/Images/ShipElements/Core.png"),
	"frame": load("res://Assets/Images/ShipElements/Frame.png"),
	"none": Image.create_empty(7, 7, false, Image.FORMAT_RGBA8),
	"cannon": load("res://Assets/Images/ShipElements/Cannon.png"),
	"engine": load("res://Assets/Images/ShipElements/Engine.png"),
	"backwardengine": load("res://Assets/Images/ShipElements/BackwardEngine.png"),
	"battery0": load("res://Assets/Images/ShipElements/Battery0.png"),
	"battery1": load("res://Assets/Images/ShipElements/Battery1.png"),
	"reflector": load("res://Assets/Images/ShipElements/Reflector.png"),
	"shield": load("res://Assets/Images/ShipElements/ShieldProjector.png"),
	"solar": load("res://Assets/Images/ShipElements/SolarPanel.png"),
	"underbelly": load("res://Assets/Images/ShipElements/UnderbellyCannon.png"),
	"volatile0": load("res://Assets/Images/ShipElements/VolatileBattery0.png"),
	"volatile1": load("res://Assets/Images/ShipElements/VolatileBattery1.png"),
	"volatile2": load("res://Assets/Images/ShipElements/VolatileBattery2.png"),
	"missilelauncher": load("res://Assets/Images/ShipElements/MissileLauncher.png"),
	"missile": load("res://Assets/Images/ShipElements/Missile.png"),
	"cluster": load("res://Assets/Images/ShipElements/ClusterFragmentGun.png"),
}
var PART_DESCRIPTIONS = {
	"core": "Core:\nThe center of command in your ship.\nAs long as one exists on your ship,\nyou can control your movement.\n\nWeight: 5",
	"frame": "Frame:\nAn empty spot, ready to be filled.\n\nWeight: 1",
	"none": "Empty:\nEmpty space. If a line of empty space\nsplits your ship (while building\nor during combat), it will seperate.\n\nWeight: 0",
	"cannon": "Cannon:\nFires when you press "+keybind("shoot_cannons")+", shooting a\nsimple projectile that can destroy enemy ship parts.\n\nCan't have another ship part directly above it.\n\nWeight: 1",
	"engine": "Engine:\nAllows you to control your ship's movement.\nUse "+keybind("thrust_forward")+keybind("thrust_left")+keybind("thrust_backward")+keybind("thrust_right")+" to drive your ship.\n\nCan't have another ship part directly below it.\nCan instead be placed backward as long as\nthere isn't another ship part directly above it.\n\nWeight: 1",
	"battery1": "Battery:\nStores 1 energy, which can power\nother components (such as shields).\n\nFunctions from anywhere on your ship.\n\nWeight: 1",
	"reflector": "Reflector Plating:\nIf hit by a bullet, reflects\nthat bullet directly back at\nthe enemy (but is still\ndestroyed in the process)\n\nWeight: 1",
	"shield": "Shield Projector:\nCreates a shield when you press "+keybind("activate_shields")+"\nthat destroys colliding projectiles.\nThe shield is projected just outside\nof your ship, covering around 3 blocks.\n\nExpends 1 energy per shield.\n\nWeight: 1",
	"solar": "Solar Panel:\nRefills 1 energy to your batteries\nevery "+str(int(Ship.SOLAR_PANEL_COOLDOWN))+" seconds. Requires batteries\non your ship to function.\n\nWeight: 1",
	"underbelly": "Underbelly Cannon:\nA special design of cannon which can fire\neven with another ship element in front.\nSuffers in projectile speed, accuracy, and reliability.\n\nWeight: 1",
	"volatile2": "Volatile Battery:\nStores 2 energy, which can power\nother components (such as shields).\nIf destroyed, it explodes, also destroying\nthe 4 adjacent elements in your ship.\n\nFunctions from anywhere on your ship.\n\nWeight: 1",
	"missilelauncher": "Missile Launcher:\nFires when you press "+keybind("shoot_missile")+", shooting a\nseeking missile which will explode on collision.\n\nExpends 2 energy per fire.\n\nWeight: 1",
	"cluster": "Cluster Fragment Gun:\nFires when you press "+keybind("shoot_cluster")+", shooting an\nexplosive projectile that splits into 8 additional\nshots on collision, dealing greater damage.\n\nExpends 2 energy per fire.\n\nWeight: 1",
}
var player_ship : Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func keybind(action: String) -> String:
	for input_event in InputMap.action_get_events(action):
		if input_event is InputEventKey:
			return OS.get_keycode_string(input_event.physical_keycode)
	return "�"
