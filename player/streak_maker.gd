extends MeshInstance3D
class_name MeshStreak

@onready var mesh_array = []

@export var lifetime = .4
@export var use_end_signal : bool = false
## The node with the signal to start (and perhaps end) mesh streak.
@export var trigger_node : Node
@export var start_trigger_signal : String = "attack_swing_started"
@export var end_trigger_signal : String = "attack_ended"

## Node where the mesh will base it's own origin points.
@export var origin_node: Node3D = self
## Where the bottom of the steak points should start in relation to the origin node.
@export var streak_bottom = Vector3.ZERO
## Where the top of the steak points should start in relation to the origin node.
@export var streak_top = Vector3.UP

## Recommend to turn shading off, and use transparency or glow for a cool look.
@export var new_material : StandardMaterial3D = StandardMaterial3D.new()

@onready var counter : int = 0
@onready var activated : bool


class edge:
	var top_p : Vector3
	var bottom_p : Vector3

func _ready():
	top_level =  true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	new_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	if trigger_node:
		trigger_node.connect(start_trigger_signal,_on_start_trigger_signal)
		if use_end_signal:
			trigger_node.connect(end_trigger_signal,_on_end_trigger_signal)
	else:
		printerr("No trigger node assigned to start the mesh strekk")
	
	if origin_node == null:
		origin_node = get_parent()

func _on_start_trigger_signal():
	activated = true
	if !use_end_signal:
		await get_tree().create_timer(lifetime).timeout
		activated = false
	
func _on_end_trigger_signal():
	activated = false

func _process(_delta):
	
	if activated:
		counter += 1
		if counter > 1:
			counter = 0
		
		if counter == 0:
			create_edge()
			mesh_update()
	else:
		if mesh_array.size() != 0:
			remove_edge()
			mesh_update()

func mesh_update():
	if mesh_array.size() != 0:
		var surface_tool = SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		surface_tool.set_material(new_material)

		for each_edge in mesh_array:
			surface_tool.add_vertex(each_edge.top_p)
			surface_tool.add_vertex(each_edge.bottom_p)
		mesh = surface_tool.commit()
	
func create_edge():
	var new_top = origin_node.to_global(streak_top)
	var new_bottom = origin_node.to_global(streak_bottom)
	var new_edge = edge.new()
	new_edge.bottom_p = new_bottom
	new_edge.top_p =  new_top
	## to avoid duplicates
	if mesh_array.size() != 0:
		if mesh_array[mesh_array.size() -1] != new_edge:
			mesh_array.append(new_edge)
	else:
		mesh_array.append(new_edge)
	
func remove_edge():
	mesh_array.pop_front()

