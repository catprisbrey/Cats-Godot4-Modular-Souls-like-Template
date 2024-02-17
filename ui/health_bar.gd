extends TextureProgressBar
class_name HealthBar

@export var health_system : HealthSystem

# Called when the node enters the scene tree for the first time.
func _ready():
	if health_system:
		max_value = health_system.total_health
		value = health_system.total_health
		health_system.health_updated.connect(_on_health_updated)

func _on_health_updated(new_health):
	value = new_health
