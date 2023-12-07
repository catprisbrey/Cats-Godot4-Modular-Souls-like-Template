extends Node3D
class_name TargetingSystem

## SUMMARY
## When turned on, a center_eye finds the most center target, signals the body.
## Each eye keeps an updating array lists of all targets one either side.
## Motioning right or left signals nodes from either eye list.
## Both groups and mask layers determine if targets will be found.

@onready var left_eye : Area3D= $LeftEye
@onready var right_eye : Area3D = $RightEye
@onready var center_eye : Area3D = $CenterEye

var left_list : Array = []
var right_list : Array = []

signal target_found

## The group name of targetable objects if using groups
@export var target_group_name : String = "Targets"
## The layers the eyes will scan when detecting targets
@export_flags_3d_physics var target_detection_layer_mask = 3

func _ready():
	center_eye.set_collision_mask_value(target_detection_layer_mask,true)
	left_eye.set_collision_mask_value(target_detection_layer_mask, true)
	right_eye.set_collision_mask_value(target_detection_layer_mask, true)
# Called when the node enters the scene tree for the first time.

func _update_targets():
	left_list = left_eye.get_overlapping_bodies()
	right_list = right_eye.get_overlapping_bodies()

	left_list = left_list.filter(_filter_body)
	right_list = right_list.filter(_filter_body)

func _filter_body(body):
	if body.is_in_group(target_group_name):
		return true

func _get_closest():
	var center_list = center_eye.get_overlapping_bodies()
	var first_target = get_target(center_list)
	if first_target: ## prioritize a target center screen
		target_found.emit(first_target)

	else: ## otherwise, get targets from side eyes and pick one.
		_update_targets()
		await get_tree().process_frame
		var new_list : Array = [get_target(right_list),get_target(left_list),]
		if !new_list.is_empty():
			if new_list[0]:
				first_target = new_list[0]
			else:
				first_target = new_list[1]
			target_found.emit(first_target)

			
func change_target(new_direction,_delay):
	_update_targets()
	await get_tree().process_frame
	var new_target
	if new_direction == -1:
		new_target = get_target(left_list)
	elif new_direction == 1:
		new_target = get_target(right_list)
	if new_target:
		target_found.emit(new_target)
	await get_tree().create_timer(_delay).timeout
	
	
## get garget may have issue
func get_target(target_list:Array):
	if !target_list.is_empty():
			#target_list.append(target_list[0])
			#target_list.pop_front()
			return target_list[0]
	
func _input(_event): 
	if _event is InputEventMouseMotion:
		if abs(_event.relative.x) > 300: 
			var target_dir = sign(_event.relative.x)
			change_target(target_dir, .5)

	elif _event is InputEventJoypadMotion:
		if _event.axis == 2 && abs(_event.axis_value) > .3:
			var target_dir = sign(_event.axis_value)
			change_target(target_dir, .5)

func _clear_lists():
	right_list.clear()
	left_list.clear()
	
