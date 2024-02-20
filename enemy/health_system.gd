extends Node
class_name HealthSystem

## A very crude health system. A 'hit' reporting node, (player or hit box, etc)
## can emit a damaging signal, or healing signal. That signal shoul dpass the
## the attacking node's information. This system checks for "node.power" of the attack
## or healing effect, and then applies that to healing or hurting.

## It can also work with a "health bar controller" or enemies to show their
## on-screen healthbar for a few seconds after being hit or healed.

@export var total_health : int = 5
@onready var current_health = total_health
@export var hit_reporting_node : Node
@export var damage_signal :String = "damage_taken"

@export var heal_reporting_node : Node
@export var heal_signal : String = "health_received"

@export var health_bar_control : Node
@export var show_time : float = 2
var show_timer : Timer

signal health_updated
signal died

func _ready():
	if hit_reporting_node:
		if hit_reporting_node.has_signal(damage_signal):
			hit_reporting_node.connect(damage_signal,_on_damage_signal)

	if heal_reporting_node:
		if heal_reporting_node.has_signal(heal_signal):
			heal_reporting_node.connect(heal_signal,_on_health_signal)
			
	if health_bar_control:
		health_bar_control.hide()
		show_timer = Timer.new()
		show_timer.one_shot = true
		show_timer.wait_time = show_time
		show_timer.timeout.connect(_on_show_timer_timeout)
		add_child(show_timer)
		
func _physics_process(_delta):
	if show_timer:
		if show_timer.time_left:
			show_health()
		
func _on_damage_signal(_by_what):
	if health_bar_control:
		show_timer.start()
	var damage_power = _by_what.power
	current_health -= damage_power
	health_updated.emit(current_health)
	if current_health <= 0:
		died.emit()

func _on_health_signal(_by_what):
	if health_bar_control:
		show_timer.start()
	var healing_power = _by_what.power
	current_health += healing_power
	if current_health > total_health:
		current_health = total_health
	health_updated.emit(current_health)
	
func show_health():
	var current_camera = get_viewport().get_camera_3d()
	var screenspace = current_camera.unproject_position(hit_reporting_node.global_position)
	health_bar_control.position = screenspace 
	health_bar_control.show()

func _on_show_timer_timeout():
	health_bar_control.hide()
