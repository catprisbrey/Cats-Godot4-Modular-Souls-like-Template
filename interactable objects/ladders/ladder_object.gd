extends InteractableObject
class_name LadderObject

## This ladder object expects waits to be told to "activate". Interactables
## typically are on physics layer 4, and in group "Interactable"
## Interacts are a bit of a 'handshake'. The requestor tells the ladder
## to activate. The ladder replies back to the requestor if they're at the top
## or the bottom of the ladder, and where to stand in order to mount the ladder.
## This way the requestor can run their own "start_ladder" logic and animations.

var loc_at_ladder
var mount_transform
## Distance from the rungs the player should move to.
@export var ladder_offset : float = .4 

func activate(_requestor: CharacterBodySoulsBase,_sensor_top_or_bottom :String):
	interactable_activated.emit()
	
	var newTranslation = global_transform.rotated_local(Vector3.UP,PI)
	if _sensor_top_or_bottom == "BOTTOM":
		loc_at_ladder = "TOP"
		mount_transform = newTranslation.translated_local(Vector3(0,-1.25
		 + _requestor.global_position.y,-.4))
	else:
		loc_at_ladder = "BOTTOM"
		mount_transform = newTranslation.translated_local(Vector3(0,0,-.4))
		mount_transform.origin.y = _requestor.transform.origin.y + .25
		
	if _requestor.has_method("start_ladder"):
		_requestor.start_ladder(loc_at_ladder,mount_transform)
	
