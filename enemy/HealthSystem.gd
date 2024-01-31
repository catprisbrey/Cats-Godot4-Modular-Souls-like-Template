extends Node

@export var total_health : int = 5
@onready var current_health = total_health
@export var hit_reporting_node : Node
@export var damage_signal :String = "damage_taken"


signal died

func _ready():
	if hit_reporting_node:
		if hit_reporting_node.has_signal(damage_signal):
			hit_reporting_node.connect(damage_signal,_on_damage_signal)

func _on_damage_signal(_by_what : EquipmentResource):
	var damage_power = _by_what.power
	current_health -= damage_power
	if current_health <= 0:
		died.emit()
