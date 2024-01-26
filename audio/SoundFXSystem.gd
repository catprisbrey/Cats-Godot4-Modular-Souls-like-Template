extends AudioStreamPlayer3D
class_name SoundFXTrigger2

@export var sound_1 : AudioStream 
@export var sound_2 : AudioStream
@onready var new_stream = sound_1

@export var triggering_node : Node
@export var sound_1_signal : String = "hit_target"
@export var sound_2_signal : String = "hit_world"

func _ready():
	if triggering_node.has_signal(sound_1_signal):
		triggering_node.connect(sound_1_signal,_on_sound_1_signal)
	if triggering_node.has_signal(sound_2_signal):
		triggering_node.connect(sound_2_signal,_on_sound_2_signal)
	
	new_stream = sound_1
	
func _on_sound_1_signal(_1 = null):
	if !playing:
		new_stream = sound_1
		stream = new_stream
		pitch_scale = randf_range(.7,1)
		play()

func _on_sound_2_signal(_1 = null):
	if !playing:
		new_stream = sound_2
		stream = new_stream
		pitch_scale = randf_range(.7,1)
		play()
