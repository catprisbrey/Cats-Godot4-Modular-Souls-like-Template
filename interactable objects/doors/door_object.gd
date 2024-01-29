extends InteractableObject
class_name DoorObject

## This door object expects waits to be told to "activate". Interactables
## typically are on physics layer 4, and in group "Interactable"
## Interacts are a bit of a 'handshake'. The requestor tells the door
## to activate. The door replies back to the requestor a translation and wait time
## so the requestor can be in sync, moving to a good position before running 
## their own "start_door" logic and animations.

@onready var opened = false
@onready var door_anim_player :AnimationPlayer = $DoorAnimPlayer

@export var locked : bool = false
var anim

func activate(_requestor = self,_sensor_loc = Vector3.ZERO):
	if locked:
		shake_door()
		
	else: # detect where the requestor is, and pass them location info to know where to center up.
		var dist_to_front = to_global(Vector3.FORWARD).distance_to(_requestor.global_position)
		var dist_to_back = to_global(Vector3.BACK).distance_to(_requestor.global_position)
		
		var new_translation = global_transform
		if dist_to_front > dist_to_back: # detect which side of the door the player is on.
			new_translation = global_transform.rotated_local(Vector3.UP,PI)
		# update the new_location with the tranfrom info of where the requestor should ideally stand to open the door
		new_translation = new_translation.translated_local(Vector3(0,_requestor.global_position.y,-1))
		var move_time = .3
		
		if opened == false:
			# Requestor 'handshake', to trigger them to take open door actions
			if _requestor.has_method("start_interact"):
				_requestor.start_interact(interact_type,new_translation, move_time)
				await get_tree().create_timer(move_time + .5).timeout
			open_door(dist_to_front, dist_to_back)
			
		if opened == true:
			close_door()



func shake_door():
	door_anim_player.play("Locked")
	
## Based on the requestors updated location from being activated,
## The door will open in or outwards. A signally lever can pass it info
## and it will work just the same.

func open_door(dist_to_front, dist_to_back):
	if !door_anim_player.is_playing():
		if dist_to_front < dist_to_back:
			anim = "OpenLeft"
		else:
			anim = "OpenRight"
		door_anim_player.play(anim)
		opened = true

func close_door(): ## Play the previous open anim backwards to close the correct way
	if !door_anim_player.is_playing():
		door_anim_player.play_backwards(anim)
		opened = false
