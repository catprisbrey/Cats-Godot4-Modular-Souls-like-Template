extends CharacterBody3D
class_name EnemyBase

@export var group_name :String = "Targets"

@export var anim_state_tree :AnimationTree 
@onready var anim_length

@export var target_sensor : Area3D 
@onready var target : set = set_target
@export var default_target : Node3D
@onready var spawn_location : Marker3D = Marker3D.new()
@onready var chase_timer :Timer = $ChaseTimer
signal chase_ended

@onready var navigation_agent_3d : NavigationAgent3D = $NavigationAgent3D
@onready var direction = Vector3.ZERO

@onready var speed
@export var walk_speed = 1.25
@export var run_speed = 3.0
@export var dash_speed = 6.0
@onready var turn_speed = .05

signal attack_started
signal attack_ended
signal attack_swing_started

@export var combat_range : float = 3.0
@onready var combat_timer = $CombatTimer
signal parried_started
signal hurt_started
var can_be_hurt = true

@onready var retreating = false

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")# helper

signal state_changed
var current_state = state.FREE : set = update_current_state # Enemy states controlled by enum PlayerStates
enum state {
	FREE,
	CHASE,
	COMBAT,
	ATTACK,
	DYNAMIC_ACTION,
	DEAD
}

func update_current_state(_new_state):
	current_state = _new_state
	match current_state:
		state.FREE:
			speed = walk_speed
		state.CHASE:
			speed = run_speed
		state.COMBAT:
			speed = walk_speed
		state.ATTACK:
			speed = 0.0
		state.DYNAMIC_ACTION:
			speed = 0.0
		state.DEAD:
			speed = 0.0
	state_changed.emit(_new_state)
			
func _ready() -> void:
	add_to_group(group_name)
	set_default_target()

	if target_sensor:
		target_sensor.target_spotted.connect(_on_target_spotted)
		target_sensor.target_lost.connect(_on_target_lost)
		
	if anim_state_tree:
		anim_state_tree.animation_measured.connect(_on_animation_measured)
	
func _physics_process(_delta):
	apply_gravity(_delta)
	if is_on_floor():
		match current_state:
				state.FREE:
					navigation()
					rotate_character()
					free_movement()
				state.CHASE:
					navigation()
					rotate_character()
					free_movement()
					chase_or_fight()
				state.COMBAT:
					rotate_character()
					free_movement()
					reset_attack_clock()
					chase_or_fight()
				state.ATTACK:
					free_movement()
		
			

func set_target(_new_target): 
	target = _new_target
	if current_state != state.ATTACK:
		if target != default_target:
			current_state = state.CHASE
		else:
			current_state = state.FREE
	
func _on_target_spotted(_spotted_target): # Updates from a TargetSensor if a target is found.
	if target != _spotted_target:
		target = _spotted_target
	chase_timer.start()

func _on_target_lost():
	chase_timer.start()

func _on_chase_timer_timeout():
	give_up()
	
func give_up():
	current_state = state.DYNAMIC_ACTION
	speed = 0.0
	chase_ended.emit()
	await get_tree().create_timer(2).timeout
	target = default_target
	
func apply_gravity(_delta):
	if !is_on_floor():
		velocity.y -= gravity * _delta
		move_and_slide()
		
func navigation():
	if target:
		navigation_agent_3d.target_position = target.global_position
		var new_dir = (navigation_agent_3d.get_next_path_position() - global_position).normalized()
		new_dir *= Vector3(1,0,1) # strip the y value so enemy stays at currentt level
		direction = new_dir
		
func free_movement():
	velocity = direction * speed
	move_and_slide()
	
func rotate_character():
		var lookdirection = global_position.direction_to(navigation_agent_3d.get_next_path_position())
		rotation.y = lerp_angle(rotation.y, atan2(lookdirection.x, lookdirection.z), turn_speed)

func set_default_target(): ## Creates a node to return to after patrolling if 
	## no default target is set.
	add_child(spawn_location)
	spawn_location.top_level = true
	spawn_location.global_position = to_global(Vector3(0,0,.2))
	if not default_target:
		default_target = spawn_location
	target = default_target

func chase_or_fight(): ## depending on distance to target, run or walk
	var current_distance = global_position.distance_to(target.global_position)
	if current_distance > combat_range && current_state != state.CHASE:
		current_state = state.CHASE
	elif current_distance <= combat_range && current_state != state.COMBAT:
		current_state = state.COMBAT

func _on_combat_timer_timeout():
	combat_randomizer()

func reset_attack_clock():
	if current_state == state.COMBAT:
		if combat_timer.is_stopped():
			combat_timer.start()
			
func combat_randomizer():
	var random_choice = randi_range(1,10)
	if random_choice <= 3:
		retreat()
	else:
		attack()

func attack():
	current_state = state.ATTACK
	anim_length = .5
	if anim_state_tree: 
		await anim_state_tree.animation_measured
	await get_tree().create_timer(anim_length *.4).timeout
	attack_started.emit()
	dash() ## delayed dash to move forward during attack animation
	await get_tree().create_timer(anim_length *.4).timeout
	current_state = state.CHASE
	
	
func retreat(): # Back away for a period of time
	var retreat_duration = 1.0
	retreating = true
	current_state = state.COMBAT
	direction = -global_transform.basis.z.normalized()
	await get_tree().create_timer(retreat_duration).timeout
	retreating = false
	current_state = state.CHASE
	
func dash(_new_direction : Vector3 = Vector3.FORWARD): 
	# burst of speed toward indicated direction, or forward by default
	speed = dash_speed
	direction = (global_position - to_global(_new_direction)).normalized()
	var dash_duration = .2
	await get_tree().create_timer(dash_duration).timeout
	speed = 0.0
	velocity = direction * speed

func _on_animation_measured(_new_length):
	anim_length = _new_length - .05 # offset slightly for the process frame

func hit(_by_who, _by_what):
	target = _by_who
	if can_be_hurt == true:
		can_be_hurt = false
		current_state = state.DYNAMIC_ACTION
		hurt_started.emit()
		anim_length = .4
		if anim_state_tree:
			await anim_state_tree.animation_measured
		await get_tree().create_timer(anim_length).timeout
		can_be_hurt = true
		current_state = state.CHASE
	
func parried():
	current_state = state.DYNAMIC_ACTION
	parried_started.emit()
	anim_length = 2.0
	if anim_state_tree:
		await anim_state_tree.animation_measured
	await get_tree().create_timer(anim_length +1.0).timeout
	current_state = state.CHASE

