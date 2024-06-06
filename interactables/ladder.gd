extends Area3D

@onready var new_trans = global_transform

func _ready():
	add_to_group("interactable")
	collision_layer = 9
	collision_mask = 2
 	
	var new_basis = Basis.from_euler(Vector3(0,deg_to_rad(180),0))
	new_trans.basis *= new_basis # model view, flip it around
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func activate(player: CharacterBody3D):
	player.current_state = player.state.STATIC
	if player.global_position.distance_to(global_position) < 2: # bottom of ladder
		new_trans.origin = to_global(Vector3.BACK *.5)
		new_trans.origin.y = player.global_position.y +.5
	else: # Top of ladder
		new_trans.origin = to_global(Vector3.BACK *.5)
		new_trans.origin.y = player.global_position.y - 1.2
	
	var tween = create_tween()
	tween.tween_property(player,"global_transform",new_trans,.3)
	await tween.finished
	
	#player.start_climb()
	player.climb_started.emit()


func _on_body_entered(body):
	if body.is_in_group("player"):
		body.ladder = self

func _on_body_exited(body):
	if body.is_in_group("player"):
		body.ladder = null

