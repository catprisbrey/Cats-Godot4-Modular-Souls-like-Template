extends AnimationTree

@export var player_node : CharacterBody3D
@onready var base_state_machine : AnimationNodeStateMachinePlayback = self["parameters/MovementStates/playback"]

signal animation_measured

func _ready():
	if player_node:
		player_node.attack_started.connect(_on_attack_started)
		player_node.attack_ended.connect(_on_attack_ended)
		player_node.retreat_started.connect(_on_retreat_started)
		player_node.retreat_ended.connect(_on_retreat_ended)

	animation_started.connect(_on_animation_started)
	
func _process(_delta):
	set_movement()
	#match player_node.current_state:
		#player_node.state.FREE:
			#set_movement()
		
func _on_attack_started():
	pass
	
func _on_attack_ended():
	pass
	
func _on_retreat_started():
	pass
	
func _on_retreat_ended():
	pass

func set_movement():
	if abs(player_node.direction) < Vector3(.1,.1,.1):
		smooth_walk_blend1(0.0)
	else:
		if player_node.speed == player_node.walk_speed:
			smooth_walk_blend1(.5)
		elif player_node.speed > player_node.walk_speed:
			smooth_walk_blend1(1.0)

func smooth_walk_blend1(_new_target: float):
	var lerp_movement = float(get("parameters/MovementStates/MovementStates/blend_position"))
	lerp_movement = lerp(lerp_movement,_new_target,.2)
	set("parameters/MovementStates/MovementStates/blend_position",lerp_movement)

func _on_animation_started(anim_name):
	var new_anim_length = get_node(anim_player).get_animation(anim_name).length
	print(anim_name)
	animation_measured.emit(new_anim_length)
