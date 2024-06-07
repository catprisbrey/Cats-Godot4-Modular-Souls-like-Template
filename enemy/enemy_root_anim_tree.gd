extends AnimationTree

@onready var enemy : CharacterBody3D = get_parent()
@onready var last_oneshot = null
# Called when the node enters the scene tree for the first time.
func _ready():
	enemy.attack_started.connect(_on_attack_started)
	enemy.retreat_started.connect(_on_retreat_started)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	set_movement()

func set_movement():
	var speed : Vector2 = Vector2.ZERO
	var near
	#if enemy.current_state:
	match enemy.current_state:
		enemy.state.FREE:
			near = (enemy.target.global_position.distance_to(enemy.global_position) < .2)
			if near:
				speed.y = 0.0
			else:
				speed.y = .5
		enemy.state.CHASE:
			near = (enemy.target.global_position.distance_to(enemy.global_position) < 4.0)
			if near:
				speed.y = .5
			else:
				speed.y = 1.0
			
	var blend = lerp(get("parameters/Movement/Movement2D/blend_position"),speed,.1)
	set("parameters/Movement/Movement2D/blend_position",blend)

func _on_attack_started():
	request_oneshot("attack")

func _on_retreat_started():
	request_oneshot("retreat")

func request_oneshot(oneshot:String):
	last_oneshot = oneshot
	set("parameters/" + oneshot + "/request",true)
