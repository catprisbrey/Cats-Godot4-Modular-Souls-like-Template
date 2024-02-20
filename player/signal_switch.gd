extends Node
class_name SignalSwitch

## A curious switching node. Takes signals from a signalling node, and turns it
## into a toggle action for a property on another node. Can either take an end 
## trigger signal or can be shut off after a lifetime in seconds.

## start_signal will toggle the property true or false, and after this lifetime in seconds,
## the property will return back to it's original value. Set to 0 to disable this
## feature. Great for temporary conditions you only need true/false for a period of time.
## eg. Cooldowns, activated periods, emitting particles, playing a sound. etc.
@export var lifetime :float = 0

## Node that will emit the starting or ending signals.
@export var signaling_node : Node
@export var start_signal :String = "body_entered"
## Optional if you want to toggle the property back by a signal instead of lifetime.
@export var end_signal : String 
## The bool property on the parent of this node that you want to flip.
@export var property: String = "emitting"

@onready var node_to_toggle
@onready var toggle

func _ready():
	node_to_toggle = get_parent()
	signaling_node.connect(start_signal,_on_signal)
	if end_signal != "":
		signaling_node.connect(end_signal,_on_signal)
	toggle = node_to_toggle.get(property)

func _on_signal(_arg = null):
	toggle = !node_to_toggle.get(property)
	node_to_toggle.set(property,toggle)
	
	if lifetime != 0:
		await get_tree().create_timer(lifetime).timeout
		toggle = !node_to_toggle.get(property)
		node_to_toggle.set(property,toggle)
