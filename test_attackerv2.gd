extends Area3D

@onready var animation_player = $"../AnimationPlayer"
@export var facts : EquipmentResource = EquipmentResource.new()

func _ready():
	animation_player.play("spin")

func _on_body_entered(body):
	if body.is_in_group("Player"):
		if body.has_method("hit"):
			set_deferred("monitoring",false)
			body.hit(self,facts)
			await get_tree().create_timer(.5).timeout
			set_deferred("monitoring",true)

func parried():
	set_deferred("monitoring",false)
	animation_player.play("parried")
	await get_tree().create_timer(.5).timeout
	animation_player.play("spin")
	set_deferred("monitoring",true)

