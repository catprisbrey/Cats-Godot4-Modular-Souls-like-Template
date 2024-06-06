extends ShapeCast3D

@onready var update_timer :Timer = Timer.new()
@onready var player : CharacterBody3D = get_parent()
# Called when the node enters the scene tree for the first time.
func _ready():
	update_timer.timeout.connect(_on_update_timer_timeout)
	update_timer.autostart = true
	update_timer.wait_time = .1
	add_child(update_timer)
	
	player.sensor_cast = self
	collision_mask = 9
	position = Vector3.UP
	target_position = Vector3(0,0,1.5)



func _on_update_timer_timeout():
	if player.interactable: # try ot maintain the currently set interacactble
		look_at(Vector3(player.interactable.global_position.x,global_position.y,player.interactable.global_position.z),Vector3.UP,true)
	if self.is_colliding():
		var body = get_collider(0)
		if body.is_in_group("interactable"):
			player.interactable = body

	else: # Clear interactable and reset to looking forward
		player.interactable = null
		rotation = Vector3.ZERO

