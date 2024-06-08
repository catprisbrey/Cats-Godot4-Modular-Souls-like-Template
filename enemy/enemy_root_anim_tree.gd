extends AnimationTree

@onready var enemy : CharacterBody3D = get_parent()
@onready var last_oneshot = null
@onready var anim_length : float = .5
@onready var state_machine_node : AnimationNodeStateMachinePlayback = self["parameters/Movement/playback"]
signal animation_measured(anim_length)
@export var max_attack_count : int = 2
@onready var attack_count
@onready var hurt_count :int = 1


# Called when the node enters the scene tree for the first time.
func _ready():
	enemy.attack_started.connect(_on_attack_started)
	enemy.retreat_started.connect(_on_retreat_started)
	enemy.hurt_started.connect(_on_hurt_started)
	enemy.parried_started.connect(_on_parried_started)
	enemy.death_started.connect(_on_death_started)
	
	animation_started.connect(_on_animation_started)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
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
		enemy.state.DEAD:
			speed.y = 0.0
			
	var blend = lerp(get("parameters/Movement/Movement2D/blend_position"),speed,.1)
	set("parameters/Movement/Movement2D/blend_position",blend)

func _on_attack_started():
	attack_count = randi_range(1,max_attack_count)
	request_oneshot("attack")

func _on_retreat_started():
	request_oneshot("retreat")

func request_oneshot(oneshot:String):
	last_oneshot = oneshot
	set("parameters/" + oneshot + "/request",true)

func abort_oneshot(oneshot):
	set("parameters/"+ str(oneshot) + "/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)

func _on_hurt_started():
	hurt_count = randi_range(1,2)
	abort_oneshot(last_oneshot)
	request_oneshot("hurt")

func _on_parried_started():
	abort_oneshot(last_oneshot)
	request_oneshot("parried")
	
func _on_death_started():
	abort_oneshot(last_oneshot)
	state_machine_node.travel("Dead")

func _on_animation_started(anim_name):
	anim_length = get_node(anim_player).get_animation(anim_name).length
	animation_measured.emit(anim_length)
