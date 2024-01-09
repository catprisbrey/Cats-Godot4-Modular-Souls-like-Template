extends StaticBody3D

var top_or_bottom
var mount_transform
## Distance from the rungs the player should move to.
@export var ladder_offset : float = .4 

func activate(_player_node:CharacterBody3D,sensor_location):
	var newTranslation = global_transform.rotated_local(Vector3.UP,PI)
	if sensor_location == "BOTTOM":
		top_or_bottom = "TOP"
		mount_transform = newTranslation.translated_local(Vector3(0,-1
		 + _player_node.global_position.y,-.4))
	else:
		top_or_bottom = "BOTTOM"
		mount_transform = newTranslation.translated_local(Vector3(0,.5,-.4))
	_player_node.start_ladder(top_or_bottom,mount_transform)
	
