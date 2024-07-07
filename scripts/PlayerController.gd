class_name PlayerController extends CharacterBody3D

@export_group("Attached Objects")
@export var camera: Camera3D
@export var vm_camera: Camera3D

var weapons: Array[BaseWeapon]
var current_weapon : BaseWeapon
var weapon_model

# Constants
var mouse_sensitivity: float = 0.4
var move_speed: float = Global.src_to_gd(250.0)

var health
var max_health = 100

func _ready():
	health = max_health
	
	add_weapon(WeaponPhyscannon.new())
	_swap_weapon(0)

func _process(delta):
	_update_debug_text()

func _update_debug_text():
	DevUI.get_node("cl/rootpanel/showpos").text = "pos: " + str(position) + "\n"\
	+ "rot: " + str(rotation) + "\n"\
	+ "vel: " + str(velocity)

func _physics_process(delta):
	if (Input.is_action_pressed("quit")):
		get_tree().quit()
	
	# capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	velocity = Vector3(0, velocity.y, 0)
	
	var deltaMove = Vector3(
		cos(rotation.y),
		sin(rotation.y),
		sin(camera.rotation.x)
	).normalized() * (move_speed)
	
	if (Input.is_action_pressed("move_left")):
		velocity.x -= deltaMove.x
		velocity.z += deltaMove.y
	if (Input.is_action_pressed("move_right")):
		velocity.x += deltaMove.x
		velocity.z -= deltaMove.y
	
	if (Input.is_action_pressed("move_forwards")):
		velocity.x -= deltaMove.y
		velocity.z -= deltaMove.x
	if (Input.is_action_pressed("move_back")):
		velocity.x += deltaMove.y
		velocity.z += deltaMove.x
	
	if (is_on_floor() and Input.is_action_just_pressed("jump")):
		velocity.y += Global.src_to_gd(200.0)
	
	if (!is_on_floor()):
		velocity.y -= Global.src_to_gd(Global.source_gravity) * delta
	
	move_and_slide()
	
	current_weapon.weapon_idle()
	
	if (Input.is_action_pressed("fire_primary")):
		current_weapon.fire_primary(!Input.is_action_just_pressed("fire_primary"))
	
	if (Input.is_action_pressed("fire_secondary")):
		current_weapon.fire_secondary(!Input.is_action_just_pressed("fire_secondary"))

func get_eye_height() -> float:
	return camera.position.y

func get_eye_position() -> Vector3:
	return camera.global_position

func get_facing_vector() -> Vector3:
	return -camera.get_global_transform().basis.z.normalized();

func cast_from_eye(distance):
	var space_state = get_world_3d().direct_space_state

	var target_pos = camera.global_position + (get_facing_vector() * distance)
	
	# cast and ignore the player
	var query = PhysicsRayQueryParameters3D.create(camera.global_position, target_pos)
	query.exclude = [self]
	query.hit_from_inside = true
	return space_state.intersect_ray(query)

func add_weapon(weapon):
	weapons.push_back(weapon)

func _swap_weapon(idx):
	if (current_weapon == weapons[idx]):
		return
	
	if (current_weapon):
		remove_child(current_weapon)
	
	current_weapon = weapons[idx]
	add_child(current_weapon)
	
	if (weapon_model):
		weapon_model.queue_free()
	
	weapon_model = current_weapon.weapon_view_model().instantiate()
	camera.add_child(weapon_model)
	
	# HACK: hl2 models are inverted!
	weapon_model.rotation_degrees.y = 180
	
	current_weapon.animator.anim_player = weapon_model.get_node("AnimationPlayer").get_path()
	current_weapon.animator.advance_expression_base_node = current_weapon.get_path()

func _input(event):
	if (event is InputEventMouseMotion):
		# change full player horizontal rotation based on camera movement
		rotation_degrees.y -= (event.relative.x * mouse_sensitivity)
		
		# change camera vertical rotation based on mouse movement
		camera.rotation_degrees.x -= (event.relative.y * mouse_sensitivity)
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -90, 90)
