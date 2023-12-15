extends Area3D

@onready var camera_3d : Camera3D = $Camera3D

# Called when the node enters the scene tree for the first time.
func _ready():
	body_entered.connect(_add_cam)
	body_exited.connect(_drop_cam)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _add_cam(body):
	print("body seen!")
	if body.is_in_group("Player"):
		camera_3d.current = true

func _drop_cam(body):
	print("body left!")
	if body.is_in_group("Player"):
		camera_3d.current = false
