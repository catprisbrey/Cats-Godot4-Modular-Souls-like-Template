extends BoneAttachment3D

## A raycast senses when the floor is present below the foot and triggers
## a footstep sound. It toggles an "on_floor" boolean so it only one-shot's 
## the audio. Select the external skeleton and point it to your player's body.
## Select an appopriate toe, foot, or leg bone. 

## If the raycast isn't facing the floor, make the system local, and then adjust
## the pivot x rotation. 60 degrees forward facing is usually enough to sense 
## footfalls on ladders/walls as well. 

## A forward rotation 
## Footfall sounds are randomly picked between the two audio files provided

@onready var floorcast = $Pivot/Floorcast
@onready var step_audio = $StepAudio
@onready var on_floor = true

@export var sound_1 : AudioStream = preload("res://player/footfall_system/footstep.wav")
@export var sound_2 : AudioStream = preload("res://player/footfall_system/footstep.wav")

func _physics_process(_delta):
	make_sound()
	reset_step()

func reset_step():
	if !floorcast.is_colliding():
		on_floor = false
		
func make_sound():
	if on_floor == false:
		if floorcast.is_colliding():
			play_footfall()
			on_floor = true

func play_footfall():
	step_audio.pitch_scale = randf_range(.5,1.0)
	step_audio.play()

	var new_stream
	match randi_range(1,2):
		1: new_stream = sound_1
		2: new_stream = sound_2
	step_audio.stream = new_stream
	step_audio.pitch_scale = randf_range(.5,1)
	step_audio.play()
