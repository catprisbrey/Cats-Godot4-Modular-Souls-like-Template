extends InteractableObject
class_name LeverObject

# Called when the node enters the scene tree for the first time.
@onready var opened = false
@onready var lever_anim_player :AnimationPlayer = $LeverAnimPlayer
@export var locked : bool = false
@export var player_offset : Vector3 = Vector3(0,0,1)

var anim

func activate(_requestor,_sensor_loc):
	if locked:
		shake_lever()
		
	else:
		var new_translation = global_transform.translated_local(player_offset).rotated_local(Vector3.UP,PI)

		#new_translation = global_transform.rotated_local(Vector3.UP,PI)
		#new_translation = new_translation.translated_local(Vector3(0,_requestor.global_position.y,-1.5))
		var move_time = .3
		
		if opened == false:
			if _requestor.has_method("start_interact"):
				_requestor.start_interact(interact_type,new_translation, move_time)
				await get_tree().create_timer(move_time).timeout
			open_lever()

func shake_lever():
	lever_anim_player.play("Locked")
	
func open_lever():
	anim = "open"
	lever_anim_player.play(anim)
	opened = true