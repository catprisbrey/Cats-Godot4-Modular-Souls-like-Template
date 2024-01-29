extends InteractableObject
class_name ChestObject

# Called when the node enters the scene tree for the first time.
@onready var opened = false
@onready var chest_anim_player :AnimationPlayer = $ChestAnimPlayer

@export var locked : bool = false
var anim

func activate(_requestor,_sensor_loc):
	if locked:
		shake_chest()
		
	else:
		var dist_to_front = to_global(Vector3.FORWARD).distance_to(_requestor.global_position)
		var dist_to_back = to_global(Vector3.BACK).distance_to(_requestor.global_position)
		
		var new_translation = global_transform
		if dist_to_front > dist_to_back:
			new_translation = global_transform.rotated_local(Vector3.UP,PI)
		new_translation = new_translation.translated_local(Vector3(0,_requestor.global_position.y,-1.5))
		var move_time = .3
		
		if opened == false:
			if _requestor.has_method("start_interact"):
				_requestor.start_interact(interact_type,new_translation, move_time)
				await get_tree().create_timer(move_time + .7).timeout
			open_chest()

func shake_chest():
	chest_anim_player.play("Locked")
	
func open_chest():
	anim = "open"
	chest_anim_player.play(anim)
	opened = true
