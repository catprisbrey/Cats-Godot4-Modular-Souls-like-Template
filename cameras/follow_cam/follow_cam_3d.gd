
extends SpringArm3D
class_name FollowCam

## Will follow the global_position of the follow_target and rotate based on 
## mouse or joystick input. If an optional targeting system is added and
## "targeting == true", this node will constantly look at a "look_target", 
## ignoring mouse movement.

## By toggling targeting to false, the camera will return to normal control.

## If the player is guarding, the spring arm lerps to a shorter aim length.
## when not guarding it lerps back to default position.

## The camera by default is has it's H Offset property set to move it over the
## right shoulder. Adjust offset there, not here so that the spring arm/camera
## don't clip through walls.


@export_range(1,50,1) var mouse_sensitivity = 15.0
@export_range(1,50,1) var joystick_sensitivity = 15.0

var targeting = false
signal targeting_changed
@export var camera_3d : Camera3D 
@export var follow_target : Node3D
@onready var default_spring :float = spring_length

## if no target is set, this node will attempt to find a CharacterBody3D to follow
var look_target : Node3D 
@onready var vertical_offset = global_position.y
@export var optional_targeting_system : Node

@export var aim_spring_length :float = .7
signal target_cleared

var current_cam_buffer = true


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if follow_target.has_signal("strafe_toggled"): ## to avoid hard coding using a SignalSwitch
		follow_target.strafe_toggled.connect(_on_strafe_toggled)
	if follow_target.has_method("_on_target_cleared"):
		target_cleared.connect(follow_target._on_target_cleared)
	#
	if optional_targeting_system:
		optional_targeting_system.target_found.connect(_on_target_found)
		
	if camera_3d:
		camera_3d.current = true
	
	target_cleared.connect(_on_target_cleared)
	
func _input(event):
	mouse_control(event)
	
func _physics_process(_delta):
	joystick_control() # run in physics processr ather than event for smoother action
	_follow_target(follow_target)
	_lookat_target()
	_detect_camera_change()
	
## Normal free camera control
func mouse_control(_event):

	if _event is InputEventMouseMotion:
		var new_rotation = rotation.x - _event.relative.y / 10000 * mouse_sensitivity
		rotation.y -= _event.relative.x /  10000 * mouse_sensitivity

		var clamped_rotation = clamp(new_rotation, -.8, 0.8) #rotation clamp
		rotation.x = clamped_rotation
		return

func joystick_control(): # For controlling freecam rotation on gamepad

		#if Input.get_vector("look_left","look_right","look_up","look_down"):
	# Calculate the target rotation
	var joy_input = Input.get_vector("look_left","look_right","look_up","look_down")
	var temporary_rotation = rotation.x + joy_input.y / 400 * joystick_sensitivity
	rotation.y -= joy_input.x / 300 * joystick_sensitivity
	
	var clamped_rotation = clamp(temporary_rotation, -.8, .8)
	rotation.x = clamped_rotation

func _detect_camera_change():
	if camera_3d != get_viewport().get_camera_3d() \
	&& current_cam_buffer:
		current_cam_buffer = false
	elif camera_3d == get_viewport().get_camera_3d() \
	&& current_cam_buffer == false:
		global_rotation.y = follow_target.global_rotation.y + PI
		current_cam_buffer = true
	
func _follow_target(new_target):
	if new_target:
		var target_position = new_target.global_position
		target_position.y += vertical_offset
		var lerp_to_position = lerp(global_position, target_position,.07)
		global_position = lerp_to_position

#### STRAFE / TARGET CAM LOGIC ####
## this section ties heavily into using an optional targeting system node.

func _on_strafe_toggled(_toggle):
	targeting = _toggle
	targeting_changed.emit(targeting)
	if targeting == false:
		target_cleared.emit()
	
func _on_target_found(new_target):
	if new_target:
		look_target = new_target
		
func _lookat_target():
	if look_target: # needed to make sure you don't try to target a freed node.
		#if look_target.is_queued_for_deletion():
		if !look_target.is_in_group("Targets"):
			target_cleared.emit()
			
	if targeting: # otherwise track the target
		if look_target: 
			var vertical_look_offset = Vector3(0,.7,0) ## to not look at the target's feet.
			look_at(look_target.global_position + vertical_look_offset ,Vector3.UP)

	if "guarding" in follow_target:
		if follow_target.guarding:
			spring_length = lerp(spring_length,aim_spring_length,.1)
		else:
			spring_length = lerp(spring_length,default_spring,.1)

func _on_target_cleared():
	look_target = null
