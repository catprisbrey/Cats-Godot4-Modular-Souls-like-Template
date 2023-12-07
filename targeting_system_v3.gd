extends Node3D
class_name TargetingSystem

## SUMMARY
## When turned on, a rayshape finds the closet target first. Signals the body.
## Each eye keeps an updating array list of all targets one either side.
## Motioning right or left cycles and signals each node per eyes list.

@onready var left_eye : Area3D= $LeftEye
@onready var right_eye : Area3D = $RightEye
@onready var closest_cast : ShapeCast3D = $ClosestCast
var left_list : Array = []
var right_list : Array = []

var left_counter : int = 0
var right_counter : int = 0

signal target_found

## The group name of targetable objects if using groups
@export var target_group_name : String = "Targets"
## The layers the eyes will scan when detecting targets
@export_flags_3d_physics var target_detection_layer_mask = 1 : 
	set(new_layers):
		target_detection_layer_mask = new_layers
		closest_cast.set_collision_mask_value(new_layers, true)
		left_eye.set_collision_mask_value(new_layers, true)
		right_eye.set_collision_mask_value(new_layers, true)

# Called when the node enters the scene tree for the first time.
func _ready():
	left_eye.body_entered.connect(_update_left)
	left_eye.body_exited.connect(_update_left)
	right_eye.body_entered.connect(_update_right)
	right_eye.body_exited.connect(_update_right)

func _update_left(_body):
	left_list = left_eye.get_overlapping_bodies()
	for each in left_list:
		if !each.is_in_group(target_group_name):
			var to_pop = left_list.find(each)
			left_list.pop_at(to_pop)
	print("Left list: " + str(left_list))

func _update_right(_body):
	right_list = right_eye.get_overlapping_bodies()
	for each in right_list:
		if !each.is_in_group(target_group_name):
			var to_pop = right_list.find(each)
			right_list.pop_at(to_pop)
	print("Right list: " + str(right_list))
	
func _get_closest():
	var closest_target = closest_cast.get_collider(0)
	if closest_target.is_in_group(target_group_name):
		target_found.emit(closest_target)
		print("closets = "+ str(closest_target))
	
func change_target(new_direction,_delay): 
	print("getting_targets")
	var new_target
	if new_direction == 1:
		new_target = get_target(left_list,left_counter)
	elif new_direction == -1:
		new_target = get_target(right_list,right_counter)
	if new_target != null:
		target_found.emit(new_target)
		print("new Target selected: " + str(new_target))
	await get_tree().create_timer(_delay).timeout
	
## get garget may have issue
func get_target(target_list:Array, new_counter):
	if target_list.size() > 0:
		return target_list[0]
	else:
		new_counter = 0
		return null
	
func _input(_event): 
	if _event is InputEventMouseMotion:
		if abs(_event.relative.x) > 100: 
			var target_dir = sign(_event.relative.x)
			change_target(target_dir, .3)

	elif _event is InputEventJoypadMotion:
		if _event.axis == 2 && abs(_event.axis_value) > .3:
			var target_dir = sign(_event.axis_value)
			change_target(target_dir, .2)

