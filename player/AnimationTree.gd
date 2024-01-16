extends AnimationTree
class_name AnimationTreeSoulsBase

@export var player_node : CharacterBody3D
@onready var animation_player_node : AnimationPlayer
@onready var base_state_machine : AnimationNodeStateMachinePlayback = self["parameters/MovementStates/playback"]
var lerp_movement
@onready var ladder_state_machine = self["parameters/MovementStates/LADDER_tree/playback"]
var guard_value :float = 0.0

signal animation_measured

func _ready():
	if !player_node:
		push_warning("Player node must be set")
	player_node.dodge_started.connect(_on_dodge_started)
	player_node.jump_started.connect(_on_jump_started)
	player_node.ladder_started.connect(_on_ladder_start)
	player_node.ladder_finished.connect(_on_ladder_finished)
	player_node.changed_state.connect(_on_changed_state)
	player_node.door_started.connect(_on_door_started)
	player_node.gate_started.connect(_on_gate_started)
	player_node.weapon_change_started.connect(_on_weapon_change_started)
	player_node.gadget_change_started.connect(_on_gadget_change_started)
	player_node.gadget_started.connect(_on_gadget_started)
	player_node.parry_started.connect(_on_parry_started)
	player_node.hurt_started.connect(_on_hurt_started)
	player_node.block_started.connect(_on_block_started)
	player_node.use_item_started.connect(_on_use_item_started)
	player_node.death_started.connect(_on_death_started)
	
	animation_player_node = get_node(anim_player)
func _on_changed_state(_new_state):
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
	var new_blend = lerp(get("parameters/Guarding/blend_amount"),guard_value,.2)
	set("parameters/Guarding/blend_amount", new_blend)

func _on_parry_started():
	request_oneshot("Parry")

func _on_block_started():
	request_oneshot("Block")

func _on_hurt_started(): ## Picks a hurt animation between "Hurt1" and "Hurt2"
	var randi_hurt = randi_range(1,2)
	request_oneshot("Hurt"+ str(randi_hurt))

func _on_death_started():
	base_state_machine.travel("Death")

func _on_use_item_started():
	request_oneshot("UseItem")

func _on_gadget_started():
	match player_node.gadget_type:
		"SHIELD":
			request_oneshot("ShieldBash")
		"TORCH":
			request_oneshot("SlashL")
			
func _on_dodge_started(dodge_dir):
	match dodge_dir:
		"FORWARD":
			request_oneshot("DodgeRoll")
		
		"BACK":
			request_oneshot("DodgeBack")

func _on_door_started():
	request_oneshot("OpenDoor")

func _on_gate_started():
	request_oneshot("OpenGate")

func _on_jump_started():
	request_oneshot("Jump")

func _on_weapon_change_started():
	request_oneshot("WeaponChange")

func _on_gadget_change_started():
	request_oneshot("GadgetChange")

func _on_ladder_start(top_or_bottom):
	base_state_machine.start("LADDER_tree")
	ladder_state_machine.travel("LadderStart_" + top_or_bottom)
	
func _on_ladder_finished(top_or_bottom):
	ladder_state_machine.travel("LadderEnd_" + top_or_bottom)
	
func set_ladder():
	set("parameters/MovementStates/LADDER_tree/LadderBlend/blend_position",-player_node.input_dir.y)

	
func set_strafe():
	# Strafe left and right animations run by the player's velocity cross product
	# Forward and back are acording to input, since direction changes by fixed camera orientation
	#var new_dir = player_node.input_dir.y - player_node.input_dir.x
	var new_blend = Vector2(player_node.strafe_cross_product,player_node.move_dot_product)
	if player_node.current_state == player_node.state.DYNAMIC_ACTION:
		new_blend *= .4 
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
