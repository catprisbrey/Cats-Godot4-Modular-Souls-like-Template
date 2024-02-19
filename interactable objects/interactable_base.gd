extends StaticBody3D
class_name InteractableObject

@export_enum("GENERIC","DOOR","GATE","CHEST","LEVER","LADDER") var interact_type : String = "GENERIC"
@export var group_name :String = "Interactable"
@export_flags_3d_physics var physical_layer = 8

func _ready():
	add_to_group(group_name,true)
	collision_layer = physical_layer
