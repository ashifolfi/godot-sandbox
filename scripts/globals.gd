extends Node

# funny physics calculations
# https://developer.valvesoftware.com/wiki/Dimensions_(Half-Life_2_and_Counter-Strike:_Source)#Source_Engine_Scale_Calculations
# https://developer.valvesoftware.com/wiki/VPhysics#Units
func src_to_gd(units):
	return units * 0.01905

func gd_to_src(units):
	return units / 0.01905

# in/s to m/s
func src_vel(inches):
	return inches * 0.0254

var sounds: Dictionary

# Constants
const tickrate = 66
# https://developer.valvesoftware.com/wiki/Gravity
const sv_gravity = 600.0
const sv_friction = 4.0
const sv_stopspeed = 100.0
const sv_accelerate = 10.0
const sv_maxspeed = 320.0
const sv_maxvelocity = 3500.0
const sv_airaccelerate = 10.0
const cl_forwardspeed = 450.0
const cl_sidespeed = 450.0

const GAMEMOVEMENT_DUCK_TIME = 1000.0 # ms
const GAMEMOVEMENT_JUMP_TIME = 510.0 # ms
const GAMEMOVEMENT_JUMP_HEIGHT = 21.0

func _ready():
	ProjectSettings.set_setting("physics/common/physics_ticks_per_second", tickrate)

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
