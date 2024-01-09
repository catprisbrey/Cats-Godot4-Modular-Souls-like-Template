extends Node3D
class_name InteractSensors

## This Class will sense objects in layer 4, that are in the group Interactable
## when the "interact" button is pressed, it simple calls "activate" on whatever
## interactable body it currently sees. This allows all other logic to happen
## on the interactable object node's script instead of here.
@onready var top_sensor = $TopSensor
@onready var bottom_sensor = $BottomSensor

signal interact_updated

@onready var interactable_top
@onready var interactable_bottom

func _ready():
	top_sensor.body_entered.connect(_top_detected)
	top_sensor.body_exited.connect(_top_lost)
	bottom_sensor.body_entered.connect(_interact_detected)
	bottom_sensor.body_exited.connect(_interact_lost)

func _top_detected(_interact_body):
	if _interact_body.is_in_group("Interactable"):
		interactable_top = _interact_body
		_interact_update()

func _top_lost(_interact_body):
	if _interact_body.is_in_group("Interactable"):
		if interactable_top == _interact_body:
			interactable_top = null
		_interact_update()

func _interact_detected(_interact_body):
	if _interact_body.is_in_group("Interactable"):
		interactable_bottom = _interact_body
		_interact_update()
	
func _interact_lost(_interact_body):
	if _interact_body.is_in_group("Interactable"):
		if interactable_bottom == _interact_body:
			interactable_bottom = null
		_interact_update()
	
func _interact_update():
	print("TOP: " + str(interactable_top) + " BOTTOM: " + str(interactable_bottom))
	interact_updated.emit(interactable_bottom,interactable_top)
