extends StaticBody3D

## All interactables function similarly. They have a function called "activate"
## that takes in the player node as an argument. Typically the interactable
## forces the player to a STATIC state, moves the player into a ready postiion,
## triggers the interact on the player while making any changes needed here.

@onready var new_trans = global_transform
@onready var opened :bool = false
@export var locked : bool = false
signal gate_opened
@onready var animation_player = $AnimationPlayer
@export var open_delay :float = .7

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("interactable")
	new_trans.origin = to_global(Vector3.FORWARD *.5)
	collision_layer = 9
	

func activate(player: CharacterBody3D):
	if locked:
		shake_gate()
		return
		
	if !opened:
		opened = true
		
		
		var dist_to_front = to_global(Vector3.FORWARD).distance_to(player.global_position)
		var dist_to_back = to_global(Vector3.BACK).distance_to(player.global_position)
		
		var new_translation = global_transform
		if dist_to_front > dist_to_back:
			new_translation = global_transform.rotated_local(Vector3.UP,PI)
		
		new_translation = new_translation.translated_local(Vector3(0,player.global_position.y,-1))
		
		var tween = create_tween()
		tween.tween_property(player,"global_transform", new_translation,.2)
		await tween.finished
		
		player.trigger_interact("GATE")
		await get_tree().create_timer(open_delay).timeout
		gate_opened.emit()
		animation_player.play("open")
		
#
func shake_gate():
	animation_player.play("locked")

#
