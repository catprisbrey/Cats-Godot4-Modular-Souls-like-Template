extends OmniLight3D

@onready var default_energy :float = self.light_energy
@onready var timer = Timer.new()
@onready var new_target :float
# Called when the node enters the scene tree for the first time.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready():
	timer.autostart = true
	timer.one_shot = false
	timer.wait_time = .5
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
	

func _process(_delta):
		light_energy = move_toward(light_energy, new_target,.2)
	
func _on_timer_timeout():
	new_target = default_energy + randf_range(-.3,.2)
	var new_time = randf_range(.05,.2)
	timer.start(new_time)
	
