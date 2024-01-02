extends AnimationTree
 
@export var player_node : CharacterBody3D
@onready var state_machine :AnimationNodeStateMachinePlayback= self["parameters/LIGHT_tree/playback"]

var weapon_type = "LIGHT"

func _input(event):
	if event.is_action_pressed("interact"):
		weaponchange()

func weaponchange():
	match weapon_type:
		"LIGHT":
			weapon_type = "HEAVY"
		"HEAVY":
			weapon_type = "LIGHT"
	print(weapon_type)

# Called when the node enters the scene tree for the first time.
func _ready():
	#self["parameters/playback"].travel("Light_tree")
	#state_machine.travel("MoveStrafe")
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player_node.strafing:
		set_strafe()
	else:
		set_free_move()
	
func set_strafe():
	print(player_node.strafe_cross_product.y)
	var new_blend = Vector2(player_node.strafe_cross_product.y,player_node.input_dir.y)
	set("parameters/" + weapon_type + "_tree/MoveStrafe/blend_position", new_blend)

func set_free_move():
	var new_blend = Vector2(0,abs(player_node.input_dir.x) + abs(player_node.input_dir.y))
	set("parameters/" + weapon_type + "_tree/MoveStrafe/blend_position",new_blend)
