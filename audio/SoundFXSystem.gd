extends AudioStreamPlayer3D

@export var hit_target_sound : AudioStream 
@export var hit_world_sound : AudioStream
@onready var new_stream = hit_target_sound

@export var triggering_node : Node
@export var hit_target_signal : String = "hit_target"
@export var hit_world_signal : String = "hit_world"

func _ready():
	if triggering_node.has_signal(hit_target_signal):
		triggering_node.connect(hit_target_signal,_on_hit_target_signal)
		triggering_node.connect(hit_world_signal,_on_hit_world_signal)
	
	new_stream = hit_target_sound
	
func _on_hit_target_signal(_1 = null):
	if !playing:
		new_stream = hit_target_sound
		stream = new_stream
		pitch_scale = randf_range(.7,1)
		play()

func _on_hit_world_signal(_1 = null):
	if !playing:
		new_stream = hit_world_sound
		stream = new_stream
		pitch_scale = randf_range(.7,1)
		play()
