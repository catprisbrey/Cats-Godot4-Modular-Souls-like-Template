extends CharacterBody3D

@export var group_name :String = "Targets"
@export var target_sensor : Area3D 
@onready var target
@onready var navigation_agent_3d = $NavigationAgent3D
@onready var direction = Vector3.ZERO

@export var default_speed = 1.5
@onready var speed = default_speed
@export var chase_speed = 3.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")# helper

var current_state # Enemy states controlled by enum PlayerStates
enum state {
	FREE,
	ALERT,
	ATTACK,
	CINEMA,
	DEAD
}

func _ready() -> void:
	current_state = state.FREE
	
	add_to_group(group_name)
	set_collision_layer_value(3,true)
	set_collision_mask_value(1,true)
	set_collision_mask_value(2,true)
	set_collision_mask_value(3,true)
	
	if target_sensor:
		target_sensor.target_spotted.connect(_on_target_spotted)

func _physics_process(_delta):
	apply_gravity(_delta)
	
	if is_on_floor():
		navigation()
		rotate_character()
	
	move_and_slide()
	
func _on_target_spotted(_new_target): # Updates from a TargetSensor if a target is found.
	target = _new_target

func apply_gravity(_delta):
	if !is_on_floor():
		velocity.y -= gravity * _delta

func navigation():
	if target:
		navigation_agent_3d.target_position = target.global_position
		var new_dir = (navigation_agent_3d.get_next_path_position() - global_position).normalized()
		new_dir *= Vector3(1,0,1) # strip the y value so enemy stays on floor
		direction = new_dir
		velocity = direction * speed

		
		
func rotate_character():
		var lookdirection = global_position.direction_to(navigation_agent_3d.get_next_path_position())
		rotation.y = lerp_angle(rotation.y, atan2(lookdirection.x, lookdirection.z), speed)
