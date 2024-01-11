extends Area3D
class_name WeaponObject

## Uses layer 4 for detecting hitable targets.

@export var weapon_info : WeaponResource

func _ready():
	set_collision_mask_value(3,true)
	set_collision_layer_value(1,false)
