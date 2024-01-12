extends AnimationTree
class_name AnimationTreeSoulsBase

@export var player_node : CharacterBody3D
@onready var base_state_machine : AnimationNodeStateMachinePlayback = self["parameters/MovementStates/playback"]
var lerp_movement
@onready var ladder_state_machine = self["parameters/MovementStates/LADDER_tree/playback"]
var guard_value :float = 0.0

signal animation_measured

func _ready():
	if !player_node:
		push_warning("Player node must be set")
	player_node.dodge_started.connect(set_dodge)
	player_node.jump_started.connect(set_jump)
	player_node.ladder_started.connect(set_ladder_start)
	player_node.ladder_finished.connect(set_ladder_finished)
	player_node.changed_state.connect(update_state)
	player_node.door_started.connect(set_door)
	player_node.gate_started.connect(set_gate)
	player_node.weapon_change_started.connect(set_weapon)
	player_node.gadget_change_started.connect(set_gadget)

func update_state(_new_state):
	pass



func _process(_delta):
	
	if player_node.strafing:
		set_strafe()
	else:
		set_free_move()
		
	if player_node.current_state == player_node.state.LADDER:
		set_ladder()
	
	set_guarding()

func request_oneshot(oneshot:String):
	set("parameters/" + oneshot + "/request",true)


func set_guarding():
	if player_node.guarding:
		guard_value = 1
	else:
		guard_value = 0
	var new_blend = lerp(get("parameters/Guarding/blend_amount"),guard_value,.4)
	set("parameters/Guarding/blend_amount", new_blend)

func set_dodge(dodge_dir):
	match dodge_dir:
		"FORWARD":
			request_oneshot("DodgeRoll")
		
		"BACK":
			request_oneshot("DodgeBack")

func set_door():
	request_oneshot("OpenDoor")

func set_gate():
	request_oneshot("OpenGate")

func set_jump():
	request_oneshot("Jump")

func set_weapon():
	request_oneshot("WeaponChange")

func set_gadget():
	request_oneshot("GadgetChange")

func set_ladder_start(top_or_bottom):
	base_state_machine.start("LADDER_tree")
	ladder_state_machine.travel("LadderStart_" + top_or_bottom)
	
func set_ladder_finished(top_or_bottom):
	ladder_state_machine.travel("LadderEnd_" + top_or_bottom)
	
func set_ladder():
	set("parameters/MovementStates/LADDER_tree/LadderBlend/blend_position",-player_node.input_dir.y)

	
func set_strafe():
	# Strafe left and right animations run by the player's velocity cross product
	# Forward and back are acording to input, since direction changes by fixed camera orientation
	#var new_dir = player_node.input_dir.y - player_node.input_dir.x
	var new_blend = Vector2(player_node.strafe_cross_product,player_node.move_dot_product)
	if player_node.current_state == player_node.state.DYNAMIC_ACTION:
		new_blend *= .5 
	lerp_movement = get("parameters/MovementStates/" + player_node.weapon_type + "_tree/MoveStrafe/blend_position")
	lerp_movement = lerp(lerp_movement,new_blend,.2)
	set("parameters/MovementStates/" + player_node.weapon_type + "_tree/MoveStrafe/blend_position", lerp_movement)

func set_free_move():
	# Non-strafing "free" movement, is just the forward input direction.
	var new_blend = Vector2(0,abs(player_node.input_dir.x) + abs(player_node.input_dir.y))
	if player_node.current_state == player_node.state.DYNAMIC_ACTION:
		new_blend *= .5 
	lerp_movement = get("parameters/MovementStates/" + player_node.weapon_type + "_tree/MoveStrafe/blend_position")
	lerp_movement = lerp(lerp_movement,new_blend,.2)
	#var new_blend = Vector2(0,abs(player_node.strafe_cross_product) + abs(player_node.move_dot_product))
	set("parameters/MovementStates/" + player_node.weapon_type + "_tree/MoveStrafe/blend_position",lerp_movement)


func _on_animation_started(anim_name):
	var new_anim_length = get_node(anim_player).get_animation(anim_name).length
	print(anim_name)
	animation_measured.emit(new_anim_length)
