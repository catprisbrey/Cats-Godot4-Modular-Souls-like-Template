extends CharacterBody3D

@onready var sensor_cast : ShapeCast3D
@export var animation_tree : AnimationTree
@onready var anim_length = .5 # updates as new animnations start
signal event_finished
## default/1st camera is a follow cam.
@onready var current_camera = get_viewport().get_camera_3d()

## Aids strafe rotation when alternating between cameras. I found it best to keep
## track of whatever the starting camera was, rather than update it if camera's change.
@onready var orientation_target = current_camera

## Interactables that update based on entering a Ladder Area or, the sensor_cast
## colliding with an interactable.
@onready var interactable : Node3D
@onready var ladder
signal climb_started
signal interact_started(interact_type)

## A generic EquipmentSystem class, used to manage moving Weapons 
## between a hand and sheathed location as well as activating collision hitbox 
## monitoring and reporting hits have happened. Very handy.
@export var weapon_system : EquipmentSystem

## A helper variable, tracks the current weapon type for easier referencing from
## the animation_tree and anywhere else that may want to know what weapon type is held.
var weapon_type :String = "SLASH"
signal weapon_change_started ## to start the animation
signal weapon_change_ended(weapon_type:String) ## informing the change is complete
signal attack_started ## to start the animation


## A helper variable for keyboard events across 2 key inputs "shift+ attack", etc.
## there may be a better way to capture combo key presses across multiple device types,
## but this worked for me in a pinch.
var secondary_action

## Gadgets and guarding equipment system that manages moving nodes from the 
## off-hand, to their hip location, the same EquipmentSystem as the weapon system.
@export var gadget_system : EquipmentSystem
## A helper variable, tracks the current gadget type for easier referencing from
## the AnimationStateTree or anywhere else that may need to know what gadget type is held.
var gadget_type :String = "SHIELD"
signal gadget_change_started ## to start the animation
signal gadget_change_ended(gadget_type:String) ## to end the animation
signal gadget_started ## when the gadget attack starts


## When guarding this substate is true. Drives animation and hitbox logic for blocking.
## The first moments of guarding, the parry window is active, allowing to parry()
## attacks and avoid damage


## Turns on when the perfect parry window is active, making regular blocks turn into parries.
@onready var parry_active = false
## How brief the perfect parry window is in seconds.
@export var parry_window = .3
signal parry_started
signal block_started

## The HealthSystem node that will take in information about damage and healing received.
@export var health_system : HealthSystem
@onready var hurt_cool_down = Timer.new() # while running, player can't be hurt
signal hurt_started # to start the animation
signal damage_taken(by_what:EquipmentObject) # to indicate the damage value
signal health_received(by_what:ItemObject)
signal death_started
var is_dead :bool = false

@export var inventory_system : InventorySystem
var current_item : ItemResource
signal item_change_started
signal item_change_ended(current_item:ItemObject)
signal use_item_started
signal item_used

# Jump and Gravity
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var jump_velocity = 4.5
@onready var last_altitude = global_position
@export var hard_landing_height :float = 4 # how far they can fall before 'hard landing'
signal landed_fall(hard_or_soft:String)
signal jump_started

## Dodge and Sprint Mechanics.
@onready var sprint_timer :Timer = Timer.new()
signal dodge_started
signal sprint_started

# Movement Mechanics
var input_dir : Vector2
@export var default_speed = 4.0
@onready var speed = default_speed


# Strafing
var strafing :bool = false # substate
@onready var strafe_cross_product = 0.0
@onready var move_dot_product = 0.0
signal strafe_toggled(toggle:bool)

# Laddering
signal ladder_started(top_or_bottom:String)
signal ladder_finished(top_or_bottom:String)

# State management
enum state {FREE,STATIC,CLIMB}

@onready var busy : bool = false # substate: to prevent input spamming
@onready var guarding = false # substate
@onready var sprinting : bool = false # substate
@onready var dodging : bool = false # substate
@onready var slowed : bool = false # substate:  force a slower walking speed

@onready var current_state = state.STATIC : set = change_state
signal changed_state(new_state: state)

func _ready():
	if animation_tree:
		animation_tree.animation_measured.connect(_on_animation_measured)
		
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
		
	climb_started.connect(_on_climb_started)
		
	add_child(sprint_timer)
	sprint_timer.one_shot = true
	
	hurt_cool_down.one_shot = true
	hurt_cool_down.wait_time = .5
	add_child(hurt_cool_down)

	if animation_tree:
		await animation_tree.animation_measured
	await get_tree().create_timer(anim_length).timeout
	current_state = state.FREE
	
	weapon_change_ended.emit(weapon_type)
	
## Makes variable changes for each state, primiarily used for updating movement speeds
func change_state(new_state):
	current_state = new_state
	changed_state.emit(current_state)
	
	match current_state:
		state.FREE:
			speed = default_speed

		state.STATIC:
			speed = 0.0
			velocity = Vector3.ZERO
	
	if current_state == state.CLIMB:
		system_visible(weapon_system,false)
		system_visible(gadget_system,false)
	else:
		system_visible(weapon_system,true)
		system_visible(gadget_system,true)
			
func _physics_process(_delta):
	match current_state:
		state.FREE:
			rotate_player()
			
		state.CLIMB:
			set_root_climb(_delta)
			
	set_root_move(_delta)
	move_and_slide()
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
		if _event.is_action_pressed("use_weapon_light"):
			attack()
		elif _event.is_action_pressed("use_weapon_strong"):
			attack_strong()
				
		if is_on_floor():
			# if interactable exists, activate its action
			if _event.is_action_pressed("interact"):
				interact()
			
			elif _event.is_action_pressed("jump"):
				jump()
				
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
	
	elif current_state == state.CLIMB:
			#aiming = false
			if _event.is_action_pressed("interact"):
				abort_climb()
	
	if sprinting:
		
		if !input_dir:
			end_sprint()
		
		if _event.is_action_released("dodge_dash"):
			end_sprint()
				
	if _event.is_action_released("use_gadget_light"):
		if not secondary_action:
			end_guard()

func apply_gravity(_delta):
	if !is_on_floor() \
	&& current_state != state.CLIMB:
		velocity.y -= gravity * _delta
		
func rotate_player():
	if busy:
		return
	var rate = .15
	
	var target_rotation
	var current_rotation = global_transform.basis.get_rotation_quaternion()
	# FreeCam rotation code, slerps to input oriented to the camera perspective, and only calculates when input is given
	if strafing:
		rate = .4
		# StrafeCam code - Look at target, slerping current rotation to the camera's rotation.
		target_rotation = current_rotation.slerp(Quaternion(Vector3.UP, orientation_target.global_rotation.y + PI), rate)
		global_transform.basis = Basis(target_rotation)
		var new_direction = calc_direction().normalized()
		
		var forward_vector = global_transform.basis.z.normalized() 
		strafe_cross_product = -forward_vector.cross(new_direction).y
		move_dot_product = forward_vector.dot(new_direction)
		return
	
	if input_dir:
		var new_direction = calc_direction().normalized()
		# Rotate the player per the perspective of the camera
		target_rotation = current_rotation.slerp(Quaternion(Vector3.UP, atan2(new_direction.x, new_direction.z)), rate)
		global_transform.basis = Basis(target_rotation)

func set_strafe_targeting():
	strafing = !strafing
	strafe_toggled.emit(strafing)
	
func _on_target_cleared():
	strafing = false

func attack():
	trigger_event("attack_started")
	
func attack_strong():
	if busy or dodging:
		return
	secondary_action = true
	trigger_event("attack_started")
	await attack_started
	secondary_action = false
	
	
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
			trigger_event("landed_fall")
		last_altitude = null

func dodge_or_sprint():
	if sprint_timer.is_stopped():
		sprint_timer.start(.3)
		await sprint_timer.timeout
		if !dodging && input_dir:
				sprinting = true
				sprint_started.emit() # triggers the change in anim tree
		
func end_sprint():
	sprinting = false
		
	
func dodge(): 
	if dodging:
		return
		
	var strafe_status = strafing
	strafing = false
	dodging = true
	sprint_timer.stop()
	dodge_started.emit()
	if animation_tree:
		await animation_tree.animation_measured
	hurt_cool_down.start(anim_length*.7)
	await get_tree().create_timer(anim_length).timeout
	
	strafing = strafe_status
	dodging = false


func _on_animation_measured(_new_length):
	anim_length = _new_length - .05 # offset slightly for the process frame

func interact():
	if is_on_floor() && !busy:
		if interactable:
			interactable.activate(self)
		elif ladder:
			ladder.activate(self)

func _on_climb_started():
	#interactable = null
	current_state = state.CLIMB
	
func abort_climb():
	if current_state == state.CLIMB:
		last_altitude = global_position
		current_state = state.FREE
	

func weapon_change():
	slowed = true
	trigger_event("weapon_change_started")
	await event_finished
	print(weapon_type)
	weapon_change_ended.emit(weapon_type)
	slowed = false
	
func _on_weapon_equipment_changed(_new_weapon:EquipmentObject):
	weapon_type = _new_weapon.equipment_info.object_type

func _on_gadget_equipment_changed(_new_gadget:EquipmentObject):
	gadget_type = _new_gadget.equipment_info.object_type

func _on_inventory_item_used(_item):
	current_item = _item
	
func gadget_change():
	slowed = true
	trigger_event("gadget_change_started")
	await event_finished
	print(gadget_type)
	gadget_change_ended.emit(gadget_type)
	await get_tree().create_timer(anim_length *.5).timeout
	slowed = false

func item_change():
	slowed = true
	trigger_event("item_change_started")
	await event_finished
	item_change_ended.emit(current_item)
	slowed = false
	
func start_guard(): # Guarding, and for a short window, parring is possible
	slowed = true
	guarding = true
	parry_active = true
	await get_tree().create_timer(parry_window).timeout
	parry_active = false
	
func end_guard():
	guarding = false
	parry_active = false
	slowed = false

func use_gadget(): # emits to start the gadget, and runs some timers before stopping the gadget
	trigger_event("gadget_started")

func hit(_who, _by_what):
	if hurt_cool_down.time_left > 0:
		return
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
	block_started.emit()

func parry():
	parry_started.emit()
	if animation_tree:
		await animation_tree.animation_measured
	await get_tree().create_timer(anim_length).timeout
	hurt_cool_down.start(anim_length)

func hurt():
	hurt_started.emit() # before state change in case on ladder,etc
	if animation_tree:
		await animation_tree.animation_measured
	hurt_cool_down.start(anim_length)
	await get_tree().create_timer(anim_length).timeout

func use_item():
	slowed = true
	
	use_item_started.emit()
	if animation_tree:
		await animation_tree.animation_measured
	await get_tree().create_timer(anim_length * .5).timeout
	item_used.emit()
	await get_tree().create_timer(anim_length * .5).timeout
	slowed = false

func death():
	current_state = state.STATIC
	hurt_cool_down.start(10)
	is_dead = true
	death_started.emit()
	await get_tree().create_timer(3).timeout
	get_tree().reload_current_scene()
		
func system_visible(_system_node,_new_toggle):
		if _system_node:
			_system_node.visible = _new_toggle

func trigger_interact(interact_type:String):
	if busy:
		return
	busy = true
	interact_started.emit(interact_type)
	await animation_tree.animation_measured
	await get_tree().create_timer(anim_length).timeout
	busy = false
		
func trigger_event(signal_name:String):
	if busy or dodging:
		return
	busy = true
	emit_signal(signal_name)
	await animation_tree.animation_measured
	await get_tree().create_timer(anim_length).timeout
	event_finished.emit()
	busy = false


func jump():
	# Handle jump.
	if is_on_floor():
		jump_started.emit()
		await get_tree().create_timer(.2).timeout # for the windup
		velocity.y = jump_velocity

func set_root_move(delta):
	input_dir = Input.get_vector("move_left","move_right","move_up","move_down")
	#set_quaternion(get_quaternion() * animation_tree.get_root_motion_rotation())
	var rate : float # imiates directional change acceleration rate
	if is_on_floor():
		rate = .5
	else:
		rate = .1
	var new_velocity = get_quaternion() * animation_tree.get_root_motion_position() / delta

	if is_on_floor():
		velocity.x = move_toward(velocity.x, new_velocity.x, rate)
		velocity.y = move_toward(velocity.y, new_velocity.y, rate)
		velocity.z = move_toward(velocity.z, new_velocity.z, rate)
	else:
		velocity.x = move_toward(velocity.x, calc_direction().x * speed, rate)
		velocity.z = move_toward(velocity.z, calc_direction().z * speed, rate)

	
func set_root_climb(delta):
	input_dir = Input.get_vector("move_left","move_right","move_up","move_down")
	
	var rate = 2
	var new_velocity = get_quaternion() * animation_tree.get_root_motion_rotation() * animation_tree.get_root_motion_position() / delta
	
	#velocity = lerp (velocity,new_velocity,rate) #buggier than move_toward
	velocity.x = move_toward(velocity.x, new_velocity.x, rate)
	velocity.y = move_toward(velocity.y, new_velocity.y, rate)
	velocity.z = move_toward(velocity.z, new_velocity.z, rate)
	# dismount logic
	if !sensor_cast.is_colliding():
		#print("cast not colliding")
		current_state = state.FREE
		last_altitude = global_position
		var dismount_pos = to_global(Vector3.BACK)
		dismount_pos.y += .5
		var tween = create_tween()

		tween.tween_property(self,"global_position",dismount_pos,.3)
	if is_on_floor():
		current_state = state.FREE
		#free_started.emit()
	
		
func calc_direction() -> Vector3 :
	var new_direction = (current_camera.global_transform.basis.z * input_dir.y + \
	current_camera.global_transform.basis.x * input_dir.x)
	return new_direction
