
extends Node3D
class_name FollowCam

@export_range(1,50,1) var mouse_sensitivity = 15.0
@export_range(1,50,1) var joystick_sensitivity = 15.0
var targeting = false
@export var spring_arm_3d : SpringArm3D 
@export var camera_3d : Camera3D 
@export var follow_target : Node3D
## if no target is set, this node will attempt to find a CharacterBody3D to follow
var look_target
@export var optional_targeting_system : TargetingSystem
signal look_target_updated

var current_cam_buffer = true


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_find_a_player()
	_find_targeting_system()
	_setup_cam_and_arm()

func _input(event):
	mouse_control(event)
	
	
func _physics_process(_delta):
	joystick_control()
	_follow_target(follow_target)
	_lookat_target()
	
	_detect_camera_change()
	


## Normal free camera control
func mouse_control(_event):
	if _event is InputEventMouseMotion:
		var new_rotation = rotation.x - _event.relative.y / 10000 * mouse_sensitivity
		rotation.y -= _event.relative.x /  10000 * mouse_sensitivity

		var clamped_rotation = clamp(new_rotation, -.8, 0.6) #rotation clamp
		rotation.x = clamped_rotation
		return

func joystick_control(): # For controlling freecam rotation on gamepad
		#if Input.get_vector("look_left","look_right","look_up","look_down"):
	# Calculate the target rotation
		var joy_input = Input.get_vector("look_left","look_right","look_up","look_down")
		var temporary_rotation = rotation.x + joy_input.y / 400 * joystick_sensitivity
		rotation.y -= joy_input.x / 300 * joystick_sensitivity
		#rotation clamp
		temporary_rotation = clamp(temporary_rotation, -.8, .6)
		rotation.x = temporary_rotation

## This allows you to ignore the spring arm entirely, 
## only worry about placing the camera's z and y position.
func _setup_cam_and_arm():
	if camera_3d == null:
		printerr("WARNING: FollowCam needs a Camera3D set")
	else:
		camera_3d.current = true
		
	if spring_arm_3d == null:
		printerr("WARNING: FollowCam needs a SpringArm3D set")
	else:
		var node_to_cam_dist = global_position.distance_to(camera_3d.global_position)
		spring_arm_3d.set_length(node_to_cam_dist)
		spring_arm_3d.global_position.y = camera_3d.global_position.y
		camera_3d.transform = Transform3D.IDENTITY

func _find_a_player():
	if follow_target == null:
		var the_kids = get_tree().get_root().get_child(0).get_children()
		for each in the_kids:
			if each is CharacterBody3D:
				if each.has_signal("strafe_toggled"):
					follow_target = each
					follow_target.strafe_toggled.connect(_toggle_targeting)
	elif follow_target.has_signal("strafe_toggled"):
		follow_target.strafe_toggled.connect(_toggle_targeting)
				
func _find_targeting_system():
	if optional_targeting_system:
		optional_targeting_system.target_found.connect(_update_target)

func _update_target(new_target):
	if new_target:
		look_target = new_target
		look_target_updated.emit(look_target)

func _follow_target(new_target):
	if new_target:
		var target_position = new_target.global_position
		var lerp_to_position = lerp(global_position, target_position,.07)
		global_position = lerp_to_position
		
func _lookat_target():
	if targeting:
		if look_target:
			look_at(look_target.global_position ,Vector3.UP)
			
func _detect_camera_change():
	if camera_3d != get_viewport().get_camera_3d() \
	&& current_cam_buffer:
		current_cam_buffer = false
	elif camera_3d == get_viewport().get_camera_3d() \
	&& current_cam_buffer == false:
		global_rotation.y = follow_target.global_rotation.y + PI
		current_cam_buffer = true
	
func _toggle_targeting(new_toggle):
	targeting = new_toggle
	if optional_targeting_system:
		if targeting:
			optional_targeting_system._get_closest()
		else:
			optional_targeting_system._clear_lists()
			look_target = null
			look_target_updated.emit(look_target)

