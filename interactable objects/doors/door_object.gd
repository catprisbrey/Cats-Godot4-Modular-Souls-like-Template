extends StaticBody3D
class_name DoorObject

@onready var opened = false
@onready var door_anim_player :AnimationPlayer = $DoorAnimPlayer

@export var locked : bool = false
var anim


func get_type():
	return type

func activate(_requestor,_sensor_loc):
	if locked:
		shake_door()
		
	else:
		var dist_to_front = to_global(Vector3.FORWARD).distance_to(_requestor.global_position)
		var dist_to_back = to_global(Vector3.BACK).distance_to(_requestor.global_position)
		
		var new_translation = global_transform
		if dist_to_front > dist_to_back:
			new_translation = global_transform.rotated_local(Vector3.UP,PI)
		new_translation = new_translation.translated_local(Vector3(0,_requestor.global_position.y,-1))
		var move_time = .3
		
		if opened == false:
			_requestor.start_door(new_translation, move_time)
			await get_tree().create_timer(move_time + .5).timeout
			open_door(dist_to_front, dist_to_back)
			
		if opened == true:
			close_door()

func shake_door():
	door_anim_player.play("Locked")
	
func open_door(dist_to_front, dist_to_back):
	if !door_anim_player.is_playing():
		if dist_to_front < dist_to_back:
			anim = "OpenLeft"
		else:
			anim = "OpenRight"
		door_anim_player.play(anim)
		opened = true

func close_door():
	if !door_anim_player.is_playing():
		door_anim_player.play_backwards(anim)
		opened = false
