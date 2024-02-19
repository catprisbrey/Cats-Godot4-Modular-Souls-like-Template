extends PathFollow3D
class_name PatrolPoint

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	progress += .02
