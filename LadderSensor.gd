extends Area3D

@export var player_node : CharacterBody3D

@onready var area_check : Area3D = $AreaCheck
@onready var raycheck :RayCast3D = $Raycheck

var area_collider
var raycast_collider

var current_position
enum ladder {BOTTOM,TOP}

signal ladder_updated



func _onready():

	area_check.body_entered.connect(update_state)
	area_check.body_exited.connect(update_state)
	
func update_raycast():
	if raycheck.is_colliding():
		var new_collider
		new_collider = raycheck.get_collider()
		return new_collider
	else:
		return null

func update_state(body):
	area_collider = body
	raycast_collider = update_raycast()
	if area_collider:
		if area_collider == raycast_collider:
			current_position = ladder.BOTTOM
		elif raycast_collider == null:
			current_position = ladder.TOP
	else:
		area_collider = null
	
