extends Node3D
class_name PlayerTargetingSystem


## A set of eyes detect potential targets. And a raycast 
## confirms they are in the eyeline (to not target through walls).
## Each eye manages their own list of targets they see. When targeting
## is enabled (usually via a signaling node/signal to match when strafe
## or a lock on cam is enabled), this system will emit a signal of the current
## target.

## The initial target will prioritize the center eye's targets first,
## then right, then left (since the camera is over the right shoulder).
## Retargeting to left or right list targets can happen by motioning with
## the mouse or joystick in those directions.

@export var signaling_node : Node
@export var targeting_toggle_signal :String = "targeting_changed"

@export_range(1,10) var joystick_retarget_sensitivity :float = 5
@export_range(1,10) var mouse_retarget_sensitivity :float = 3

@onready var left_eye : Area3D= $LeftEye
@onready var right_eye : Area3D = $RightEye
@onready var center_eye : Area3D = $CenterEye
@onready var eyeline = $Eyeline

var target_list : Array = []
@onready var targeting = false 

signal target_found

@onready var reticle_control = $ReticleControl

## The group name of targetable objects if using groups
@export var target_group_name : String = "Targets"
## The layers the eyes will scan when detecting targets
@export_flags_3d_physics var target_detection_layer_mask = 3

func _ready():
	center_eye.collision_mask = target_detection_layer_mask
	left_eye.collision_mask = target_detection_layer_mask
	right_eye.collision_mask = target_detection_layer_mask
	eyeline.collision_mask = target_detection_layer_mask
	
	center_eye.connect("target_list_updated",_update_lists)
	left_eye.connect("target_list_updated",_update_lists)
	right_eye.connect("target_list_updated",_update_lists)
	
	if signaling_node:
		if signaling_node.has_signal(targeting_toggle_signal):
			signaling_node.connect(targeting_toggle_signal,_on_targeting_toggled)
			
func _update_lists():
	target_list = center_eye.target_list
	target_list += right_eye.target_list
	target_list += left_eye.target_list

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
	
	## targeting is activated by outside influences. Typically a follow cam
	## or player will signal it's targeting status to this node for it to begin
	## scanning and reporting back targets.
		
	
func _on_targeting_toggled(_toggle):
	print("targeting toggled: " + str(_toggle))
	targeting = _toggle
	if targeting == false:
		target_list.clear()
	else:
		get_target()
	
func select_new_target(_new_direction = -1,_delay = .5):
	if _new_direction == -1:
		get_target(left_eye.target_list)
	elif _new_direction == 1:
		get_target(right_eye.target_list)
	await get_tree().create_timer(_delay).timeout
	
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

func get_target(_list = target_list):
	# prioritize the center eye, but if no target found, check the next eyes for 
	# a target to assign
	for new_target in _list:
		if await eyeline_check(new_target):
			target_found.emit(new_target)
			break
	
	
