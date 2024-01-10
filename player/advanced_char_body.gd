extends CharacterBody3D

## A semi-smart character controller. Will detect the current camera in use
## and update control orientation to match it. Strafing will lock rotation to
## to face camera perspective, except for dodging actions.
@export var anim_state_tree : AnimationTree
@onready var anim_length = .5

@export var interact_sensor : Node3D
@onready var interact_loc : String # use "TOP","BOTTOM","BOTH"
@onready var interactable

@onready var current_camera = get_viewport().get_camera_3d()
# This target aids strafe rotation when alternating between cameras, but the 
# default/1st camera is a follow cam.
@onready var orientation_target = current_camera

###SIGNAL TESTS ####
signal jump_triggered

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var jump_velocity = 4.5
signal jump_started

# Dodge Mechanics
@export var dodge_speed = 9.0

signal dodge_started
signal dodge_ended

# Movement Mechanics
var input_dir : Vector2
var strafing :bool = false
var strafe_cross_product #: Vector3
var move_dot_product
signal strafe_toggled

@export var default_speed = 5.0
@onready var speed = default_speed
var direction = Vector3.ZERO

var ladder_top_or_bottom
var ladder_mount_trans
var ladder_dismount_pos
var climb_speed = 1.0
signal ladder_started
signal ladder_finished


enum state {FREE,ACTION,DODGE,LADDER,ATTACK,AIRATTACK}
@onready var current_state = state.FREE : set = change_state
signal changed_state

func _ready():
	if anim_state_tree:
		anim_state_tree.animation_measured.connect(update_animation_length)
		#anim_state_tree.animation_finished.connect(reset_attack_state)
	if interact_sensor:
		interact_sensor.interact_updated.connect(update_interact)
		
func change_state(new_state):
	current_state = new_state
	print("current state is " + str(current_state))
	changed_state.emit(current_state)
	match current_state:
		state.FREE:
			speed = default_speed
		state.LADDER:
			speed = climb_speed
		state.DODGE:
			speed = dodge_speed

#func reset_attack_state(_anim):
	#if current_state == state.ATTACK:
		#current_state = state.FREE

func _input(_event:InputEvent):
	if _event.is_action_pressed("ui_cancel"):
		get_tree().quit()
		
	if current_state == state.FREE:

			
		if is_on_floor():
			if _event.is_action_pressed("interact"):
				interact()
				
			elif _event.is_action_pressed("jump"):
				jump()
			
			elif _event.is_action_pressed("use_weapon"):
				attack()
			# dodge
			elif _event.is_action_pressed("dodge_dash"):
				dodge()
				
				# strafe toggle on/off
			elif _event.is_action_pressed("strafe_target"):
				strafing = !strafing
				strafe_toggled.emit(strafing)
			
		else: # if not on floor
			if _event.is_action_pressed("use_weapon"):
				air_attack()
			# Update current orientation to camera when nothing pressed
		if !Input.is_anything_pressed():
			current_camera = get_viewport().get_camera_3d()

func _physics_process(_delta):
	apply_gravity(_delta)
	match current_state:
		state.FREE:
			rotate_player()
			free_movement()
			
		state.DODGE:
			rotate_player()
			dash_movement()
			
		state.LADDER:
			ladder_movement()
			
		state.ATTACK:
			dash_movement()
			
		state.AIRATTACK:
			move_and_slide()
			if is_on_floor():
				current_state = state.FREE
			
func apply_gravity(_delta):
	if !is_on_floor() && \
	current_state != state.LADDER:
		velocity.y -= gravity * _delta
		
func free_movement():
	# Get the movement orientation from the angles of the player to the camera.
	# Using only camera's basis rotation created weird speed inconsistencies at downward angles
	#dodge_movement()
	input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
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
	if strafing == true && current_state != state.DODGE: # Strafing looks at enemy
		target_rotation = current_rotation.slerp(Quaternion(Vector3.UP, orientation_target.global_rotation.y + PI), 0.4)
		global_transform.basis = Basis(target_rotation)
		#print(transform.basis * Vector3(input_dir.x,0,input_dir.y))
				# Assuming forwardVector and newMovementDirection are your vectors
		var forward_vector = global_transform.basis.z.normalized() # Example: Forward vector of the character
		
		strafe_cross_product = -forward_vector.cross(calc_direction().normalized()).y
		move_dot_product = forward_vector.dot(calc_direction().normalized())
		print(strafe_cross_product)
		print(move_dot_product)
	# Otherwise freelook, which is when not strafing or dodging, as well as, when rolling as you strafe. 
	elif (strafing == false and current_state != state.DODGE) or (strafing == true and current_state == state.DODGE): # .... else:
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
	var new_direction = (forward_vector * input_dir.y + horizontal_vector * input_dir.x)
	return new_direction

func attack():
	current_state = state.ATTACK
	speed = 0.0
	if anim_state_tree:
		await anim_state_tree.animation_started
		var attack_duration = anim_length
		await get_tree().create_timer(attack_duration *.45).timeout
		dash()
		await get_tree().create_timer(attack_duration *.3).timeout
	else:
		await get_tree().create_timer(.3).timeout
		dash()
	if current_state == state.ATTACK:
		current_state = state.FREE

func air_attack():
	current_state = state.AIRATTACK
		
func jump():
	if anim_state_tree:
		jump_started.emit()
		await anim_state_tree.animation_measured
		var jump_duration = anim_length
	# After timer finishes, return to pre-dodge state
		await get_tree().create_timer(jump_duration *.7).timeout
	velocity.y = jump_velocity

func dash(_new_direction : Vector3 = Vector3.FORWARD): 
	# burst of speed toward indicated direction, or forward by default
	speed = dodge_speed
	direction = (global_position - to_global(_new_direction)).normalized()
	var dash_duration = .1
	await get_tree().create_timer(dash_duration).timeout
	speed = default_speed
	direction = Vector3.ZERO
	velocity = direction * speed
	move_and_slide()
		
func dodge(): 
	# Burst of speed toward an input direction, or backwards
	current_state = state.DODGE
	var dodge_duration : float = .5
	speed = dodge_speed
	if input_dir: # Dodge toward direction of input_dir 
		direction = calc_direction()
		dodge_started.emit("FORWARD")

	else: # Dodge toward the 'BACK' of your global position
		direction = (global_position - to_global(Vector3.BACK)).normalized()
		dodge_started.emit("BACK")
	if anim_state_tree:
		await anim_state_tree.animation_measured
		dodge_duration = anim_length
	# After timer finishes, return to pre-dodge state
	await get_tree().create_timer(dodge_duration).timeout
	dodge_ended.emit()
	current_state = state.FREE
	speed = default_speed
	direction = Vector3.ZERO
		
func dash_movement():
	# required in the process function states for dodges/dashes
	velocity = direction * speed
	move_and_slide()
	
func ladder_movement():
	# move up and down ladders per the indicated direction
	input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = (Vector3.DOWN * input_dir.y) * speed
	# exiting ladder state triggers:
	if interact_loc == "BOTTOM":
		exit_ladder("TOP") 
	if is_on_floor():
		exit_ladder("BOTTOM")
	move_and_slide()

func start_ladder(top_or_bottom,mount_transform):
	ladder_started.emit(top_or_bottom)
	var wait_time = .4
	# After timer finishes, return to pre-dodge state
	var tween = create_tween()
	tween.tween_property(self,"global_transform", mount_transform, wait_time)
	await tween.finished
	current_state = state.LADDER

func exit_ladder(exit_loc):
	current_state = state.ACTION
	ladder_finished.emit(exit_loc)
	var dismount_pos
	var dismount_time = .3
	if anim_state_tree:
		await anim_state_tree.animation_measured
		dismount_time = anim_length *.6
	match exit_loc:
		"TOP":
			dismount_pos = to_global(Vector3(0,1.5,.5))
		"BOTTOM":
			dismount_pos = global_position
	var tween = create_tween()
	tween.tween_property(self,"global_position", dismount_pos,dismount_time)
	await tween.finished
	current_state = state.FREE

func update_animation_length(new_length):
	anim_length = new_length - .05 # offset slightly for the process frame
	print("Anim Length: " + str(anim_length))

func update_interact(int_bottom, int_top):
	## This updates the interactable objects and
	## which sensor spotted it if you have an 
	## if an interact sensor added to the export.
	if int_bottom && int_top:
		interactable = int_bottom
		interact_loc = "BOTH"
	elif int_bottom && int_top == null:
		interactable = int_bottom
		interact_loc = "BOTTOM"
	elif int_bottom == null && int_top:
		interactable = int_top
		interact_loc = "TOP"
	else:
		interactable = null
		interact_loc = ""
	print(str(interactable) + " at " + interact_loc)
	
func interact():
	## The only command passed to interactable objects:
	## the command passes the player node, and which sensor,
	## TOP/BOTTOM/BOTH sees the interactable
	if interactable:
		interactable.activate(self,interact_loc)
