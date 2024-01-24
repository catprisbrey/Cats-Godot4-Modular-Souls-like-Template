extends BoneAttachment3D
class_name FootfallSensor

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


