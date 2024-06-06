extends StaticBody3D

# Called when the node enters the scene tree for the first time.
@onready var opened = false
@onready var chest_anim_player :AnimationPlayer = $ChestAnimPlayer
@export var locked : bool = false
@export var player_offset : Vector3 = Vector3(0,0,1)
@onready var interact_type = "CHEST"
@export var anim_delay : float = .2
var anim
signal interactable_activated

func _ready():
	add_to_group("interactable")
	collision_layer = 9


func activate(player: CharacterBody3D):
	if locked:
		shake_chest()
		
	else:
		interactable_activated.emit()
		player.current_state = player.state.STATIC
		var new_translation = global_transform.translated_local(player_offset).rotated_local(Vector3.UP,PI)

		var tween = create_tween()
		tween.tween_property(player,"global_transform", new_translation,.2)
		await tween.finished
		
		if opened == false:
			player.trigger_interact(interact_type)
			await get_tree().create_timer(anim_delay).timeout
			open_chest()

func shake_chest():
	chest_anim_player.play("Locked")
	
func open_chest():
	anim = "open"
	chest_anim_player.play(anim)
	opened = true
