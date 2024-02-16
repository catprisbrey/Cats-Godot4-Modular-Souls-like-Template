extends Node
class_name HealthSystem

@export var total_health : int = 5
@onready var current_health = total_health
@export var hit_reporting_node : Node
@export var damage_signal :String = "damage_taken"

@export var heal_reporting_node : Node
@export var heal_signal : String = "health_received"

signal health_updated
signal died

func _ready():
	if hit_reporting_node:
		if hit_reporting_node.has_signal(damage_signal):
			hit_reporting_node.connect(damage_signal,_on_damage_signal)

	if heal_reporting_node:
		if heal_reporting_node.has_signal(heal_signal):
			heal_reporting_node.connect(heal_signal,_on_health_signal)
			
func _on_damage_signal(_by_what):
	var damage_power = _by_what.power
	current_health -= damage_power
	health_updated.emit(current_health)
	if current_health <= 0:
		died.emit()

func _on_health_signal(_by_what):
	var healing_power = _by_what.power
	current_health += healing_power
	if current_health > total_health:
		current_health = total_health
	health_updated.emit(current_health)
