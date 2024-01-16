extends Area3D

@onready var animation_player = $"../AnimationPlayer"

func _ready():
	animation_player.play("spin")

func _on_body_entered(body):
	if body.is_in_group("Player"):
		if body.has_method("hit"):
			body.hit(self)

		
func parried():
	animation_player.play("parried")
	await animation_player.animation_finished
	animation_player.play("spin")
