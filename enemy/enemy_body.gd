extends CharacterBody3D



@export var group_name :String = "Targets"

@export var anim_state_tree :AnimationTree 
@onready var anim_length

@export var target_sensor : Area3D 
@onready var target : set = update_target
@export var default_target : Node3D
@onready var spawn_location : Marker3D = Marker3D.new()
@onready var chase_timer :Timer = $ChaseTimer

@onready var navigation_agent_3d : NavigationAgent3D = $NavigationAgent3D
@onready var direction = Vector3.ZERO

@onready var speed
@export var walk_speed = 1.25
@export var run_speed = 3.0
@export var dash_speed = 9.0
@onready var turn_speed = .1

@onready var attacking = false
signal attack_started
signal attack_ended

@onready var retreating = false
signal retreat_started
signal retreat_ended

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")# helper

var current_state : set = update_current_state # Enemy states controlled by enum PlayerStates
enum state {
	FREE,
	ALERT,
	ATTACK,
	DYNAMIC_ACTION,
	DEAD
}

func update_current_state(_new_state):
	current_state = _new_state
	match current_state:
		state.FREE:
			speed = walk_speed
		state.ALERT:
			speed = run_speed
		state.ATTACK:
			speed = 0.0
		state.DEAD:
			speed = 0.0
	print("state is: "+ str(current_state))
			
func _ready() -> void:
	current_state = state.FREE
	
	add_to_group(group_name)
	set_collision_layer_value(3,true)
	set_collision_mask_value(1,true)
	set_collision_mask_value(2,true)
	set_collision_mask_value(3,true)
	
	set_default_target()

	if target_sensor:
		target_sensor.target_spotted.connect(_on_target_spotted)
		target_sensor.target_lost.connect(_on_target_lost)
		
	if anim_state_tree:
		anim_state_tree.animation_measured.connect(_on_animation_measured)
func _physics_process(_delta):
	apply_gravity(_delta)
	
	match current_state:
		state.FREE:
			if is_on_floor():
				navigation()
				rotate_character()
				free_movement()
		state.ALERT:
			if is_on_floor():
				navigation()
				rotate_character()
				free_movement()
				combat_logic()
				
		state.ATTACK:
			dash_movement()
			
		state.DYNAMIC_ACTION:
			rotate_character()
			dash_movement()

func update_target(_new_target):
	target = _new_target
	if target != default_target:
		current_state = state.ALERT
	else:
		current_state = state.FREE
	
func _on_target_spotted(_spotted_target): # Updates from a TargetSensor if a target is found.
	if target != _spotted_target:
		target = _spotted_target
	chase_timer.stop()

func _on_target_lost():
	chase_timer.start()

func _on_chase_timer_timeout():
	give_up()
	
func give_up():
	current_state = state.DYNAMIC_ACTION
	speed = 0.0
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
		new_dir *= Vector3(1,0,1) # strip the y value so enemy stays on floor
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

func combat_logic():
	if global_position.distance_to(target.global_position) <= navigation_agent_3d.target_desired_distance :
		var random_choice = randi_range(1,2)
		match random_choice:
			1:
				attack()
			2:
				retreat()

func attack():
	current_state = state.ATTACK
	attacking = true
	print("I'm attacking the player!!")
	attack_started.emit()
	if anim_state_tree:
		await anim_state_tree.animation_measured
	await get_tree().create_timer(anim_length *.5).timeout
	dash()
	await get_tree().create_timer(anim_length *.5).timeout
	attack_ended.emit()
	attacking = false
	if current_state == state.ATTACK:
		current_state = state.ALERT
	

func retreat():
	retreat_started.emit()
	retreating = true
	current_state = state.DYNAMIC_ACTION
	direction = global_position - to_global(Vector3.BACK)
	speed = walk_speed
	velocity = direction * speed
	await get_tree().create_timer(2).timeout
	retreat_ended.emit()
	retreating = false
	current_state = state.ALERT

	
func dash(_new_direction : Vector3 = Vector3.FORWARD): 
	# burst of speed toward indicated direction, or forward by default
	speed = dash_speed
	direction = (global_position - to_global(_new_direction)).normalized()
	var dash_duration = .2
	await get_tree().create_timer(dash_duration).timeout
	speed = 0.0
	direction = Vector3.ZERO
	velocity = direction * speed
	
func dash_movement():
	# required in the process function states for dodges/dashes
	velocity = direction * speed
	move_and_slide()
		
func _on_navigation_agent_3d_target_reached():
	if target != default_target:
		combat_logic()

func _on_animation_measured(_new_length):
	anim_length = _new_length - .05 # offset slightly for the process frame
	#print("Anim Length: " + str(anim_length))


