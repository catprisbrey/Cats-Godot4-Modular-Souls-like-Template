extends InteractableObject
class_name LadderObject

## This ladder object expects waits to be told to "activate". Interactables
## typically are on physics layer 4, and in group "Interactable"
## Interacts are a bit of a 'handshake'. The requestor tells the ladder
## to activate. The ladder replies back to the requestor if they're at the top
## or the bottom of the ladder, and where to stand in order to mount the ladder.
## This way the requestor can run their own "start_ladder" logic and animations.

var top_or_bottom
var mount_transform
## Distance from the rungs the player should move to.
@export var ladder_offset : float = .4 

func activate(_requestor: Node3D,sensor_location = "BOTTOM"):
	var newTranslation = global_transform.rotated_local(Vector3.UP,PI)
	if sensor_location == "BOTTOM":
		top_or_bottom = "TOP"
		mount_transform = newTranslation.translated_local(Vector3(0,-1.4
		 + _requestor.global_position.y,-.4))
	else:
		top_or_bottom = "BOTTOM"
		mount_transform = newTranslation.translated_local(Vector3(0,0,-.4))
		mount_transform.origin.y = _requestor.transform.origin.y + .5
		
	if _requestor.has_method("start_ladder"):
		_requestor.start_ladder(top_or_bottom,mount_transform)
	
