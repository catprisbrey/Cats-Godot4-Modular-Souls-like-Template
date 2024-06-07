extends CharacterBody3D

@onready var nav_agent_3d = $NavigationAgent3D
@onready var animation_tree = $AnimationTree
@export var speed :float = 4.0
@onready var direction : Vector3 = Vector3.ZERO

@export var target_sensor : Area3D 
@export var target : Node3D : set = set_target
## Use for pathfinding, it will return to following this default target after
## giving up a chase. Most commonly this is a pathfollow node, following a Path.
## if left blank, then the default target is simply the same locationw here this
## enemy spawns.
@export var default_target : Node3D
@onready var spawn_location : Marker3D = Marker3D.new()
@export var combat_range :float = 2
@onready var combat_timer : Timer = $CombatTimer

signal attack_started
signal retreat_started

@onready var current_state = state.FREE : set = update_current_state # Enemy states controlled by enum PlayerStates
enum state {
	FREE,
	CHASE,
	COMBAT,
	ATTACK,
	DEAD
}
signal state_changed


func _ready():
	nav_agent_3d.target_reached.connect(_on_target_reached)
	combat_timer.timeout.connect(_on_combat_timer_timeout)
	
func _process(delta):
	rotate_character()
	navigation()
	free_movement(delta)
	chase_or_fight()
	
	
	match current_state:
		state.FREE:
			pass
		state.CHASE:
			pass
		state.COMBAT:
			pass
		state.DEAD:
			pass
	
func _on_target_reached():
	pass
	
func free_movement(delta):
	#set_quaternion(get_quaternion() * animation_tree.get_root_motion_rotation())
	var rate : float # imiates directional change acceleration rate
	if is_on_floor():
		rate = .5
	else:
		rate = .1
	var new_velocity = get_quaternion() * animation_tree.get_root_motion_position() / delta

	if is_on_floor():
		velocity.x = move_toward(velocity.x, new_velocity.x, rate)
		velocity.y = move_toward(velocity.y, new_velocity.y, rate)
		velocity.z = move_toward(velocity.z, new_velocity.z, rate)
	else:
		velocity.x = move_toward(velocity.x, calc_direction().x * speed, rate)
		velocity.z = move_toward(velocity.z, calc_direction().z * speed, rate)
		
	move_and_slide()
		
func calc_direction() -> Vector3 :
	var new_direction = global_transform.basis.z
	return new_direction
	
func update_current_state(_new_state):
	current_state = _new_state
	if current_state != state.DEAD:
		state_changed.emit(_new_state)
		
func set_target(_new_target): 
	target = _new_target
	#if current_state != state.ATTACK:
	if target != default_target:
		current_state = state.CHASE
	else:
		current_state = state.FREE

func navigation():
	if target:
		nav_agent_3d.target_position = target.global_position
		var new_dir = (nav_agent_3d.get_next_path_position() - global_position).normalized()
		new_dir *= Vector3(1,0,1) # strip the y value so enemy stays at current level
		direction = new_dir
		
func rotate_character():
	var rate = .2
	var new_direction = global_position.direction_to(nav_agent_3d.get_next_path_position())
	var current_rotation = global_transform.basis.get_rotation_quaternion()
	var target_rotation = current_rotation.slerp(Quaternion(Vector3.UP, atan2(new_direction.x, new_direction.z)), rate)
	global_transform.basis = Basis(target_rotation)

func chase_or_fight(): ## depending on distance to target, run or walk
	if target:
		var current_distance = global_position.distance_to(target.global_position)
		if current_distance > combat_range && current_state != state.CHASE:
			current_state = state.CHASE
		elif current_distance <= combat_range && current_state != state.COMBAT:
			current_state = state.COMBAT

func _on_combat_timer_timeout():
	if current_state != state.DEAD:
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
	attack_started.emit()
	
func retreat(): # Back away for a period of time
	retreat_started.emit()
