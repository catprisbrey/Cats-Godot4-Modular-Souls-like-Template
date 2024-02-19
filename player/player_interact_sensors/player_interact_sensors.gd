extends Node3D
class_name PlayerInteractSensors

## Player node's figurative "eye balls". This will sense objects in layer 4 by 
## default, but can be overridden by setting the detection_mask layers. 
## This detects objects in the detection_group of that layer.
## This class focuses ONLY on detection and signalling out what was seen 
## and which sensor saw it. Actual activation of interactable objects 
## happens between a 'handshake' exchange between the player and the interactable
## node.


@export_flags_3d_physics var detection_mask = 8
@export var detection_group = "Interactable"
@onready var top_sensor = $TopSensor
@onready var bottom_sensor = $BottomSensor

signal interact_updated

@onready var interactable_top
@onready var interactable_bottom

func _ready():
	top_sensor.collision_layer = detection_mask
	bottom_sensor.collision_mask = detection_mask
	
	top_sensor.body_entered.connect(_top_body_entered)
	top_sensor.body_exited.connect(_top_body_exited)
	bottom_sensor.body_entered.connect(_bottom_body_entered)
	bottom_sensor.body_exited.connect(_bottom_body_exited)

func _top_body_entered(_top_body):
	if _top_body.is_in_group(detection_group):
		interactable_top = _top_body
		_interact_update()

func _top_body_exited(_top_body):
	if _top_body.is_in_group(detection_group):
		if interactable_top == _top_body:
			interactable_top = null
		_interact_update()

func _bottom_body_entered(_bottom_body):
	if _bottom_body.is_in_group(detection_group):
		interactable_bottom = _bottom_body
		_interact_update()
	
func _bottom_body_exited(_bottom_body):
	if _bottom_body.is_in_group(detection_group):
		if interactable_bottom == _bottom_body:
			interactable_bottom = null
		_interact_update()
	
func _interact_update():
	## This updates the interactable objects and
	## which sensor spotted it if you have an 
	## if an interact sensor added to the export.
	var interactable
	var interact_loc
	if interactable_bottom && interactable_top:
		interactable = interactable_bottom
		interact_loc = "BOTH"
	elif interactable_bottom && interactable_top == null:
		interactable = interactable_bottom
		interact_loc = "BOTTOM"
	elif interactable_bottom == null && interactable_top:
		interactable = interactable_top
		interact_loc = "TOP"
	else:
		interactable = null
		interact_loc = ""
	print(interactable)
	interact_updated.emit(interactable,interact_loc)
