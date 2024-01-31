extends Node3D
class_name ItemSystem

signal item_changed
## The node that will emit the weapon change signal
@export var player_node : CharacterBody3D
@export var change_signal : String = "item_changed"
@onready var item_type = "DRINK"
@onready var current_item : Node3D
@export var held_mount_point : Node3D
@onready var stored_item : Node3D
@export var stored_mount_point : Node3D

signal healed_damage

func _ready():
	if player_node:
		if player_node.has_signal(change_signal):
			player_node.connect(change_signal,_on_item_changed)
	
	if held_mount_point:
		if held_mount_point.get_child(0):
			current_item = held_mount_point.get_child(0)

	if stored_mount_point:
		if stored_mount_point.get_child(0):
			stored_item = stored_mount_point.get_child(0)
	
func _on_item_changed():
	if stored_mount_point.get_child(0) && held_mount_point.get_child(0):
		stored_item = stored_mount_point.get_child(0)
		
		## rearrange children
		held_mount_point.remove_child(current_item)
		stored_mount_point.remove_child(stored_item)
		
		held_mount_point.add_child(stored_item)
		stored_mount_point.add_child(current_item)
		
		# Update to current item
		current_item = held_mount_point.get_child(0)
		
		await get_tree().process_frame
		item_changed.emit(current_item)
		item_type = current_item.item_info.object_type
		
func activate():
	match item_type:
		"DRINK":
			healed_damage.emit(current_item.item_info.power)
		
		"THROWN":
			pass
