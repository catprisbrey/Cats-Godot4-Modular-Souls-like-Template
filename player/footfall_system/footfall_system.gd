extends BoneAttachment3D
class_name FootfallSensor

## Set the external skeleton to your character body. Assign the bone to each foot.
## If the raycast isn't pointed down to the floor, adjust its x rotatino.
## The cast will sense and signal each step down and up step action.

signal foot_stepped
signal foot_lifted

@onready var floorcast = $Pivot/Floorcast
@onready var on_floor = true


func _physics_process(_delta):
	reset_step()
	step_check()
	
func reset_step():
	if on_floor:
		if !floorcast.is_colliding():
			foot_lifted.emit()
			on_floor = false
		
func step_check():
	if on_floor == false:
		if floorcast.is_colliding():
			foot_stepped.emit()
			on_floor = true


