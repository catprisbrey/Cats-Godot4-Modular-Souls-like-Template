extends AudioStreamPlayer3D
class_name SoundFXTrigger

## Takes a node, and a signal string. When the signal is emitted by the 
## triggering node, this stream  will shuffle its pitch and play. Useful
## for making footsteps, sword hits, etc less monotonous.

@export var triggering_node : Node
@export var sound_trigger_signal : String = "hit_target"

func _ready():
	if triggering_node:
		if triggering_node.has_signal(sound_trigger_signal):
			triggering_node.connect(sound_trigger_signal,_on_sound_trigger_signal)
	
func _on_sound_trigger_signal(_1 = null):
	if !playing:
		#pitch_scale = randf_range(.8,1.1)
		play()
