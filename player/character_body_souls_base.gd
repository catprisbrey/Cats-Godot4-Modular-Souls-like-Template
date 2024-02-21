extends CharacterBody3D
class_name CharacterBodySoulsBase

## A semi-smart character controller. Will detect the current camera in use
## and update control orientation to match it. Strafing will lock rotation to
## to face camera perspective, except for dodging actions.

## A LOT of actions here have signals delayed by timers. This is bad form.
## It's bad for production but handy when protoyping new animations and you don't
## want to hard bake where each trigger happens every time you change something.
## Once player animations are finalized, add the signal triggers to the animations
## and remove the timers in the functions here as needed. 

## Manages all animations generally pulling info it needs from states and substates.
@export var anim_state_tree : AnimationTreeSoulsBase
#### When the anim_state_tree starts a new animatino, this variable updates with it's length
@onready var anim_length = .5


## default/1st camera is a follow cam.
@onready var current_camera = get_viewport().get_camera_3d()
## Aids strafe rotation when alternating between cameras
@onready var orientation_target = current_camera

## Sensing interactable objects, like ladders, doors, etc. 
@export var interact_sensor : Node3D
## The sensor that spotted the object, TOP sensor, or BOTTOM sensor.
@onready var interact_loc : String # use "TOP","BOTTOM","BOTH"
## The newly sensed interactable node.
@onready var interactable : Node3D
signal interact_started
signal door_started
signal gate_started
signal chest_started
signal lever_started


## Weapons and attacking equipment system that manages moving nodes from the 
## attacking hand, to their sheathed location
@export var weapon_system : EquipmentSystem
## A helper variable, tracks the current weapon type for easier referencing from
## the anim_state_tree
@onready var attack_combo_timer = Timer.new()
var weapon_type :String = "SLASH"
signal weapon_change_started
signal weapon_changed
signal weapon_change_ended
signal attack_started
signal attack_activated
signal air_attack_started
signal big_attack_started
## A helper variable for keyboard events across 2 key inputs "shift+ attack", etc.
var secondary_action

## Gadgets and guarding equipment system that manages moving nodes from the 
## off-hand, to their hip location
@export var gadget_system : EquipmentSystem
## A helper variable, tracks the current gadget type for easier referencing from
## the anim_state_tree
var gadget_type :String = "SHIELD"
signal gadget_change_started
signal gadget_changed
signal gadget_change_ended
signal gadget_started
signal gadget_activated



## When guarding this substate is true
@onready var guarding = false
## The first moments of guarding, the parry window is active, allowing to parry()
## attacks and avoid damage
@onready var can_be_hurt = true
@onready var parry_active = false
var parry_window = .3
signal parry_started
signal block_started

@export var health_system :Node
signal hurt_started
signal damage_taken
signal health_received
signal death_started
var is_dead :bool = false
signal respawn_started
@export var last_spawn_site : SpawnSite

@export var inventory_system : InventorySystem
var current_item : ItemResource
signal item_change_started
signal item_changed
signal item_change_ended
signal use_item_started
signal item_used

# Jump and Gravity
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var jump_velocity = 4.5
@onready var last_altitude = global_position
@export var hard_landing_height :float = 4 # how far they can fall before 'hard landing'
signal landed_hard
signal jump_started

## Dodge and Sprint Mechanics.
@export var dodge_speed = 10.0
@onready var dodge_timer :Timer = Timer.new()
@onready var sprint_timer :Timer = Timer.new()
@export var sprint_speed = 7.0
signal dodge_started
signal dodge_ended
signal sprint_started

# Movement Mechanics
var input_dir : Vector2
@export var default_speed = 4.0
@export var walk_speed = 1.0
@onready var speed = default_speed
var direction = Vector3.ZERO

# Strafing
var strafing :bool = false
@onready var strafe_cross_product = 0.0
@onready var move_dot_product = 0.0
signal strafe_toggled

# Laddering
@export var ladder_climb_speed = 1.0
signal ladder_started
signal ladder_finished

# State management
enum state {SPAWN,FREE,STATIC_ACTION,DYNAMIC_ACTION,DODGE,SPRINT,LADDER,ATTACK}
@onready var current_state = state.STATIC_ACTION : set = change_state
signal changed_state

func _ready():
	if anim_state_tree:
		anim_state_tree.animation_measured.connect(_on_animation_measured)

	if interact_sensor:
		interact_sensor.interact_updated.connect(_on_interact_updated)
		
	if weapon_system:
		weapon_system.equipment_changed.connect(_on_weapon_equipment_changed)
		_on_weapon_equipment_changed(weapon_system.current_equipment)
		
	if gadget_system:
		gadget_system.equipment_changed.connect(_on_gadget_equipment_changed)
		_on_gadget_equipment_changed(gadget_system.current_equipment)
	
	if inventory_system:
		inventory_system.item_used.connect(_on_inventory_item_used)
			
	if health_system:
		health_system.died.connect(death)
		
		
	add_child(sprint_timer)
	sprint_timer.one_shot = true
	
	add_child(dodge_timer)
	dodge_timer.one_shot = true
	dodge_timer.connect("timeout",_on_dodge_timer_timeout)
	
	add_child(attack_combo_timer)
	attack_combo_timer.one_shot = true
	
	if anim_state_tree:
		await anim_state_tree.animation_measured
	await get_tree().create_timer(anim_length).timeout
	current_state = state.FREE
	
## Makes variable changes for each state, primiarily used for updating movement speeds
func change_state(new_state):
	current_state = new_state
	changed_state.emit(current_state)
	
	match current_state:
		state.FREE:
			speed = default_speed
		state.LADDER:
			speed = ladder_climb_speed
		state.DODGE:
			speed = dodge_speed
		state.SPRINT:
			speed = sprint_speed
		state.DYNAMIC_ACTION:
			speed = walk_speed
		state.STATIC_ACTION:
			speed = 0.0

			
func _physics_process(_delta):
	match current_state:
		state.FREE:
			rotate_player()
			free_movement()

		state.SPRINT:
			rotate_player()
			free_movement()
			
		state.DODGE:
			dash_movement()
			rotate_player()
			
			
		state.LADDER:
			ladder_movement()
			
		state.ATTACK:
			dash_movement()
		
		state.DYNAMIC_ACTION:
			free_movement()
			rotate_player()
			
	apply_gravity(_delta)
	fall_check()
	
func _input(_event:InputEvent):
		# Update current orientation to camera when nothing pressed
	if !Input.is_anything_pressed():
		current_camera = get_viewport().get_camera_3d()
	
	if _event.is_action_pressed("ui_cancel"):
		get_tree().quit()
		
	## strafe toggle on/off
	if _event.is_action_pressed("strafe_target"):
		set_strafe_targeting()
		
	# a helper for keyboard controls, not really used for joypad
	if Input.is_action_pressed("secondary_action"):
		secondary_action = true
	else:
		secondary_action = false
	
	if current_state == state.FREE:
		if is_on_floor():
			# if interactable exists, activate its action
			if _event.is_action_pressed("interact"):
				interact()
			
			elif _event.is_action_pressed("jump"):
				jump()
				
			elif _event.is_action_pressed("use_weapon_light"):
				if secondary_action: # big attack for keyboard
					attack(secondary_action)
				else:
					attack()
					
					
			elif _event.is_action_pressed("use_weapon_strong"):
				attack(secondary_action) # big attack for joypad

			elif _event.is_action_pressed("dodge_dash"):
				dodge_or_sprint()
				
			elif _event.is_action_released("dodge_dash") \
			&& sprint_timer.time_left:
				dodge()
			
			elif _event.is_action_pressed("change_primary"):
				weapon_change()
			elif _event.is_action_pressed("change_secondary"):
				gadget_change()

			elif _event.is_action_pressed("use_gadget_strong"): 
					use_gadget()
					
			elif _event.is_action_pressed("use_gadget_light"):
				if secondary_action:
					use_gadget()
				else:
					start_guard()
			
			elif _event.is_action_pressed("change_item"):
				item_change()
			elif _event.is_action_pressed("use_item"): 
				use_item()
		else: # if not on floor
			if _event.is_action_pressed("use_weapon_light"):
				air_attack()
	
	elif current_state == state.SPRINT:
		
		if _event.is_action_released("dodge_dash"):
			end_sprint()
			
		elif _event.is_action_pressed("jump"):
				jump()
				
	elif current_state == state.LADDER:
		if _event.is_action_pressed("dodge_dash"):
			current_state = state.FREE
				
	if _event.is_action_released("use_gadget_light"):
		if not secondary_action:
			end_guard()
	
func apply_gravity(_delta):
	if !is_on_floor() \
	&& current_state != state.LADDER:
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
	var freelook
	match strafing:
		true:
			## since during dodges we want the player to look where they roll...
			if current_state == state.DODGE:
				freelook = true
			## otherwise just strafe about.
			else:
				freelook = false
		false:
			freelook = true
	
	var target_rotation
	var current_rotation = global_transform.basis.get_rotation_quaternion()
	

	if freelook: 
		# FreeCam rotation code, slerps to input oriented to the camera perspective, and only calculates when input is given
		if input_dir:
			var new_direction = calc_direction().normalized()
			# Rotate the player per the perspective of the camera
			target_rotation = current_rotation.slerp(Quaternion(Vector3.UP, atan2(new_direction.x, new_direction.z)), 0.2)
			global_transform.basis = Basis(target_rotation)
		
	else: 
		# StrafeCam code - Look at target, slerping current rotation to the camera's rotation.
		target_rotation = current_rotation.slerp(Quaternion(Vector3.UP, orientation_target.global_rotation.y + PI), 0.4)
		global_transform.basis = Basis(target_rotation)

		var forward_vector = global_transform.basis.z.normalized() 
		
		var new_direction = calc_direction().normalized()
		strafe_cross_product = -forward_vector.cross(new_direction).y
		move_dot_product = forward_vector.dot(new_direction)

	# Otherwise freelook, which is when not strafing or dodging, as well as, when rolling as you strafe. 

	# move_and_slide() unused here. Controlled by States and free_movement().

func set_strafe_targeting():
	strafing = !strafing
	strafe_toggled.emit(strafing)
	
func _on_target_cleared():
	strafing = false
	
## calculate and return the direction of movement oriented to the current camera
func calc_direction():
	var forward_vector = Vector3(0, 0, 1).rotated(Vector3.UP, current_camera.global_rotation.y)
	var horizontal_vector = Vector3(1, 0, 0).rotated(Vector3.UP, current_camera.global_rotation.y)
	var new_direction = (forward_vector * input_dir.y + horizontal_vector * input_dir.x)
	return new_direction

func attack(_is_special_attack : bool = false):
	current_state = state.ATTACK
	if _is_special_attack:
		big_attack_started.emit()
	else:
		attack_started.emit()
	if anim_state_tree: 
		await anim_state_tree.animation_measured
	await get_tree().create_timer(anim_length *.3).timeout
	attack_activated.emit()
	dash(Vector3.FORWARD,.3) ## delayed dash to move forward during attack animation
	await get_tree().create_timer(anim_length *.7).timeout
	if current_state == state.ATTACK:
		current_state = state.FREE

		
func air_attack():
	air_attack_started.emit()
	current_state = state.DYNAMIC_ACTION
	if anim_state_tree: 
		await anim_state_tree.animation_measured
	await get_tree().create_timer(anim_length *.5).timeout
	attack_activated.emit()
	await get_tree().create_timer(anim_length *.5).timeout
	current_state = state.FREE
	
		


func fall_check():
	## If you leave the floor, store last position.
	## When you land again, compare the distances of both location y values, if greater
	## than the hard_landing_height, then trigger a hard landing. Otherwise, 
	## clear the last_altitude variable.
	if !is_on_floor() && last_altitude == null: 
		last_altitude = global_position
	if is_on_floor() && last_altitude != null:
		var fall_distance = abs(last_altitude.y - global_position.y)
		if fall_distance > hard_landing_height:
			hard_landing()
		last_altitude = null
				
func hard_landing():
		current_state = state.STATIC_ACTION
		landed_hard.emit()
		anim_length = .4
		if anim_state_tree:
			await anim_state_tree.animation_measured
		await get_tree().create_timer(anim_length).timeout
		if current_state == state.STATIC_ACTION:
			current_state = state.FREE
	
func jump():
	if is_on_floor():
		if anim_state_tree:
			jump_started.emit()
			anim_length = .5
			if anim_state_tree:
				await anim_state_tree.animation_measured
			var jump_duration = anim_length
		# After timer finishes, return to pre-dodge state
			await get_tree().create_timer(jump_duration *.7).timeout
		velocity.y = jump_velocity

func dash(_new_direction : Vector3 = Vector3.FORWARD, _duration = .1): 
	# burst of speed toward indicated direction, or forward by default
	speed = dodge_speed
	if _new_direction:
		direction = (global_position - to_global(_new_direction)).normalized()
	#speed = default_speed
	await get_tree().create_timer(_duration).timeout
	direction = Vector3.ZERO
	
func dodge_or_sprint():
	if sprint_timer.is_stopped():
		sprint_timer.start(.3)
		await sprint_timer.timeout
		if current_state == state.FREE \
			&& input_dir:
				current_state = state.SPRINT
				sprint_started.emit()
		
func end_sprint():
	if current_state == state.SPRINT:
		current_state = state.FREE
		
func dash_movement():
	var rate = .1
	velocity.x = move_toward(velocity.x, direction.x * speed, rate)
	velocity.z = move_toward(velocity.z, direction.z * speed, rate)
	# required in the process function states for dodges/dashes
	move_and_slide()
	
func dodge(): 
	# Burst of speed toward an input direction, or backwards
	current_state = state.DODGE
	can_be_hurt = false
	sprint_timer.stop()
	## uses timer rather than 'await' because 'await' stops processes like gravity affecting velocity.
	if input_dir: # Dodge toward direction of input_dir 
		direction = calc_direction()
		dodge_started.emit()
	else: # Dodge toward the 'BACK' of your global position
		var backward_dir =(global_position - to_global(Vector3.BACK)).normalized()
		velocity = backward_dir * (dodge_speed * .75)
		dodge_started.emit()
	if anim_state_tree:
		await anim_state_tree.animation_measured
	# After timer finishes, return to pre-dodge state
	dodge_timer.start(anim_length * .7)
	
func _on_dodge_timer_timeout():
	dodge_ended.emit()
	speed = default_speed
	current_state = state.FREE
	can_be_hurt = true

func ladder_movement():
	# move up and down ladders per the indicated direction
	input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = (Vector3.DOWN * input_dir.y) * speed
	# exiting ladder state triggers:
	last_altitude = global_position
	if interact_loc == "BOTTOM":
		exit_ladder("TOP") 
	if is_on_floor():
		exit_ladder("BOTTOM")
	move_and_slide()

func start_ladder(top_or_bottom,mount_transform):
	ladder_started.emit(top_or_bottom)
	if anim_state_tree:
		await anim_state_tree.animation_measured
	# After timer finishes, return to pre-dodge state
	var tween = create_tween()
	tween.tween_property(self,"global_transform", mount_transform, anim_length *.4)
	await tween.finished
	current_state = state.LADDER
	
func exit_ladder(exit_loc):
	current_state = state.STATIC_ACTION
	ladder_finished.emit(exit_loc)
	var dismount_pos
	if anim_state_tree:
		await anim_state_tree.animation_measured
	match exit_loc:
		"TOP":
			dismount_pos = to_global(Vector3(0,1.5,.5))
		"BOTTOM":
			dismount_pos = global_position
	var tween = create_tween()
	tween.tween_property(self,"global_position", dismount_pos, anim_length * .6)
	await tween.finished
	current_state = state.FREE

func _on_animation_measured(_new_length):
	anim_length = _new_length - .05 # offset slightly for the process frame

func _on_interact_updated(_interactable, _int_loc):
	interactable = _interactable
	interact_loc = _int_loc
	
func interact():
	## interactions are a handshake. The interactable will reply back with more
	## info or actions if needed.
	if interactable:
		interactable.activate(self,interact_loc)

func start_interact(interact_type = "GENERIC", desired_transform :Transform3D = global_transform, move_time : float = .5):
	current_state = state.STATIC_ACTION
	# After timer finishes, return to pre-dodge state
	var tween = create_tween()
	tween.tween_property(self,"global_transform", desired_transform, move_time)
	await tween.finished
	interact_started.emit(interact_type)
	if anim_state_tree:
		await anim_state_tree.animation_measured
	await get_tree().create_timer(anim_length).timeout
	current_state = state.FREE



func weapon_change():
	current_state = state.DYNAMIC_ACTION
	weapon_change_started.emit()
	if anim_state_tree:
		await anim_state_tree.animation_measured
	await get_tree().create_timer(anim_length *.5).timeout
	weapon_changed.emit()
	if weapon_system:
		await weapon_system.equipment_changed
	print(weapon_type)
	weapon_change_ended.emit(weapon_type)
	await get_tree().create_timer(anim_length *.5).timeout
	current_state = state.FREE
	
func _on_weapon_equipment_changed(_new_weapon:EquipmentObject):
	weapon_type = _new_weapon.equipment_info.object_type

func _on_gadget_equipment_changed(_new_gadget:EquipmentObject):
	gadget_type = _new_gadget.equipment_info.object_type

func _on_inventory_item_used(_item):
	current_item = _item
	
func gadget_change():
	current_state = state.DYNAMIC_ACTION
	gadget_change_started.emit()
	if anim_state_tree:
		await anim_state_tree.animation_measured
	await get_tree().create_timer(anim_length *.5).timeout
	gadget_changed.emit()
	if gadget_system:
		await gadget_system.equipment_changed
	print(gadget_type)
	gadget_change_ended.emit(gadget_type)
	await get_tree().create_timer(anim_length *.5).timeout
	current_state = state.FREE

func item_change():
	current_state = state.DYNAMIC_ACTION
	item_change_started.emit()
	if anim_state_tree:
		await anim_state_tree.animation_measured
	await get_tree().create_timer(anim_length *.5).timeout
	item_changed.emit()
	await get_tree().process_frame
	item_change_ended.emit(current_item)
	await get_tree().create_timer(anim_length *.5).timeout
	current_state = state.FREE
	
func start_guard(): # Guarding, and for a short window, parring is possible
	guarding = true
	parry_active = true
	current_state = state.DYNAMIC_ACTION
	await get_tree().create_timer(parry_window).timeout
	parry_active = false
	
func end_guard():
	guarding = false
	parry_active = false
	current_state = state.FREE

func use_gadget(): # emits to start the gadget, and runs some timers before stopping the gadget
	current_state = state.STATIC_ACTION
	gadget_started.emit()
	if anim_state_tree:
		await anim_state_tree.animation_started
	await get_tree().create_timer(anim_length  *.3).timeout
	gadget_activated.emit()
	dash(Vector3.FORWARD,.3)
	await get_tree().create_timer(anim_length  *.7).timeout
	if current_state == state.STATIC_ACTION:
		current_state = state.FREE

func hit(_who, _by_what):
	if can_be_hurt:
		if parry_active:
			parry()
			if _who.has_method("parried"):
				_who.parried()
			return
		elif guarding:
			block()
		else:
			damage_taken.emit(_by_what)
			hurt()

func heal(_by_what):
	health_received.emit(_by_what)

func block():
	current_state = state.STATIC_ACTION
	block_started.emit()
	if anim_state_tree:
		await anim_state_tree.animation_measured
	await get_tree().create_timer(anim_length).timeout
	if current_state == state.STATIC_ACTION:
		current_state = state.DYNAMIC_ACTION

func parry():
	current_state = state.STATIC_ACTION
	can_be_hurt = false
	parry_started.emit()
	if anim_state_tree:
		await anim_state_tree.animation_measured
	await get_tree().create_timer(anim_length).timeout
	if current_state == state.STATIC_ACTION:
		current_state = state.FREE
	can_be_hurt = true

func hurt():
	current_state = state.STATIC_ACTION
	can_be_hurt = false
	hurt_started.emit()
	if anim_state_tree:
		await anim_state_tree.animation_measured
	await get_tree().create_timer(anim_length).timeout
	if !is_dead:
		if current_state == state.STATIC_ACTION:
			current_state = state.FREE
		can_be_hurt = true

func use_item():
	current_state = state.DYNAMIC_ACTION
	use_item_started.emit()
	if anim_state_tree:
		await anim_state_tree.animation_measured
	await get_tree().create_timer(anim_length * .5).timeout
	item_used.emit()
	await get_tree().create_timer(anim_length * .5).timeout
	if current_state == state.DYNAMIC_ACTION:
		current_state = state.FREE

func death():
	current_state = state.STATIC_ACTION
	can_be_hurt = false
	is_dead = true
	death_started.emit()
	await get_tree().create_timer(3).timeout
	get_tree().reload_current_scene()
		
