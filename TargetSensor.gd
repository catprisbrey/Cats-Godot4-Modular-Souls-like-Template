extends Node3D
class_name TargetingSystem

@onready var center_eye = $CenterEye
@onready var left_eye = $LeftEye
@onready var right_eye = $RightEye

var CenterClosest
var LeftClosest
var RightClosest
var FinalClosest

signal targeted

## The group name of targetable objects if using groups
@export var target_group_name : String = "Targets"
## The layers the eyes will scan when detecting targets
@export_flags_3d_physics var target_detection_layer_mask = 1 : 
	set(new_layers):
		target_detection_layer_mask = new_layers
		center_eye.set_collision_mask_value(new_layers)
		left_eye.set_collision_mask_value(new_layers)
		right_eye.set_collision_mask_value(new_layers)

var targeting = false : 
	set(toggle_targeting):
		targeting = toggle_targeting
		if toggle_targeting == true:
			# when first enabling targetting, emit the closest target node
			_update_targets()
			targeted.emit(FinalClosest)

func _input(_event:InputEvent):
	if _event.is_action_pressed("ui_text_backspace"):
		targeting = !targeting
		
	if targeting == true \
	&& _event is InputEventMouseMotion \
	or _event is InputEventJoypadMotion:
		_update_targets()
		select_target(_event)
		
func _update_targets():
		CenterClosest = findClosestBody($CenterEye)
		LeftClosest = findClosestBody($LeftEye)
		RightClosest = findClosestBody($RightEye)
		FinalClosest = findFinalClosest()
		return FinalClosest
		
func findClosestBody(area: Area3D): # Loops through bodies in an area, maths out if it's the closest one
	var closest_body
	var closest_distance = INF
	var overlapping_bodies: Array = area.get_overlapping_bodies()

	for body in overlapping_bodies:
		if body.is_in_group(target_group_name): # how far away are each body?
			print(body)
			var body_global_position = body.global_position
			var distance_to_parent = body_global_position.distance_to(global_position)

			if distance_to_parent < closest_distance: # If whatever body is closer than the last logged distance, set them as closests_body
				closest_distance = distance_to_parent
				closest_body = body
	return closest_body

func findFinalClosest(): # Loops through the closest target of each region, to find the MOST closest
	var finalclosest_body
	var closest_distance = INF
	var closest_bodies: Array = [CenterClosest,LeftClosest,RightClosest]

	for body in closest_bodies:
		if body != null:
			var body_global_position = body.global_position
			var distance_to_parent = body_global_position.distance_to(global_position)

			if distance_to_parent < closest_distance:
				closest_distance = distance_to_parent
				finalclosest_body = body
	return finalclosest_body

## Function for sensing direction of target to select
func select_target(_event): 
	if _event is InputEventMouseMotion:
		if abs(_event.relative.x) > 300: # check if timer is active
			# Calculate the direction of the mouse movement
			var target_dir = sign(_event.relative.x)
			ChangeTarget(target_dir, .3)
	elif _event is InputEventJoypadMotion:
		if _event.axis == 2 && abs(_event.axis_value) > .3:
			var target_dir = sign(_event.axis_value)
			ChangeTarget(target_dir, .2)
			#print(direction) # for targetting debugging

func ChangeTarget(new_direction,_delay): 
	# looks for targets from the left eye
	if new_direction == -1 && LeftClosest:
		targeted.emit(LeftClosest)
		print(LeftClosest)
	# looks for closet target from the right eye
	elif new_direction == 1 && RightClosest:
		targeted.emit(RightClosest)
		print(RightClosest)
	else:
		targeted.emit(CenterClosest)
		print(CenterClosest)
		if LeftClosest == null \
		&& RightClosest == null \
		&& CenterClosest == null: # if all baddies are dead or not in view, disable targeting mode
			await get_tree().create_timer(.3).timeout
			targeting = false
			targeted.emit(null)
	await get_tree().create_timer(_delay).timeout
	# This final await controls how soon you can switch between targets after locking on.
	# this helps avoid cycling through all the targets in a milisecond
