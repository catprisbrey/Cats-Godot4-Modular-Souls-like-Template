extends CharacterBody3D

@export var group_name :String = "Targets"
@export var target_sensor : Area3D 
@onready var target

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
	
func _on_target_spotted(_new_target): # Updates from a TargetSensor if a target is found.
	target = _new_target

