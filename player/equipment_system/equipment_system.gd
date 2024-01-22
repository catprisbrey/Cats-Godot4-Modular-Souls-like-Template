extends Node3D
class_name EquipmentSystem

signal equipment_changed
## The node that will emit the weapon change signal
@export var player_node : CharacterBody3D
## The object group to detect 
@export var target_group : String = "Targets"
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

signal hit_target

func _ready():
	if player_node:
		if player_node.has_signal(change_signal):
			player_node.connect(change_signal,_on_equipment_changed)
		if player_node.has_signal(activate_signal):
			player_node.connect(activate_signal,_on_action_started)
		if player_node.has_signal(deactivate_signal):
			player_node.connect(deactivate_signal,_on_action_ended)
		if player_node.has_signal("hurt_started"):
			player_node.hurt_started.connect(_on_hurt_started)
			 
	if held_mount_point:
		if held_mount_point.get_child(0):
			current_equipment = held_mount_point.get_child(0)
			current_equipment.equipped = true
			current_equipment.monitoring = false
			if current_equipment.has_signal("body_entered"):
				current_equipment.body_entered.connect(_on_body_entered)
		
	if stored_mount_point:
		if stored_mount_point.get_child(0):
			stored_equipment = stored_mount_point.get_child(0)
			stored_equipment.equipped = false
			stored_equipment.monitoring = false
	
func _on_equipment_changed():
	if stored_mount_point.get_child(0) && held_mount_point.get_child(0):
		stored_equipment = stored_mount_point.get_child(0)
		
		## rearrange children
		held_mount_point.remove_child(current_equipment)
		stored_mount_point.remove_child(stored_equipment)
		
		held_mount_point.add_child(stored_equipment)
		stored_mount_point.add_child(current_equipment)
		
		# Update to current equipment
		current_equipment.equipped = false
		if current_equipment.is_connected("body_entered", _on_body_entered):
			current_equipment.disconnect("body_entered",_on_body_entered)
		current_equipment = held_mount_point.get_child(0)
		
		await get_tree().process_frame
		if current_equipment.has_signal("body_entered"):
			current_equipment.body_entered.connect(_on_body_entered)
		current_equipment.equipped = true
		equipment_changed.emit(current_equipment)
		
func _on_action_started(_anim_time= .5,_is_special_attack = false):
	## awaiting so the area3D starts monitoring about mid-attack
	if current_equipment:
		await get_tree().create_timer(_anim_time *.3).timeout
		current_equipment.monitoring = true

func _on_action_ended():
	if current_equipment:
		current_equipment.monitoring = false
		
func _on_body_entered(_hit_body):
	if _hit_body.is_in_group(target_group):
		if _hit_body.has_method("hit"):
			_hit_body.hit(player_node,current_equipment.equipment_info)

func _on_hurt_started():
	current_equipment.monitoring = false
