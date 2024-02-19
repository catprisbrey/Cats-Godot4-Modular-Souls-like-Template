extends Control

@export var signaling_node : Node
@export var dead_signal_string : String = "death_started"
@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("lifecard")
	if signaling_node.has_signal(dead_signal_string):
		signaling_node.connect(dead_signal_string,_on_dead_signal)
	
func _on_dead_signal():
	animation_player.play("deadcard")
