extends StaticBody3D


## All interactables function similarly. They have a function called "activate"
## that takes in the player node as an argument. Typically the interactable
## forces the player to a STATIC state, moves the player into a ready postiion,
## triggers the interact on the player while making any changes needed here.

@onready var opened = false
@onready var door_anim_player :AnimationPlayer = $AnimationPlayer
@onready var interact_type  = "DOOR"
@export var locked : bool = false
@export var delay_anim : float = .8
var anim

func _ready():
	add_to_group("interactable")
	collision_layer = 9
	
func activate(player: CharacterBody3D):
	if locked:
		shake_door()
		
	else:
		
		 # detect where the player is, and pass them location info to know where to center up.
		var dist_to_front = to_global(Vector3.FORWARD).distance_to(player.global_position)
		var dist_to_back = to_global(Vector3.BACK).distance_to(player.global_position)
		
		var new_translation = global_transform
		if dist_to_front > dist_to_back: # detect which side of the door the player is on.
			new_translation = global_transform.rotated_local(Vector3.UP,PI)
		# update the new_location with the tranfrom info of where the player should ideally stand to open the door
		new_translation = new_translation.translated_local(Vector3(0,player.global_position.y,-1))

		var tween = create_tween()
		tween.tween_property(player,"global_transform", new_translation,.2)
		await tween.finished
		
		
		if opened == false:
			player.trigger_interact(interact_type)
			await get_tree().create_timer(delay_anim).timeout
			open_door(dist_to_front, dist_to_back)
			
		if opened == true:
			close_door()

func shake_door():
	door_anim_player.play("Locked")
	
## Based on the players updated location from being activated,
## The door will open in or outwards. A signally lever can pass it info
## and it will work just the same.

func open_door(dist_to_front, dist_to_back):
	if !door_anim_player.is_playing():
		if dist_to_front < dist_to_back:
			anim = "OpenLeft"
		else:
			anim = "OpenRight"
		door_anim_player.play(anim)
		opened = true

func close_door(): ## Play the previous open anim backwards to close the correct way
	if !door_anim_player.is_playing():
		door_anim_player.play_backwards(anim)
		opened = false
