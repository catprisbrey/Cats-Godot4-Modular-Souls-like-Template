extends Control

## A very crude inventory system UI. It waits for a signal from whatever node 
## you choose, that signal should pass the currently held inventory. This node
## looks at the first item in that inventory array, hecks the item count, and 
## texture and updates it on screen.

@export var signaling_node : Node
@export var update_signal : String = "inventory_updated"

@onready var item_texture = $ItemTexture
@onready var item_count = $ItemCount

# Called when the node enters the scene tree for the first time.
func _ready():
	if signaling_node:
		signaling_node.connect(update_signal,_on_update_signal)

func _on_update_signal(inventory):
	if inventory[0]:
		var current_item = inventory[0]
		item_count.text = str(current_item.count)
		item_texture.texture = current_item.texture
	else:
		item_count.text = str(0)
		item_texture.texture = null
