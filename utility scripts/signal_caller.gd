extends Node
class_name SignalCaller

## A curious switching node. Takes signals from a signalling node, and turns it
## into a toggle action for a property on another node. Can either take an end 
## trigger signal or can be shut off after a lifetime in seconds.

## start_signal will toggle the property true or false, and after this lifetime in seconds,
## the property will return back to it's original value. Set to 0 to disable this
## feature. Great for temporary conditions you only need true/false for a period of time.
## eg. Cooldowns, activated periods, emitting particles, playing a sound. etc.

## Node that will emit the starting or ending signals.
@export var signaling_node : Node
@export var start_signal :String = "body_entered"
## Optional if you want to toggle the property back by a signal instead of lifetime.
## The bool property on the parent of this node that you want to flip.
@export var method_to_call: String = "look_at"
@export var args_separated_by_commas : String = "global_position,Vector3.UP,true"


func _ready():
	signaling_node.connect(start_signal,_on_signal)

func _on_signal(_arg = null,_arg2 = null, _arg3 = null):
		var node_to_toggle = get_parent()
		if node_to_toggle.has_method(method_to_call):
			node_to_toggle.call(method_to_call,args_separated_by_commas)
