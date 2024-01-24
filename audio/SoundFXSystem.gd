extends AudioStreamPlayer3D

@export var sound_1 : AudioStream 
@export var sound_2 : AudioStream
@onready var new_stream = sound_1

@export var triggering_node : Node
@export var trigger_signal_name : String

func _ready():
	if triggering_node.has_signal(trigger_signal_name):
		triggering_node.connect(trigger_signal_name,_on_trigger_signal)
	new_stream = sound_1
	
func _on_trigger_signal(_1 = null):
	if !playing:
		if sound_2 != null:
			match randi_range(1,2):
				1: new_stream = sound_1
				2: new_stream = sound_2
		stream = new_stream
		pitch_scale = randf_range(.7,1)
		play()

