extends AnimationTree
 
@export var player_node : CharacterBody3D
@onready var state_machine :AnimationNodeStateMachinePlayback= self["parameters/MovementStates/LIGHT_tree/playback"]
@onready var base_state_machine : AnimationNodeStateMachinePlayback = self["parameters/MovementStates/playback"]
var weapon_type = "LIGHT"

func _ready():
	player_node.dodge_started.connect(set_dodge)
	
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
	base_state_machine.travel("change_weapon")

func set_dodge(dodge_dir):
	if dodge_dir == "FORWARD":
		request_oneshot("DodgeRoll")
		
	elif dodge_dir == "BACK":
		pass
	#else:
		#pass
		
# Called when the node enters the scene tree for the first time.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player_node.strafing:
		set_strafe()
	else:
		set_free_move()
	
func set_strafe():
	# Strafe left and right animations run by the player's velocity cross product
	# Forward and back are acording to input, since direction changes by fixed camera orientation
	var new_dir = player_node.input_dir.y - player_node.input_dir.x
	var new_blend = Vector2(player_node.strafe_cross_product.y,new_dir)
	set("parameters/MovementStates/" + weapon_type + "_tree/MoveStrafe/blend_position", new_blend)

func set_free_move():
	# Non-strafing "free" movement, is just the forward input direction.
	var new_blend = Vector2(0,abs(player_node.input_dir.x) + abs(player_node.input_dir.y))
	set("parameters/MovementStates/" + weapon_type + "_tree/MoveStrafe/blend_position",new_blend)

func request_oneshot(oneshot:String):
	set("parameters/" + oneshot + "/request",true)
