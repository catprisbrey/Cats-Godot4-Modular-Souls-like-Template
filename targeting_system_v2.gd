extends Node3D
class_name TargetingSystem_v2

@onready var center_eye = $CenterEye
@onready var left_eye = $LeftEye
@onready var right_eye = $RightEye
var center_list = []
var left_list = []
var right_list = []
var short_list = []

signal target_found

## The group name of targetable objects if using groups
@export var target_group_name : String = "Targets"
## The layers the eyes will scan when detecting targets
@export_flags_3d_physics var target_detection_layer_mask = 1 : 
	set(new_layers):
		target_detection_layer_mask = new_layers
		center_eye.set_collision_mask_value(new_layers)
		left_eye.set_collision_mask_value(new_layers)
		right_eye.set_collision_mask_value(new_layers)

#func _input(_event:InputEvent):
	#if _event is InputEventMouseMotion \
	#or _event is InputEventJoypadMotion:
		#select_target_dir(_event)

# Called when the node enters the scene tree for the first time.
func _ready():
	center_eye.body_entered.connect(_update_targets)
	center_eye.body_exited.connect(_update_targets)
	left_eye.body_entered.connect(_update_targets)
	left_eye.body_exited.connect(_update_targets)
	right_eye.body_entered.connect(_update_targets)
	right_eye.body_exited.connect(_update_targets)

func _update_targets(_body):
		center_list = center_eye.get_overlapping_bodies()
		left_list = left_eye.get_overlapping_bodies()
		right_list = right_eye.get_overlapping_bodies()
		short_list = []
		if center_list.size() != 0 \
		&& center_list[0].is_in_group(target_group_name):
			short_list.append(center_list[0])
		if left_list.size() != 0 \
		&& left_list[0].is_in_group(target_group_name):
			short_list.append(left_list[0])
		if right_list.size() != 0 \
		&& right_list[0].is_in_group(target_group_name):
			short_list.append(right_list[0])
		print(short_list)
		find_closest()
		
func find_closest(): # Loops through bodies in an area, maths out if it's the closest one
	var closest_body
	var closest_distance = INF
	if short_list != []:
		if short_list.size() == 1:
			closest_body = short_list[0]
		else:
			for body in short_list:
				var distance_to_parent = body.global_position.distance_to(global_position)
				if distance_to_parent < closest_distance: # If whatever body is closer than the last logged distance, set them as closests_body
					closest_distance = distance_to_parent
					closest_body = body
	else:
		closest_body = null
	target_found.emit(closest_body)
		
		
#func change_target(new_direction,_delay): 
	#_update_targets(self)
	#print("getting_targets")
	#var new_target
	#if short_list.size() >= 2:
		#if new_direction == -1:
			#new_target = short_list[0]
		#elif new_direction == 1:
			#new_target = short_list[1]
	#target_found.emit(new_target)
	#print("new Target selected: " + str(new_target))
	#await get_tree().create_timer(_delay).timeout
	
#func select_target_dir(_event): 
	#if _event is InputEventMouseMotion:
		#if abs(_event.relative.x) > 100: 
			## Calculate the direction of the mouse movement
			#var target_dir = sign(_event.relative.x)
			#change_target(target_dir, .3)
	#elif _event is InputEventJoypadMotion:
		#if _event.axis == 2 && abs(_event.axis_value) > .3:
			#var target_dir = sign(_event.axis_value)
			#change_target(target_dir, .2)
			#print(direction) # for targetting debugging
