extends AudioStreamPlayer3D

@export var player_node : EnemyBase


@export var swing_sound : AudioStream
@export var parried_sound : AudioStream 
@export var hurt_sound : AudioStream 

var new_stream : set = _randomize_and_play

# Called when the node enters the scene tree for the first time.
func _ready():
	if player_node:
		player_node.attack_swing_started.connect(_on_attack_swing_started)
		player_node.hurt_started.connect(_on_hurt_started)
		player_node.parried_started.connect(_on_parried_started)
	
func _randomize_and_play(_new_value):
	new_stream = _new_value
	stream = new_stream
	pitch_scale = randf_range(.9,1.2)
	play()

func _on_attack_swing_started():
	new_stream = swing_sound
	
func _on_hurt_started():
	new_stream = hurt_sound
	
func _on_parried_started():
	new_stream = parried_sound
