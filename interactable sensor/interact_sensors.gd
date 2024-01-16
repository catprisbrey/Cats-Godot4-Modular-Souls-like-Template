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
	top_sensor.body_entered.connect(_top_body_entered)
	top_sensor.body_exited.connect(_top_body_exited)
	bottom_sensor.body_entered.connect(_bottom_body_entered)
	bottom_sensor.body_exited.connect(_bottom_body_exited)

func _top_body_entered(_top_body):
	if _top_body.is_in_group("Interactable"):
		interactable_top = _top_body
		_interact_update()

func _top_body_exited(_top_body):
	if _top_body.is_in_group("Interactable"):
		if interactable_top == _top_body:
			interactable_top = null
		_interact_update()

func _bottom_body_entered(_bottom_body):
	if _bottom_body.is_in_group("Interactable"):
		interactable_bottom = _bottom_body
		_interact_update()
	
func _bottom_body_exited(_bottom_body):
	if _bottom_body.is_in_group("Interactable"):
		if interactable_bottom == _bottom_body:
			interactable_bottom = null
		_interact_update()
	
func _interact_update():
	#print("TOP: " + str(interactable_top) + " BOTTOM: " + str(interactable_bottom))
	interact_updated.emit(interactable_bottom,interactable_top)
