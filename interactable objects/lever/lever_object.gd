extends StaticBody3D

## All interactables function similarly. They have a function called "activate"
## that takes in the player node as an argument. Typically the interactable
## forces the player to a STATIC state, moves the player into a ready postiion,
## triggers the interact on the player while making any changes needed here.

## The physical maniifestation of a boolean haha. Pull the lever, it will
## flip the boolean on of the property_to_switch on the node_to_control

# Called when the node enters the scene tree for the first time.
@export var node_to_control : Node3D
@export var property_to_switch :String = "locked"
@onready var opened = false
@onready var lever_anim_player :AnimationPlayer = $LeverAnimPlayer
@export var locked : bool = false
@export var player_offset : Vector3 = Vector3(0,0,1)
@onready var interact_type = "LEVER"
@export var anim_delay : float = .1
var anim
signal interactable_activated

func _ready():
	add_to_group("interactable")
	collision_layer = 9


func activate(player: CharacterBody3D):
	if locked:
		shake_lever()
	elif opened:
		return
	else:
		interactable_activated.emit()
		
		# move the player in front of the lever
		var new_translation = global_transform.translated_local(player_offset).rotated_local(Vector3.UP,PI)
		var tween = create_tween()
		tween.tween_property(player,"global_transform", new_translation,.2)
		await tween.finished
		
		# trigger player and lever animation
		player.trigger_interact(interact_type)
		await get_tree().create_timer(anim_delay).timeout
		open_lever()

func shake_lever():
	lever_anim_player.play("locked")
	
func open_lever():
	anim = "open"
	lever_anim_player.play(anim)
	opened = true
	if node_to_control:
		if property_to_switch in node_to_control:
			var new_value = !node_to_control.get(property_to_switch)
			node_to_control.set(property_to_switch,new_value)
