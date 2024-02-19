extends InteractableObject
class_name SpawnSite

# Called when the node enters the scene tree for the first time.
@onready var anim_player :AnimationPlayer = $AnimationPlayer
@onready var texture_rect = $TextureRect
@export var spawn_scene : PackedScene
@export var reset_level : bool = false
@onready var ring = $MeshInstance3D/Ring
@onready var audio_stream_player = $AudioStreamPlayer

func _ready():
	anim_player.play("idle",.2)

func activate(_requestor: CharacterBodySoulsBase,_sensor_loc = null):
	if _requestor.has_method("start_interact"):
		_requestor.start_interact(interact_type,_requestor.global_transform.looking_at(global_position,Vector3.UP,true), .4)
		audio_stream_player.play()
		anim_player.play("respawn",.2)
		await get_tree().create_timer(2).timeout
		_requestor.queue_free()
		await get_tree().create_timer(1).timeout
		anim_player.play("idle",.2)
	

func respawn():
	if reset_level:
		get_tree().reload_current_scene()
	else:
		if spawn_scene:
			var new_scene : CharacterBody3D = spawn_scene.instantiate()
			add_sibling(new_scene)
			var new_translation = global_transform.translated_local(Vector3.BACK)
			await get_tree().process_frame
			new_scene.global_transform = new_translation
			new_scene.last_spawn_site = self
