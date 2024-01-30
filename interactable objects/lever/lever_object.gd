extends InteractableObject
class_name LeverObject

## The physical maniifestation of a boolean haha. Pull the lever, it will
## flip the boolean on of the property_to_switch on the node_to_control

# Called when the node enters the scene tree for the first time.
@export var node_to_control : Node3D
@export var property_to_switch :String = "locked"
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
		var move_time = .3
		
		if opened == false:
			if _requestor.has_method("start_interact"):
				_requestor.start_interact(interact_type,new_translation, move_time)
				await get_tree().create_timer(move_time).timeout
			open_lever()

func shake_lever():
	lever_anim_player.play("locked")
	
func open_lever():
	anim = "open"
	lever_anim_player.play(anim)
	opened = true
	if node_to_control:
		if property_to_switch in node_to_control:
			var new_value = !node_to_control.get(property_to_switch)
			node_to_control.set(property_to_switch,new_value)
