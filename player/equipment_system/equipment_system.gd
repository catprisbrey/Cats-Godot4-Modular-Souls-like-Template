extends Node3D
class_name EquipmentSystem

signal equipment_changed
## The node that will emit the weapon change signal
@export var player_node : CharacterBody3D
## The signal name should be connected to trigger the equipment swap
@export var change_signal : String = "weapon_changed"
## The signal name from player_node for when the item should be active.
## items themselves should manage what "active" means, but typically this is
## monitoring/collision shapes, emitters,sound FX, etc. 
@export var activate_signal : String = "attack_started"
## The signal name from player_node for when the item should be inactive
@export var deactivate_signal : String = "attack_ended"

## The primary item location. Bone attachments or Marker3Ds work well for placement
@export var held_mount_point : Node3D
## The secondary item location. Bone attachments or Marker3Ds work well for placement
@export var stored_mount_point : Node3D
## The item currently under the primary held mount node
@onready var current_equipment : Node3D
## The item currently under the stored/sheathed node
@onready var stored_equipment : Node3D

func _ready():
	if player_node:
		player_node.connect(change_signal,_on_equipment_changed)
		player_node.connect(activate_signal,_on_action_started)
		player_node.connect(deactivate_signal,_on_action_ended)
		
	if held_mount_point.get_child(0):
		current_equipment = held_mount_point.get_child(0)
		current_equipment.equipped = true
	
	if stored_mount_point.get_child(0):
		stored_equipment = stored_mount_point.get_child(0)
		stored_equipment.equipped = false

	
func _on_equipment_changed():
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
		
		
func _on_action_started(_anim_time= .5,_is_special_attack = false):
	current_equipment.activate(_anim_time,_is_special_attack)

func _on_action_ended():
	current_equipment.deactivate()
