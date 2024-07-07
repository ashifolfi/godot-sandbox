class_name WorldSpawn extends Node3D

const PLAYER_CLASS = "BasePlayer"

func _ready():
	var spawn_pos: Vector3 = Vector3.ZERO
	var spawn_angle: float # we only modify left and right
	
	# find the first instance of player start
	var found_spawn = false
	for child in get_children():
		if child is InfoPlayerStart:
			spawn_pos = child.global_position
			spawn_angle = child.global_rotation.y
			found_spawn = true
			break
	
	if (!found_spawn):
		push_warning("No info_player_start within the map! Spawning at origin!")
	
	var found_class = ""
	for class_inf in ProjectSettings.get_global_class_list():
		if (class_inf.class == PLAYER_CLASS):
			found_class = class_inf.path
	
	if (found_class == ""):
		push_error("PLAYER_CLASS is invalid!")
	else:
		var player = (load(found_class) as Script).new()
		add_child(player)
		player.global_position = spawn_pos
		player.global_rotation.y = spawn_angle
