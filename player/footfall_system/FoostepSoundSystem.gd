extends Node3D
class_name FootstepSoundSystem

## Receives signal from FootfallSensors for when a foot steps down or up.
## The signal will trigger a randonmized step sound or pants swoosh sound.
## 'Make Local' this node and be sure to assign the bones to the each foot,
## as well as 'make local' the feet nodes if to adjust their pivot x rotation
## if they arent' pointed toward the floor.

@export var left_foot : FootfallSensor
@export var right_foot : FootfallSensor

@export var step_sound :AudioStream
@export var pant_sound :AudioStream

@onready var footsteps = $Footsteps
@onready var pant_swish = $Pantswish

# Called when the node enters the scene tree for the first time.
func _ready():
	
	if left_foot:
		left_foot.foot_stepped.connect(_on_foot_stepped)
		left_foot.foot_lifted.connect(_on_foot_lifted)
		
	if right_foot:
		right_foot.foot_stepped.connect(_on_foot_stepped)
		right_foot.foot_lifted.connect(_on_foot_lifted)

	if step_sound:
		footsteps.stream = step_sound
	if pant_sound:
		pant_swish.stream = pant_sound
	
func _rando_foot_play():
	footsteps.pitch_scale = randf_range(.9,1.2)
	footsteps.play()

func _rando_pants_play():
	pant_swish.pitch_scale = randf_range(.9,1.2)
	pant_swish.play()

func _on_foot_stepped():
	_rando_foot_play()

func _on_foot_lifted():
	_rando_pants_play()
