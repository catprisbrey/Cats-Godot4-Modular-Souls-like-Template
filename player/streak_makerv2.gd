extends MeshInstance3D

@export var lifetime : float = .2 
@onready var mesh_array = []
@onready var timer_test = Timer.new()
@onready var top
@onready var bottom

class edge:
	var top_p : Vector3
	var bottom_p : Vector3

func _ready():
	
	add_child(timer_test)
	timer_test.autostart = false
	timer_test.one_shot = true
	timer_test.start(1)

func _input(event):
	if event.is_action_pressed("use_weapon_light"):
		timer_test.start()
		

func _process(_delta):
	top = get_parent().to_global(Vector3.ZERO)
	bottom = get_parent().to_global(Vector3.UP)
	
	if timer_test.time_left:
		create_edge()
		
	else:
		remove_edge()
	mesh_update()

	print(mesh_array.size())


func mesh_update():
	#mesh.clear_surfaces()
	#if mesh_array.size() != 0:
		#mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		#for each_edge in mesh_array.size()-1:
			#mesh.surface_add_vertex(mesh_array[each_edge].top_p)
			#mesh.surface_add_vertex(mesh_array[each_edge].bottom_p)
		#mesh.surface_end()
	if mesh_array.size() != 0:
		var arrays = PackedVector3Array
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = mesh_array

		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays)

	
func create_edge():
	#var new_edge = edge.new()
	#new_edge.bottom_p = bottom
	#new_edge.top_p =  top
	#mesh_array.append(new_edge)
	mesh_array.append(top)
	mesh_array.append(bottom)
	
func remove_edge():
	if mesh_array.size() != 0:
		mesh_array.pop_back()


