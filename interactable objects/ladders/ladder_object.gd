extends StaticBody3D

@onready var bottom_mount = $"../BottomMount"
@onready var top_mount = $"../TopMount"

@onready var bottom_area = $"../BottomArea"
@onready var top_area = $"../TopArea"

var top_or_bottom
var mount_transform
var dismount_position

signal ladder_info_updated

func _ready():
	bottom_area.connect("body_entered",update_bottom)
	bottom_area.connect("body_exited",exit_area)
	top_area.connect("body_entered",update_top)
	top_area.connect("body_exited",exit_area)

func activate(_player_node):
	_player_node.interact_ladder()
	
func update_bottom(_body):
	ladder_info_updated.connect(_body.update_ladder)
	top_or_bottom = "BOTTOM"
	mount_transform = bottom_mount.global_transform
	dismount_position = bottom_area.global_position
	ladder_info_updated.emit(top_or_bottom,mount_transform,dismount_position)
	
func update_top(_body):
	ladder_info_updated.connect(_body.update_ladder)
	top_or_bottom = "TOP"
	mount_transform = top_mount.global_transform
	dismount_position = top_area.global_position
	ladder_info_updated.emit(top_or_bottom,mount_transform,dismount_position)

func exit_area(_body):
	ladder_info_updated.disconnect(_body.update_ladder)
	top_or_bottom = null
	mount_transform = null
	dismount_position = null
	ladder_info_updated.emit(top_or_bottom,mount_transform,dismount_position)
