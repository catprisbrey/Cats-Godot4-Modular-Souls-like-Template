
extends SpringArm3D
class_name FollowCam

## Will follow the global_position of the follow_target and rotate based on 
## mouse or joystick input. If an optional targeting system is added and
## "targeting == true", this node will constantly look at a "look_target", 
## ignoring mouse movement.

##By toggling targeting to false, the camera will return to normal control.


@export_range(1,50,1) var mouse_sensitivity = 15.0
@export_range(1,50,1) var joystick_sensitivity = 15.0

var targeting = false
@export var camera_3d : Camera3D 
@export var follow_target : Node3D
## if no target is set, this node will attempt to find a CharacterBody3D to follow
var look_target
@onready var vertical_offset = global_position.y
@export var optional_targeting_system : TargetingSystem

signal target_cleared

var current_cam_buffer = true


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	#if follow_target.has_signal("strafe_toggled"): ## to avoid hard coding using a SignalSwitch
		#follow_target.strafe_toggled.connect(_on_strafe_toggled)
	
	if optional_targeting_system:

		optional_targeting_system.targeting_changed.connect(_on_targeting_changed)
		optional_targeting_system.target_found.connect(_on_target_found)
		#if follow_target: ## to avoid hard coding using a SignalSwitch
			#follow_target.strafe_toggled.connect(optional_targeting_system.set_targeting)
	if camera_3d:
		camera_3d.current = true

func _input(event):
	mouse_control(event)
	
func _physics_process(_delta):
	joystick_control() # run in physics processr ather than event for smoother action
	_follow_target(follow_target)
	_lookat_target()
	_detect_camera_change()
	
## Normal free camera control
func mouse_control(_event):
	if targeting == false:
		if _event is InputEventMouseMotion:
			var new_rotation = rotation.x - _event.relative.y / 10000 * mouse_sensitivity
			rotation.y -= _event.relative.x /  10000 * mouse_sensitivity

			var clamped_rotation = clamp(new_rotation, -.8, 0.8) #rotation clamp
			rotation.x = clamped_rotation
			return

func joystick_control(): # For controlling freecam rotation on gamepad
	if targeting == false:
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

#### STAFE / TARGET CAM LOGIC ####
## this section ties heavily into using an optional targeting system node.

func _on_strafe_toggled(_toggle):
	targeting = _toggle
		
func _on_target_found(new_target):
	if new_target:
		look_target = new_target

func _on_targeting_changed(_toggle):
	targeting = _toggle
	if !_toggle:
		look_target = null
		target_cleared.emit()
		
func _lookat_target():
	if targeting:
		if look_target:
			var vertical_look_offset = Vector3(0,.7,0) ## to not look at the target's feet.
			look_at(look_target.global_position + vertical_look_offset ,Vector3.UP)
			



