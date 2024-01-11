extends Area3D
class_name GadgetObject

## Uses layer 3 for detecting hitable targets.

@export var gadget_info : GadgetResource

func _ready():
	set_collision_mask_value(3,true)
	set_collision_layer_value(1,false)
	monitoring = false

func activete(anim_time):
	# wait before becoming lethal
	await get_tree().create_timer(anim_time*.3).timeout
	# turn on object col shape to detect collisions
	monitoring = true
	# leave on for half the animation length
	await get_tree().create_timer(anim_time*.5).timeout
	# turn off the col shape detection
	monitoring = false

	
