extends Node

# funny physics calculations
# https://developer.valvesoftware.com/wiki/Dimensions_(Half-Life_2_and_Counter-Strike:_Source)#Source_Engine_Scale_Calculations
# https://developer.valvesoftware.com/wiki/VPhysics#Units
func src_to_gd(units):
	return units * 0.01905

# in/s to m/s
func src_vel(inches):
	return inches * 0.0254

var sounds: Dictionary

# Constants
const tickrate = 66
const source_gravity = 600.0

var gravity

func _ready():
	ProjectSettings.set_setting("physics/common/physics_ticks_per_second", tickrate)
	# https://developer.valvesoftware.com/wiki/Gravity
	gravity = src_to_gd(sqrt(source_gravity / tickrate))

func debug_draw_ray(from, to, color):
	var mi3d = MeshInstance3D.new()
	mi3d.mesh = ImmediateMesh.new()
	
	mi3d.mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	mi3d.mesh.surface_set_color(color)
	mi3d.mesh.surface_add_vertex(from)
	mi3d.mesh.surface_set_color(color)
	mi3d.mesh.surface_add_vertex(to)
	
	mi3d.mesh.surface_end()
	
	get_tree().current_scene.add_child(mi3d)
