class_name FreeCam extends Camera3D

const mouse_sensitivity = 0.4
const move_speed = 0.5

var capture_mode = false

func _physics_process(delta):
	# capture mouse when moving
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if capture_mode else Input.MOUSE_MODE_VISIBLE
	
	if (!capture_mode):
		return # don't do anything when not captured
	
	var deltaMove = Vector3(
		cos(rotation.y) * move_speed,
		sin(rotation.y) * move_speed,
		sin(rotation.x) * move_speed
	)
	
	if (Input.is_action_pressed("move_left")):
		position.x -= deltaMove.x
		position.z += deltaMove.y
	if (Input.is_action_pressed("move_right")):
		position.x += deltaMove.x
		position.z -= deltaMove.y
		
	if (Input.is_action_pressed("move_forwards")):
		position.x -= deltaMove.y
		position.z -= deltaMove.x
		position.y += deltaMove.z
	if (Input.is_action_pressed("move_back")):
		position.x += deltaMove.y
		position.z += deltaMove.x
		position.y -= deltaMove.z

func _input(event):
	if (event is InputEventMouseButton):
		if (event.button_index == MOUSE_BUTTON_RIGHT):
			capture_mode = event.pressed
	
	if (!capture_mode):
		return # don't do anything when not captured
	
	if (event is InputEventMouseMotion):
		# change camera rotation based on mouse movement
		rotation_degrees.x -= (event.relative.y * mouse_sensitivity)
		rotation_degrees.y -= (event.relative.x * mouse_sensitivity)
		
		rotation_degrees.x = clamp(rotation_degrees.x, -90, 90)
