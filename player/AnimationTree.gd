extends AnimationTree
@onready var player = $".."

var movement = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_movement():
	set("parameters/Light_tree/MoveStrafe/blend_position", movement)
