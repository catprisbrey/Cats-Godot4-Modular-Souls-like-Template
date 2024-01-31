extends Node3D
class_name EquipmentSystem

## A node that listens for signals from a player node to change equipment, or
## to activate and deactivate Area3D equipment nodes.
## When the 'change_signal" emits from the player node, the child #0 under
## the held_mount_point will reparent to the stored_mount_point, and same for
## child #0 of stored, will move to held. Handy for swaping objects from hand
## bones to back bones or similar.

## the Activate and deactivate signals will turn on and off monitoring for the 
## area3d children. Also if they hit things in the target_group they'll emit
## the hit_target signal, and if they hit anything else, they'll emit hit_world
## signal. Hitting target will communicate equipment and player_node info to the
## object receiving the hit.


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

@export var deactivate_signal : String = "hurt_started"
## The primary item location. Bone attachments or Marker3Ds work well for placement
@export var held_mount_point : Node3D
## The secondary item location. Bone attachments or Marker3Ds work well for placement
@export var stored_mount_point : Node3D
## The item currently under the primary held mount node
@onready var current_equipment : Node3D
## The item currently under the stored/sheathed node
@onready var stored_equipment : Node3D

signal hit_target
signal hit_world

func _ready():
	if player_node:
		if player_node.has_signal(change_signal):
			player_node.connect(change_signal,_on_equipment_changed)
		## needed to turn on/off monitoring when attacks start/end
		if player_node.has_signal(activate_signal):
			player_node.connect(activate_signal,_on_activated)
		## needed to turn off monitoring if hurt mid-attack
		if player_node.has_signal(deactivate_signal):
			player_node.connect(deactivate_signal,_on_stop_signal)
			 
	## update what weapon we're starting with
	if held_mount_point:
		if held_mount_point.get_child(0):
			current_equipment = held_mount_point.get_child(0)
			current_equipment.equipped = true
			current_equipment.monitoring = false
			if current_equipment.has_signal("body_entered"):
				current_equipment.body_entered.connect(_on_body_entered)
	## update what gadget we're holding
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
		
func _on_activated():
	## awaiting so the area3D starts monitoring about after attack wind-up
	if current_equipment:
		## pause and start monitoring to hit things
		current_equipment.monitoring = true
		await get_tree().create_timer(player_node.anim_length *.35).timeout
		## after moment turn off monitoring to not hit things
		current_equipment.monitoring = false
		
func _on_body_entered(_hit_body):
	if _hit_body.is_in_group(target_group):
		if _hit_body.has_method("hit"):
			hit_target.emit()
			_hit_body.hit(player_node,current_equipment.equipment_info)
	else: 
		hit_world.emit()

func _on_stop_signal():
	current_equipment.monitoring = false
