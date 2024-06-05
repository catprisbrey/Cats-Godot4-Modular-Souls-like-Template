extends InteractableObject
class_name SpawnSite

# Called when the node enters the scene tree for the first time.
@onready var anim_player :AnimationPlayer = $AnimationPlayer
@onready var texture_rect = $TextureRect
@export var spawn_scene : PackedScene
@export var reset_level : bool = true
@onready var audio_stream_player = $AudioStreamPlayer
@onready var flame_particles = $FlameParticles


func activate(_requestor: CharacterBody3D):
	interactable_activated.emit()
	
	if _requestor.has_method("start_interact"):
		_requestor.start_interact(interact_type,_requestor.global_transform.looking_at(global_position,Vector3.UP,true), .4)
		anim_player.play("respawn",.2)
		await anim_player.animation_finished
		_requestor.queue_free()
	

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
