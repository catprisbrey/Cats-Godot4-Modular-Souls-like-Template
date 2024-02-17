extends Node3D
class_name PlayerTargetingSystem

## A set of eyes detect potential targets. And a raycast 
## confirms they are in the eyeline (to not target through walls).
## A center_eye finds the most center target. If the eyeline collides, that 
## body is emitted in a signal "target_found". Connect that wherever is useful.

## Eyes update only when targetting mode is on/togged. Keeping performance high.
## When actively tareting, both the left and right eyes are active.
## Both groups and mask layers determine if targets will be found.
## This works best when added as a child to the player, or a following camera.

## Targetting is activated via signals currently. Typically a bool value is passed
## to this nodes 'set_targeting(bool)' method
@export_range(1,10) var joystick_retarget_sensitivity :float = 5
@export_range(1,10) var mouse_retarget_sensitivity :float = 3

@onready var left_eye : Area3D= $LeftEye
@onready var right_eye : Area3D = $RightEye
@onready var center_eye : Area3D = $CenterEye
@onready var eyeline = $Eyeline

var left_list : Array = []
var right_list : Array = []
var center_list : Array = []
var current_target : Node3D = null
## if enabled, sensors will actively report and signal out targets. It's more 
## performant to only enable this as needed. (such as if your player enters a
## targeting or strafing mode). 
@export var targeting = false

signal targeting_changed
signal targets_updated
signal target_found

## The group name of targetable objects if using groups
@export var target_group_name : String = "Targets"
## The layers the eyes will scan when detecting targets
@export_flags_3d_physics var target_detection_layer_mask = 3

func _ready():
	center_eye.set_collision_mask_value(target_detection_layer_mask,true)
	left_eye.set_collision_mask_value(target_detection_layer_mask, true)
	right_eye.set_collision_mask_value(target_detection_layer_mask, true)
	eyeline.set_collision_mask_value(target_detection_layer_mask,true)

	targeting_changed.connect(_on_targeting_changed)
	
func _input(_event:InputEvent): 
	# Senses input left or right on mouse or joypad
	# and calls to change target to the left or right.
	if targeting:
		if _event is InputEventMouseMotion:
			if abs(_event.relative.x) > mouse_retarget_sensitivity * 100: 
				var target_dir = sign(_event.relative.x)
				select_new_target(target_dir, .6)

		elif _event is InputEventJoypadMotion:
			if _event.axis == 2 && abs(_event.axis_value) > joystick_retarget_sensitivity * .1:
				var target_dir = sign(_event.axis_value)
				select_new_target(target_dir, .5)
	
	## targeting is activated by ouside influences. Typically a follow cam
	## or player will signal it's targeting status to this node for it to begin
	## scanning and reporting back targets.
	
	#if _event.is_action_pressed("strafe_target"):
		#targeting = !targeting
		
	
func _on_targeting_changed(_toggle):
	targeting = _toggle
	if targeting == false:
		_clear_lists()
	else:
		get_closest()
	
func select_new_target(_new_direction,_delay):
	_update_targets()
	await targets_updated
	
	var new_target
	if _new_direction == -1:
		new_target = get_target(left_list)
	elif _new_direction == 1:
		new_target = get_target(right_list)
	# Once a target is found in those areas, an eyeline check is done to see
	# if we can actually SEE the enemy (so we don't target hidden enemies
	# through walls)
	if new_target:
		if await eyeline_check(new_target):
			target_found.emit(new_target)
	# and then a small delay to prevent cycling too fast through targets
	await get_tree().create_timer(_delay).timeout

func _update_targets():
	left_list = left_eye.get_overlapping_bodies()
	right_list = right_eye.get_overlapping_bodies()
	center_list = center_eye.get_overlapping_bodies()
	# Filters the arrays to only bodies in the target group
	left_list = left_list.filter(_filter_body)
	right_list = right_list.filter(_filter_body)
	center_list = center_list.filter(_filter_body)
	
	targets_updated.emit()

func _filter_body(body):
	# returns true of the bodies are in the target group.
	if body.is_in_group(target_group_name):
		return true
		
func eyeline_check(_new_target):
	if _new_target:
		eyeline.look_at(_new_target.global_position + Vector3.UP,Vector3.UP,false)
		await get_tree().process_frame
		if eyeline.is_colliding():
			if eyeline.get_collider() == _new_target:
				return true

func get_closest():
	# prioritize the center eye, but if no target found, check the next eyes for 
	# a target to assign.
	_update_targets()
	await targets_updated
	
	# if an input direction is indicated, a new target
	# will be selected from the left or right eye's list 
	var center_target
	var right_target
	var left_target
	var new_target
	center_target = get_target(center_list)
	left_target = get_target(left_list)
	right_target = get_target(right_list)
	if center_target:
		new_target = center_target
	else:
		if right_target:
			new_target = right_target
		else:
			if left_target:
				new_target = left_target
			else:
				new_target = null
	if new_target:
		if await eyeline_check(new_target):
			target_found.emit(new_target)
	print(new_target)
	# and then a small delay to prevent cycling too fast through targets
	await get_tree().create_timer(.3).timeout

func get_target(target_list:Array):
	if !target_list.is_empty():
			return target_list[0]
	
func _clear_lists():
	# can be called to clean the arrays (like if targeting mode is exited)
	right_list.clear()
	left_list.clear()
	center_list.clear()
	
