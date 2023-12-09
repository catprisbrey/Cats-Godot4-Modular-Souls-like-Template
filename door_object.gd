extends Node3D
class_name DoorObject

@onready var opened = false
@onready var door_anim_player = $DoorAnimPlayer


func activate(_requestor):
	var dist_to_front = to_global(Vector3.FORWARD).distance_to(_requestor.global_position)
	var dist_to_back = to_global(Vector3.BACK).distance_to(_requestor.global_position)
	
	if opened == false:
		open_door(dist_to_front, dist_to_back)
		
	if opened == true:
		close_door(dist_to_front, dist_to_back)

func open_door(dist_to_front, dist_to_back):
	if !door_anim_player.is_playing():
		if dist_to_front < dist_to_back:
			door_anim_player.play("OpenLeft")
		else:
			door_anim_player.play("OpenRight")
		opened = true

func close_door(dist_to_front, dist_to_back):
	if !door_anim_player.is_playing():
		if dist_to_front < dist_to_back:
			door_anim_player.play("CloseLeft")
		else:
			door_anim_player.play("CloseRight")
		opened = false
