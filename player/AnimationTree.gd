extends AnimationTree
 
@export var player_node : CharacterBody3D
@onready var base_state_machine : AnimationNodeStateMachinePlayback = self["parameters/MovementStates/playback"]
var weapon_type = "LIGHT"

@onready var ladder_state_machine = self["parameters/MovementStates/LADDER_tree/playback"]

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
	
func update_state(new_state):
	#match new_state:
		#player_node.state.FREE:
			#if !player_node.is_on_floor():
				#set_fall()
	pass
			
#func _input(event):
	#if event.is_action_pressed("interact"):
		#weaponchange()
#
#func weaponchange():
	#match weapon_type:
		#"LIGHT":
			#weapon_type = "HEAVY"
		#"HEAVY":
			#weapon_type = "LIGHT"
	#print(weapon_type)
	#request_oneshot("ChangeWeapon")

func set_dodge(dodge_dir):
	match dodge_dir:
		"FORWARD":
			request_oneshot("DodgeRoll")
		
		"BACK":
			request_oneshot("DodgeBack")

func set_door():
	request_oneshot("OpenDoor")

func set_jump():
	request_oneshot("Jump")

func set_ladder_start(top_or_bottom):
	base_state_machine.start("LADDER_tree")
	ladder_state_machine.travel("LadderStart_" + top_or_bottom)
	
func set_ladder_finished(top_or_bottom):
	ladder_state_machine.travel("LadderEnd_" + top_or_bottom)
	
func set_ladder():
	set("parameters/MovementStates/LADDER_tree/LadderBlend/blend_position",-player_node.input_dir.y)

func _process(_delta):
	if player_node.strafing:
		set_strafe()
	elif player_node.current_state == player_node.state.LADDER:
		set_ladder()
		#if player_node.is_on_floor():
#
			#player_node.current_state = player_node.state.FREE
	else:
		set_free_move()
	
func set_strafe():
	# Strafe left and right animations run by the player's velocity cross product
	# Forward and back are acording to input, since direction changes by fixed camera orientation
	#var new_dir = player_node.input_dir.y - player_node.input_dir.x
	var new_blend = Vector2(player_node.strafe_cross_product,player_node.move_dot_product)
	set("parameters/MovementStates/" + weapon_type + "_tree/MoveStrafe/blend_position", new_blend)

func set_free_move():
	# Non-strafing "free" movement, is just the forward input direction.
	var new_blend = Vector2(0,abs(player_node.input_dir.x) + abs(player_node.input_dir.y))
	#var new_blend = Vector2(0,abs(player_node.strafe_cross_product) + abs(player_node.move_dot_product))
	set("parameters/MovementStates/" + weapon_type + "_tree/MoveStrafe/blend_position",new_blend)

func request_oneshot(oneshot:String):
	set("parameters/" + oneshot + "/request",true)


func _on_animation_started(anim_name):
	var new_anim_length = get_node(anim_player).get_animation(anim_name).length
	print(anim_name)
	animation_measured.emit(new_anim_length)
