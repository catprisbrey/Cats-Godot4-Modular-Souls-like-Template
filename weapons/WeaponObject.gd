extends Area3D
class_name WeaponObject

## Uses layer 3 for detecting hitable targets.

@export var equipment_info : WeaponResource

func _ready():
	set_collision_mask_value(3,true)
	set_collision_layer_value(1,false)
	monitoring = false

func activate(anim_time):
	# wait before becoming lethal
	await get_tree().create_timer(anim_time*.3).timeout
	# turn on object col shape to detect collisions
	monitoring = true
	print("Object active")
	
func deactivate():
	monitoring = false
	print("Object inactive")
