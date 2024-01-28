extends AnimationTree
class_name AnimationTreeSoulsBase

## A companion to the SoulsCharacterBase, expects a lot of specific signals and will react to them
## by triggering oneshot animations, switching trees, blending run types, etc.

@export var player_node : CharacterBodySoulsBase
@onready var base_state_machine : AnimationNodeStateMachinePlayback = self["parameters/MovementStates/playback"]
@onready var current_weapon_tree : AnimationNodeStateMachinePlayback
@onready var weapon_type : String = "SLASH"

var lerp_movement
@onready var ladder_state_machine = self["parameters/MovementStates/LADDER_tree/playback"]
var guard_value :float = 0.0

signal animation_measured

func _ready():
	if !player_node:
		push_warning(str(self) + ": Player node must be set")
		
	player_node.dodge_started.connect(_on_dodge_started)
	player_node.jump_started.connect(_on_jump_started)
	player_node.ladder_started.connect(_on_ladder_start)
	player_node.ladder_finished.connect(_on_ladder_finished)
	player_node.changed_state.connect(_on_changed_state)
	player_node.door_started.connect(_on_door_started)
	player_node.gate_started.connect(_on_gate_started)
	player_node.weapon_change_started.connect(_on_weapon_change_started)
	player_node.weapon_change_ended.connect(_on_weapon_change_ended)
	player_node.gadget_change_started.connect(_on_gadget_change_started)
	player_node.gadget_started.connect(_on_gadget_started)
	player_node.parry_started.connect(_on_parry_started)
	player_node.hurt_started.connect(_on_hurt_started)
	player_node.block_started.connect(_on_block_started)
	player_node.use_item_started.connect(_on_use_item_started)
	player_node.death_started.connect(_on_death_started)
	player_node.sprint_started.connect(_on_sprint_started)
	player_node.landed_hard.connect(_on_landed_hard)
	
	_on_weapon_change_ended(player_node.weapon_type)
	
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

func _on_landed_hard():
	request_oneshot("LandedHard")

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
	if player_node.current_state == player_node.state.LADDER:
		request_oneshot("HurtLadder")
	else:
		var randi_hurt = randi_range(1,2)
		request_oneshot("Hurt"+ str(randi_hurt))
		current_weapon_tree.start("MoveStrafe")
	
func _on_death_started():
	base_state_machine.travel("Death")

func _on_use_item_started():
	request_oneshot("UseItem")

func _on_gadget_started():
	request_oneshot("Gadget")

func _on_sprint_started():
	base_state_machine.travel("SPRINT_tree")
	
func _on_dodge_started():
	request_oneshot("Dodge")

func _on_door_started():
	request_oneshot("OpenDoor")

func _on_gate_started():
	request_oneshot("OpenGate")

func _on_jump_started():
	request_oneshot("Jump")

func _on_weapon_change_started():
	request_oneshot("WeaponChange")

func _on_weapon_change_ended(_new_weapon_type):
	# if a wapon tree exixts, swap to it, otherwise, just use the "SLASH_tree" for rmovements.
	var weapon_tree_exists = tree_root.get_node("MovementStates").has_node(str(_new_weapon_type)+"_tree")
	if weapon_tree_exists:
		weapon_type = _new_weapon_type
	else:
		weapon_type = "SLASH"
	current_weapon_tree = get("parameters/MovementStates/"+str(_new_weapon_type)+"_tree/playback")

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
	var new_blend = Vector2(player_node.strafe_cross_product,player_node.move_dot_product)
	if player_node.current_state == player_node.state.DYNAMIC_ACTION:
		new_blend *= .4 # Force a walk speed
	lerp_movement = get("parameters/MovementStates/" + weapon_type + "_tree/MoveStrafe/blend_position")
	lerp_movement = lerp(lerp_movement,new_blend,.2)
	set("parameters/MovementStates/" + weapon_type + "_tree/MoveStrafe/blend_position", lerp_movement)

func set_free_move():
	# Non-strafing "free" movement, is just the forward input direction.
	var new_blend = Vector2(0,abs(player_node.input_dir.x) + abs(player_node.input_dir.y))
	if player_node.current_state == player_node.state.DYNAMIC_ACTION:
		new_blend *= .5 # force a walk speed
	lerp_movement = get("parameters/MovementStates/" + weapon_type + "_tree/MoveStrafe/blend_position")
	lerp_movement = lerp(lerp_movement,new_blend,.2)
	set("parameters/MovementStates/" + weapon_type + "_tree/MoveStrafe/blend_position",lerp_movement)


func _on_animation_started(anim_name):
	var new_anim_length = get_node(anim_player).get_animation(anim_name).length
	#print("animation name: " + str(anim_name))
	animation_measured.emit(new_anim_length)
