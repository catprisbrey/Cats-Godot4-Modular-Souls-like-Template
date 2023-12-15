extends CharacterBody3D

## A semi-smart character controller. Will detect the current camera in use
## and update control orientation to match it. Strafing will lock rotation to
## to face camera perspective, except for dodging actions.


@onready var current_camera = get_viewport().get_camera_3d()
# This target aids strafe rotation when alternating between cameras, but the 
# default/1st camera is a follow cam.
@onready var orientation_target = current_camera


var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var jump_velocity = 4.5

# Dodge Mechanics
@export var dodge_speed = 10.0
var dodging : bool = false
var dodge_buffer :float = .5
var dodge_buffer_timer :Timer = Timer.new()
signal dodge_started
signal dodge_ended

# Movement Mechanics
var input_dir : Vector2
var strafing :bool = false
signal strafe_toggled

@export var default_speed = 5.0
@onready var speed = default_speed
var direction = Vector3.ZERO

func _init():
	dodge_buffer_timer.one_shot = true
	dodge_buffer_timer.wait_time = dodge_buffer
	add_child(dodge_buffer_timer)

func _input(_event:InputEvent):
	
	if _event.is_action_pressed("ui_select"):
		jump()
		
	if _event.is_action_pressed("ui_focus_next"):
		dodge()
		
	# strafe toggle on/off
	if _event.is_action_pressed("ui_text_backspace"):
		strafing = !strafing
		strafe_toggled.emit(strafing)
	
	# when direction input stops, get the latest camera
	if _event.is_action_released("ui_left") \
	or _event.is_action_released("ui_right") \
	or _event.is_action_released("ui_up") \
	or _event.is_action_released("ui_down"):
		current_camera = get_viewport().get_camera_3d()


func _physics_process(_delta):
	apply_gravity(_delta)
	rotate_player()

	if dodging:
		dodge_player()

	else:
		move_player()


func apply_gravity(_delta):
	if !is_on_floor():
		velocity.y -= gravity * _delta
		
func move_player():
	# Get the movement orientation from the angles of the player to the camera.
	# Using only camera's basis rotation created weird speed inconsistencies at downward angles
	#dodge_movement()
	input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var new_direction = calc_direction()
	if new_direction:
		var rate : float # imiates directional change acceleration rate
		if is_on_floor():
			rate = .5
		else:
			rate = .1 # Makes it hard to change directions once in midair
		velocity.x = move_toward(velocity.x, new_direction.x * speed, rate)
		velocity.z = move_toward(velocity.z, new_direction.z * speed, rate)
	else: # Smoothly come to a stop
		velocity.x = move_toward(velocity.x, 0, .5)
		velocity.z = move_toward(velocity.z, 0, .5)
	move_and_slide()
	
func rotate_player():
	var target_rotation
	var current_rotation = global_transform.basis.get_rotation_quaternion()
	
	# StrafeCam code - Look at target, slerping current rotation to the camera's rotation.
	if strafing == true && dodging == false: # Strafing looks at enemy
		target_rotation = current_rotation.slerp(Quaternion(Vector3.UP, orientation_target.global_rotation.y + PI), 0.4)
		global_transform.basis = Basis(target_rotation)
	
	# Otherwise freelook, which is when not strafing or dodging, as well as, when rolling as you strafe. 
	elif (strafing == false and dodging == false) or (strafing == true && dodging == true): # .... else:
		
		# FreeCam rotation code, slerps to input oriented to the camera perspective, and only calculates when input is given
		if input_dir:
			var new_direction = calc_direction().normalized()
		# Rotate the player per the perspective of the camera
			target_rotation = current_rotation.slerp(Quaternion(Vector3.UP, atan2(new_direction.x, new_direction.z)), 0.2)
			global_transform.basis = Basis(target_rotation)
	# move_and_slide() unused. (controlled by States).

func calc_direction():
	# calculate and return the direction of movement oriented to the current camera
	var forward_vector = Vector3(0, 0, 1).rotated(Vector3.UP, current_camera.global_rotation.y)
	var horizontal_vector = Vector3(1, 0, 0).rotated(Vector3.UP, current_camera.global_rotation.y)
	direction = (forward_vector * input_dir.y + horizontal_vector * input_dir.x)
	return direction

func jump():
	if is_on_floor() \
	&& dodging == false:
		velocity.y = jump_velocity

func dodge():
	if is_on_floor() \
	&& dodge_buffer_timer.is_stopped() \
	&& dodging == false:
		dodging = true
		dodge_buffer_timer.start()
		
func dodge_player(_new_direction : Vector3 = Vector3.ZERO):
		var dodge_duration : float
		speed = dodge_speed
		if _new_direction != Vector3.ZERO: # If a direction is passed to the dodge command
			direction = (global_position - to_global(_new_direction)).normalized()
			dodge_duration = .1
		elif input_dir: # Dodge toward direction of input_dir 
			dodge_started.emit()
			direction = calc_direction()
			dodge_duration = .25
		else: # Dodge toward the 'BACK' of your global position
			dodge_started.emit()
			direction = (global_position - to_global(Vector3.BACK)).normalized()
			dodge_duration = .15
		velocity = direction * dodge_speed
		move_and_slide()
		await get_tree().create_timer(dodge_duration).timeout
		dodge_ended.emit()
		dodging = false
		speed = default_speed
		direction = Vector3.ZERO

### used with the targeting cam and target sensor to 
#func _find_targeting_system():
	#if optional_follow_cam == FollowCam :
		#optional_follow_cam.look_target_updated.connect(_update_target)
		#
#func _update_target(new_target):
	#print("target_updated")
	#if new_target != null:
		#orientation_target = new_target
	#else: 
		#orientation_target = current_camera
