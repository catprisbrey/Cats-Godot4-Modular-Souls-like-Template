extends BoneAttachment3D
class_name FootfallSensor

signal foot_stepped

@onready var floorcast = $Pivot/Floorcast
@onready var on_floor = true


func _physics_process(_delta):
	reset_step()
	step_check()
	
func reset_step():
	if !floorcast.is_colliding():
		on_floor = false
		
func step_check():
	if on_floor == false:
		if floorcast.is_colliding():
			foot_stepped.emit()
			on_floor = true


