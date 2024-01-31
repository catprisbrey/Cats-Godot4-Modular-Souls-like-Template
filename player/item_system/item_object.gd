extends CharacterBody3D
class_name ItemObject

@export var item_info : ItemResource = ItemResource.new()
@onready var carried = true
const SPEED = 10.0
const JUMP_VELOCITY = 4.5
var direction : Vector3

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
	if carried == false:
		free_movement()
		apply_gravity(delta)
	
func throw():
	carried = false
	direction = to_global(Vector3(0,.2,1))

func apply_gravity(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

func free_movement():
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
