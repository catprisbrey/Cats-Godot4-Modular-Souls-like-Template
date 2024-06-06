extends StaticBody3D


# Called when the node enters the scene tree for the first time.
@onready var anim_player :AnimationPlayer = $AnimationPlayer
@onready var texture_rect = $TextureRect
@export var spawn_scene : PackedScene
@export var reset_level : bool = true
@onready var audio_stream_player = $AudioStreamPlayer
@onready var flame_particles = $FlameParticles
@onready var interact_type = "SPAWN"


func _ready():
	add_to_group("interactable")
	collision_layer = 9

func activate(requester: CharacterBody3D):
	requester.current_state = requester.state.STATIC
	requester.trigger_interact(interact_type)
	anim_player.play("respawn",.2)
	await anim_player.animation_finished
	requester.queue_free()
	

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
