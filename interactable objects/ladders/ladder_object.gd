extends StaticBody3D

@onready var bottom_mount = $"../BottomMount"
@onready var top_mount = $"../TopMount"


@onready var bottom_area = $"../BottomArea"
@onready var top_area = $"../TopArea"

var player_location
var mount_transform
var dismount_position

func _ready():
	bottom_area.connect("body_entered",update_bottom)
	bottom_area.connect("body_exited",exit_area)
	top_area.connect("body_entered",update_top)
	top_area.connect("body_exited",exit_area)

func activate(_requestor):
	if _requestor.climbing == false:
		var tween = create_tween()
		tween.tween_property(_requestor,"global_transform", mount_transform,.3)
		_requestor.ladder_mount()
	elif _requestor.climbing == true:
		var tween = create_tween()
		tween.tween_property(_requestor,"global_position", dismount_position,.3)
		_requestor.ladder_mount()
	
	
func update_bottom(_body):
	_body.ladder_position = "BOTTOM"
	mount_transform = bottom_mount.global_transform
	dismount_position = bottom_area.global_position
	
func update_top(_body):
	_body.ladder_position = "TOP"
	mount_transform = top_mount.global_transform
	dismount_position = top_area.global_position

	
func exit_area(_body):
	mount_transform = null
	dismount_position = null
