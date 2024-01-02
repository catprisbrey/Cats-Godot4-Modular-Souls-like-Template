extends AnimationTree
 
@export var player_node : CharacterBody3D
@onready var state_machine :AnimationNodeStateMachinePlayback= self["parameters/Light_tree/playback"]
var movement = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	#self["parameters/playback"].travel("Light_tree")
	#state_machine.travel("MoveStrafe")
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	set_movement()
	
func set_movement():
	print(player_node.strafe_cross_product.y)
	set("parameters/Light_tree/MoveStrafe/blend_position", Vector2(player_node.strafe_cross_product.y,0))
		
