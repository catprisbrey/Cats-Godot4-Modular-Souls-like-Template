extends AudioStreamPlayer3D

@export var player_node : CharacterBodySoulsBase
@export var dodge_sound : AudioStream  
@export var jump_sound : AudioStream 
@export var equipement_change_sound : AudioStream 
@export var block_sound : AudioStream 
@export var parry_sound : AudioStream 
@export var item_sound : AudioStream 
@export var hurt_sound : AudioStream 
@export var death_sound : AudioStream

var new_stream : set = _randomize_and_play

# Called when the node enters the scene tree for the first time.
func _ready():
	player_node.dodge_started.connect(_on_dodge_started)
	player_node.jump_started.connect(_on_jump_started)
	player_node.gadget_change_started.connect(_on_gadget_change_started)
	player_node.weapon_change_started.connect(_on_gadget_change_started)
	player_node.parry_started.connect(_on_parry_started)
	player_node.hurt_started.connect(_on_hurt_started)
	player_node.block_started.connect(_on_block_started)
	player_node.use_item_started.connect(_on_use_item_started)
	player_node.death_started.connect(_on_death_started)
	
func _randomize_and_play(_new_value):
	new_stream = _new_value
	stream = new_stream
	print("Sound should play")
	pitch_scale = randf_range(.7,1)
	play()

func _on_jump_started():
	new_stream = jump_sound
	
func _on_dodge_started():
	new_stream = dodge_sound
	
func _on_gadget_change_started():
	new_stream = equipement_change_sound
	
func _on_parry_started():
	new_stream = parry_sound
	
func _on_hurt_started():
	new_stream = hurt_sound
	
func _on_block_started():
	new_stream = block_sound
	
func _on_death_started():
	new_stream = death_sound
	
func _on_use_item_started():
	new_stream = item_sound
