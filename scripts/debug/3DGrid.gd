extends MeshInstance3D

func _physics_process(delta):
	position.x = get_viewport().get_camera_3d().position.x
	position.z = get_viewport().get_camera_3d().position.z
