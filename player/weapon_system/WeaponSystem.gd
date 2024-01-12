extends Node3D
class_name EquipmentSystem

signal equipment_changed
## The node that will emit the weapon change signal
@export var player_node : CharacterBody3D
## The signal name should be connected to trigger the equipment swap
@export var change_signal : String = "weapon_changed"
@export var activate_signal : String = "attack_started"
@export var deactivate_signal : String = "attack_ended"
## The primary item location. Recommend to be a child node of a bone attachement
@export var held_mount_point : Node3D
## The secondary item location. Recommend to be a child node of a bone attachement
@export var stored_mount_point : Node3D
## The item currently in under the held mount point
@onready var current_equipment : Node3D
@onready var stored_equipment : Node3D

func _ready():
	if player_node:
		player_node.connect(change_signal,change_equipment)
		player_node.connect(activate_signal,activate)
		player_node.connect(deactivate_signal,deactivate)
		
	if held_mount_point.get_child(0):
		current_equipment = held_mount_point.get_child(0)
		current_equipment.equipped = true
	
	if stored_mount_point.get_child(0):
		stored_equipment = stored_mount_point.get_child(0)
		stored_equipment.equipped = false

	
func change_equipment():
	if stored_mount_point.get_child(0) && held_mount_point.get_child(0):
		stored_equipment = stored_mount_point.get_child(0)
		
		print("Former equpiment: " + str(current_equipment))
		held_mount_point.remove_child(current_equipment)
		stored_mount_point.remove_child(stored_equipment)
		held_mount_point.add_child(stored_equipment)
		stored_mount_point.add_child(current_equipment)
		current_equipment.equipped = false
		
		# Update current
		current_equipment = held_mount_point.get_child(0)
		equipment_changed.emit(current_equipment)
		current_equipment.equipped = true
		print("New equipment: " + str(current_equipment))
		
		
func activate(_anim_time):
	current_equipment.activate(_anim_time)

func deactivate():
	current_equipment.deactivate()
