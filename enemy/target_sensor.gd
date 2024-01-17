extends Area3D

## The Aread3D scans for the target group in the physics detection layer. 
## if an object enters, the eyeline repeately checks if it can see the potential
## target. If it succeeds, a 'target_spotted' signal emits. Connect wherever
## useful, for example, into navegation code to persue the player.

@onready var eyeline : RayCast3D = $Eyeline
@export var target_group_name : String = "Player"
@export_flags_3d_physics var dectection_layer_mask
@onready var check_interval = $CheckInterval

signal target_spotted
var potential_target
var target
var checking_active = false
# Called whe@n the node enters the scene tree for the first time.

func _ready():
	set_collision_mask_value(dectection_layer_mask,true)
	eyeline.set_collision_mask_value(dectection_layer_mask,true)

## Lookat a sensed body's direction, if there is a clean line of site
## return that node to be assigned as a target
func eyeline_check():
	if checking_active && potential_target:
		eyeline.look_at(potential_target.global_position + Vector3.UP,Vector3.UP,true)
		await get_tree().process_frame
		if eyeline.is_colliding():
			var new_vista = eyeline.get_collider()
			if potential_target == new_vista:
				target_spotted.emit(potential_target)


## When a player body is in the field of view, check if they're in
## the enemy's eyeline, and if so, mark them as the current target
func _on_body_entered(_body):
	if _body.is_in_group(target_group_name):
		potential_target = _body
		checking_active = true
		eyeline_check()


func _on_body_exited(_body):
	if _body.is_in_group(target_group_name):
		potential_target = null
		checking_active = false


func _on_check_interval_timeout():
	eyeline_check()
