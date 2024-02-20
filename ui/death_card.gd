extends Control
class_name LifeDeathCard

## A very basic node that waits for a signal from a node, and queues an 
## animation to play. 

@export var signaling_node : Node
@export var dead_signal_string : String = "death_started"
@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("lifecard")
	if signaling_node.has_signal(dead_signal_string):
		signaling_node.connect(dead_signal_string,_on_dead_signal)
	
func _on_dead_signal():
	animation_player.play("deadcard")
