extends OmniLight3D

@onready var tween : Tween
# Called when the node enters the scene tree for the first time.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready():
	tween = create_tween()
	tween.connect("finished",_on_tween_finished)
	await get_tree().process_frame
	_on_tween_finished()

func _on_tween_finished():
	tween.stop()
	tween.tween_property(self,"light_energy", randf(),randf_range(.1,.2))
	tween.play()
