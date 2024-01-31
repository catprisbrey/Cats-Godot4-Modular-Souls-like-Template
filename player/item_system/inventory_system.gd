extends Node
class_name InventorySystem

@export var signaling_node : Node3D 
@export var change_item_signal : String = "item_changed"
@export var use_item_signal  : String = "item_used"

@onready var inventory : Array = []
@export var starter_item : ItemResource
@export var starter_item2 : ItemResource
@onready var current_item

signal item_used
signal inventory_updated(Array)

func _ready():
	if signaling_node:
		signaling_node.connect(change_item_signal,_on_change_item_signal)
		signaling_node.connect(use_item_signal, _on_item_used_signal)
	
	inventory.append(starter_item)
	inventory.append(starter_item)
	inventory.append(starter_item2)
	restack_inventory()
	
func _on_item_used_signal():
	if current_item.count > 0:
		current_item.count -= 1
		item_used.emit(current_item)
		inventory_updated.emit(inventory)
		
func _on_change_item_signal():
	if inventory.size() > 0:
		change_item(0,inventory.size()-1)
		

func add_item(_new_item: ItemResource):
	inventory.append(_new_item)
	restack_inventory()
	
func change_item(_start_index,_destination_index):
	var start_item = inventory[_start_index]
	var dest_item = inventory[_destination_index]
	inventory[_start_index] = dest_item
	inventory[_destination_index] = start_item
	current_item = inventory[0]
	inventory_updated.emit(inventory)

#func remove_item(_index):
	#var former_item = inventory[_index] #store item in the current spot
	#inventory[_index] = null
	#inventory_updated.emit(inventory)
	#return former_item
	#
#func set_item(_index,_new_item: ItemResource):
	#var former_item = inventory[_index] #store item in the current spot
	#inventory[_index] = _new_item
	#inventory_updated.emit(inventory)
	#return former_item
	
func restack_inventory():
	var inventory_refresh = []
	print(inventory)
	await get_tree().process_frame
	for item in range(inventory.size()):
		var this_item = inventory[item]
		var found = false

		for others in range(inventory_refresh.size()):
			if this_item.name == inventory_refresh[others].name:
				print(this_item.name)
				this_item.count += inventory_refresh[others].count
				found = true
		if not found:
			inventory_refresh.append(this_item)
			
	inventory = inventory_refresh
	print(inventory)
	if inventory[0]:
		current_item = inventory[0]
	inventory_updated.emit(inventory)
