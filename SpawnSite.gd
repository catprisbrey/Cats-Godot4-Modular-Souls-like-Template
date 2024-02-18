extends InteractableObject
class_name SpawnSite

# Called when the node enters the scene tree for the first time.
@onready var anim_player :AnimationPlayer = $AnimationPlayer
@onready var texture_rect = $TextureRect
@export var spawn_scene : PackedScene
var anim
@onready var ring = $MeshInstance3D/Ring

func ready():
	anim_player.play("idle")

func activate(_requestor: CharacterBodySoulsBase,_sensor_loc):
	if _requestor.has_method("start_interact"):
		_requestor.start_interact(interact_type,_requestor.global_transform.looking_at(global_position,Vector3.UP,true), .4)
		anim = "respawn"
		anim_player.play(anim)
		await get_tree().create_timer(2).timeout
		_requestor.queue_free()
	

func respawn():
	if spawn_scene:
		var new_scene : CharacterBody3D = spawn_scene.instantiate()
		add_sibling(new_scene)
		var new_translation = global_transform.translated_local(Vector3.BACK)
		await get_tree().process_frame
		new_scene.global_transform = new_translation
