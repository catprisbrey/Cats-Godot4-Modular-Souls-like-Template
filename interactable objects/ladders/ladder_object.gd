extends StaticBody3D

@onready var bottom_mount = $"../BottomMount"
@onready var top_mount = $"../TopMount"


@onready var bottom_area = $"../BottomArea"
@onready var top_area = $"../TopArea"

var player_location
enum location {BOTTOM,TOP}
var mount_transform

func _ready():
	bottom_area.connect("body_entered",update_bottom)
	bottom_area.connect("body_exited",exit_area)
	top_area.connect("body_entered",update_top)
	top_area.connect("body_exited",exit_area)

func activate(_requestor):
	if _requestor.climbing == false:
		_requestor.climbing = true
		var tween = create_tween()
		tween.tween_property(_requestor,"global_transform", mount_transform,.3)
		_requestor.start_ladder()
		
	
func update_bottom(_body):
	player_location = location.BOTTOM
	mount_transform = bottom_mount.global_transform

func update_top(_body):
	player_location = location.TOP
	mount_transform = top_mount.global_transform
	
func exit_area(_body):
	player_location = null
	mount_transform = null
