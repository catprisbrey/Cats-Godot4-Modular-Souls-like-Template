extends Node3D

@export_range(1,50,1) var mouse_sensitivity = 15.0
var targeting = false
@onready var spring_arm_3d : SpringArm3D= $SpringArm3D
@onready var camera_3d : Camera3D = $SpringArm3D/Camera3D
@export var follow_target : Node3D

var current_cam_buffer = true
	
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_setup_spring_arm()
	camera_3d.current = true
	
func _input(event):
	if targeting == true:
		select_target(event)
	else:
		mouse_control(event)

func _physics_process(delta):
	_follow_target(follow_target.global_position)
	_detect_camera_change()

## Function for sensing direction of target to select
func select_target(_event): 
		if _event is InputEventMouseMotion:
			if abs(_event.relative.x) > 300: # check if timer is active
				# Calculate the direction of the mouse movement
				var direction = sign(_event.relative.x)
				#ChangeTarget(direction, .3)
		elif _event is InputEventJoypadMotion:
			if _event.axis == 2 && abs(_event.axis_value) > .3:
				var direction = sign(_event.axis_value)
				#ChangeTarget(direction, .2)
				#print(direction) # for targetting debugging

## Normal free camera control
func mouse_control(_event):
	if _event is InputEventMouseMotion:
		var temporary_rotation = rotation.x - _event.relative.y / 10000 * mouse_sensitivity
		rotation.y -= _event.relative.x /  10000 * mouse_sensitivity
		#rotation clamp
		temporary_rotation = clamp(temporary_rotation, -.8, 0.6)
		rotation.x = temporary_rotation
		return

## This allows you to ignore the spring arm entirely, 
## only worry about placing the camera's z and y position.
func _setup_spring_arm():
	var node_to_cam_dist = global_position.distance_to(camera_3d.global_position)
	spring_arm_3d.set_length(node_to_cam_dist)
	spring_arm_3d.global_position.y = camera_3d.global_position.y
	camera_3d.transform = Transform3D.IDENTITY

func _follow_target(target_position: Vector3):
	var lerp_to_position = lerp(global_position, target_position,.07)
	global_position = lerp_to_position
	
func _detect_camera_change():
	if camera_3d != get_viewport().get_camera_3d() \
	&& current_cam_buffer:
		current_cam_buffer = false
	elif camera_3d == get_viewport().get_camera_3d() \
	&& current_cam_buffer == false:
		global_rotation.y = follow_target.global_rotation.y + PI
		current_cam_buffer = true
	
#func Change_CameraMode():
	##Changes camera location, height and spring length dependingg on whether
	## in free, or targeting camera mode.
	#
	## Make camera follow the character's global position
	#var LerpToPlayer = lerp(global_position, player_body.global_position + Vector3(0,camera_height_final,0),.07)
	#global_position = LerpToPlayer
	#
	## Stafing and lockon logic
	#if Targeting == true:
		## If locked on to a target, boost the camera taller, and extend spring length
		#camera_height_final = lerp(camera_height_final, camera_height + target_cam_height_boost, .08)
		#spring_arm_3d.spring_length = lerp(spring_arm_3d.spring_length,target_cam_spring_length, .05)
		#if closest_body != null:
			#look_at(closest_body.global_position + Vector3(0,(camera_height),0))
			##Dead cancel logic
			#if closest_body.health < 0:
				#await get_tree().create_timer(.1).timeout
				##ChangeTarget(0,.2)
	#else:
		## if not locked on, smoothly bring the camera back down
		#camera_height_final = lerp(camera_height_final, camera_height, .05)
		#spring_arm_3d.spring_length = lerp(spring_arm_3d.spring_length, free_cam_spring_length, .1)
		#spring_arm_3d.position = get_parent().global_position
		## Set closest body as target when entered, if no target already exists
		#closest_body = null
