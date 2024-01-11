extends Area3D
class_name GadgetObject

## Uses layer 4 for detecting hitable targets.

@export var gadget_info : GadgetResource

func _ready():
	set_collision_mask_value(3,true)
	set_collision_layer_value(1,false)
