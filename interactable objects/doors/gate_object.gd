extends StaticBody3D

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
	

func activate(requester: CharacterBody3D):
	if locked:
		shake_gate()
		return
		
	if !opened:
		opened = true
		requester.current_state = requester.state.STATIC
		
		var dist_to_front = to_global(Vector3.FORWARD).distance_to(requester.global_position)
		var dist_to_back = to_global(Vector3.BACK).distance_to(requester.global_position)
		
		var new_translation = global_transform
		if dist_to_front > dist_to_back:
			new_translation = global_transform.rotated_local(Vector3.UP,PI)
		
		new_translation = new_translation.translated_local(Vector3(0,requester.global_position.y,-1))
		
		var tween = create_tween()
		tween.tween_property(requester,"global_transform", new_translation,.2)
		await tween.finished
		
		requester.trigger_interact("GATE")
		await get_tree().create_timer(open_delay).timeout
		gate_opened.emit()
		animation_player.play("open")
		



#
### This gate object expects waits to be told to "activate". Interactables
### typically are on physics layer 4, and in group "Interactable"
### Interacts are a bit of a 'handshake'. The requestor tells the gate
### to activate. The gate replies back to the requestor a translation and wait time
### so the requestor can be in sync, moving to a good position before running 
### their own "start_gate" logic and animations.
#
#@onready var opened = false
#@onready var gate_anim_player :AnimationPlayer = $GateAnimPlayer
#
#@export var locked : bool = false
#var anim
#
#func activate(_requestor: CharacterBody3D):
	#
	#if locked:
		#shake_gate()
		#
	#else:
		#interactable_activated.emit()
		#var dist_to_front = to_global(Vector3.FORWARD).distance_to(_requestor.global_position)
		#var dist_to_back = to_global(Vector3.BACK).distance_to(_requestor.global_position)
		#
		#var new_translation = global_transform
		#if dist_to_front > dist_to_back:
			#new_translation = global_transform.rotated_local(Vector3.UP,PI)
		#new_translation = new_translation.translated_local(Vector3(0,_requestor.global_position.y,-1))
		#var move_time = .3
		#
		#if opened == false:
			#if _requestor.has_method("start_interact"):
				#_requestor.start_interact(interact_type,new_translation, move_time)
				#await get_tree().create_timer(move_time + 1).timeout
			#open_gate()
#
func shake_gate():
	animation_player.play("locked")
	#
#func open_gate():
	#anim = "Open"
	#gate_anim_player.play(anim)
	#opened = true
#
#
