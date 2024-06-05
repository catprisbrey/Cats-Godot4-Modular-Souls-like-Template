extends StaticBody3D
class_name InteractableObject

@export var group_name :String = "interactable"
@export_flags_3d_physics var physical_layer = 8

signal interactable_activated

func _ready():
	add_to_group(group_name,true)
	collision_layer = physical_layer

func activate(_requestor: CharacterBody3D):
	interactable_activated.emit()
