extends Area3D
class_name InteractSensor

signal interact_found
signal interact_lost

@onready var interactable

func _input(_event : InputEvent):
	if _event.is_action_pressed("interact"):
		if interactable:
			interactable.activate()

func _ready():
	body_entered.connect(_interact_detected)
	body_exited.connect(_interact_lost)

func _interact_detected(_interact_body):
	if _interact_body.is_in_group("Interactable"):
		interactable = _interact_body
		interact_found.emit(_interact_body)
	
func _interact_lost(_interact_body):
	if _interact_body.is_in_group("Interactable"):
		if interactable == _interact_body:
			interactable = null
			interact_lost.emit(_interact_body)
