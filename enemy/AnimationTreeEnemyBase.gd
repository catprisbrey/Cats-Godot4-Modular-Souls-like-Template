extends AnimationTree
class_name AnimationTreeEnemyBase

@export var player_node : CharacterBody3D
@onready var base_state_machine : AnimationNodeStateMachinePlayback = self["parameters/MovementStates/playback"]
@onready var current_state
var anim_length
var attack_count = 1
var hurt_count = 1
var last_oneshot

signal animation_measured
@onready var last_velocity

func _ready():
	
	if player_node:
		player_node.parried_started.connect(_on_parry_started)
		player_node.hurt_started.connect(_on_hurt_started)
		player_node.state_changed.connect(_on_state_changed)
		player_node.attack_started.connect(_on_attack_started)
		player_node.death_started.connect(_on_death_started)
func _process(_delta):
		set_movement()
	
func _on_state_changed(_new_state):
	current_state = _new_state

func _on_attack_started():
	attack_count = randi_range(1,2)
	request_oneshot("Attack")

func _on_parry_started():
	abort_oneshot(last_oneshot)
	request_oneshot("Parried")
	
func _on_hurt_started(): ## Picks a hurt animation between "Hurt1" and "Hurt2"
	abort_oneshot(last_oneshot)
	hurt_count = randi_range(1,2)
	request_oneshot("Hurt")

func _on_death_started():
	abort_oneshot(last_oneshot)
		
func request_oneshot(oneshot:String):
	last_oneshot = oneshot
	set("parameters/" + oneshot + "/request",true)
	
func abort_oneshot(oneshot):
	set("parameters/"+ str(oneshot) + "/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)

func set_movement():
	if player_node.retreating:
		smooth_walk_blend1(-.5)
	
	elif abs(player_node.velocity.x) + abs(player_node.velocity.z) < .1:  ## not moving
		
		smooth_walk_blend1(0.0)
	
	else: ## we can assume they're moving now
		if player_node.speed == player_node.walk_speed:
			smooth_walk_blend1(.5)
		elif player_node.speed == player_node.run_speed:
			smooth_walk_blend1(1.0)
	
	last_velocity = player_node.velocity
	
	
func smooth_walk_blend1(_new_target: float):
	
	var lerp_movement = float(get("parameters/MovementStates/MovementStates/blend_position"))
	lerp_movement = lerp(lerp_movement,_new_target,.2)
	set("parameters/MovementStates/MovementStates/blend_position",lerp_movement)

func _on_animation_started(anim_name):
	anim_length = get_node(anim_player).get_animation(anim_name).length
	animation_measured.emit(anim_length)
