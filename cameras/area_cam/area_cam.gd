extends Area3D

## This node can use a built in camera or use one you've determined
## The builtin camera will queue_free at runtime if a new camera is used. 
@export var camera_3d : Camera3D
@onready var builtin : Camera3D = $Pivot/Camera3D

# Called when the node enters the scene tree for the first time.
func _ready():
	if camera_3d:
		builtin.queue_free()
	else:
		camera_3d = builtin
	 
	body_entered.connect(_add_cam)
	body_exited.connect(_drop_cam)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _add_cam(body):
	if body.is_in_group("Player"):
		camera_3d.current = true

func _drop_cam(body):
	if body.is_in_group("Player"):
		camera_3d.current = false
