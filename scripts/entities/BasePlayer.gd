class_name BasePlayer extends CharacterBody3D

var camera: Camera3D

var weapons: Array[BaseWeapon]
var current_weapon: BaseWeapon
var weapon_model

# Constants
var mouse_sensitivity := 0.4
var move_speed := 190.0
var sprint_speed := 320.0
var view_height_stand: float = Global.src_to_gd(64.0)

var health := 0
var max_health := 100
var surfaceFriction := 0.0

var forwardMove := 0.0
var sideMove := 0.0
var upMove := 0.0
var jump_timer := 0.0

func _ready():
	# create the camera using our fov and mark it as current
	camera = Camera3D.new()
	add_child(camera)
	camera.fov = 75.0
	camera.position.y = view_height_stand
	
	# collision mesh
	var col_shape = CollisionShape3D.new()
	add_child(col_shape)
	col_shape.shape = CapsuleShape3D.new()
	# https://developer.valvesoftware.com/wiki/Dimensions_(Half-Life_2_and_Counter-Strike:_Source)#Map_Grid_Units:_Quick_Reference
	col_shape.shape.height = 1.4
	col_shape.position.y = col_shape.shape.height / 2 # it centers the shape and we don't want that
	
	health = max_health
	
	add_weapon(WeaponPhyscannon.new())
	_swap_weapon(0)

func _process(delta):
	_update_debug_text()

# checks against velocity and is_on_floor
func is_grounded() -> bool:
	if (velocity.z < 250.0 and Time.get_ticks_msec() > jump_timer):
		return is_on_floor()
	return false

func _update_debug_text():
	DevUI.get_node("cl/rootpanel/showpos").text = "pos: " + str(position) + "\n"\
	+ "rot: " + str(rotation) + "\n"\
	+ "vel: " + str(velocity)

func _do_move_slide():
	# convert to godot to move normally
	velocity = Vector3(
		Global.src_to_gd(velocity.x),
		Global.src_to_gd(velocity.z),
		Global.src_to_gd(velocity.y)
	)
	
	move_and_slide()
	
	# swap velocity back to source measurements
	velocity = Vector3(
		Global.gd_to_src(velocity.x),
		Global.gd_to_src(velocity.z),
		Global.gd_to_src(velocity.y)
	)

func _physics_process(delta):
	if (Input.is_action_pressed("quit")):
		get_tree().quit()
		
	# capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if (Input.is_action_pressed("move_left")):
		sideMove = -1.0 * Global.cl_sidespeed
	elif (Input.is_action_pressed("move_right")):
		sideMove = 1.0 * Global.cl_sidespeed
	else:
		sideMove = 0.0
	
	if (Input.is_action_pressed("move_forwards")):
		forwardMove = 1.0 * Global.cl_forwardspeed
	elif (Input.is_action_pressed("move_back")):
		forwardMove = -1.0 * Global.cl_forwardspeed
	else:
		forwardMove = 0.0
	
	_get_surface_friction()
	if (is_grounded()):
		_full_walk_move()
	else:
		_full_toss_move()
	
	# Weapon Code
	current_weapon.weapon_idle()
	
	if (Input.is_action_pressed("fire_primary")):
		current_weapon.fire_primary(!Input.is_action_just_pressed("fire_primary"))
	
	if (Input.is_action_pressed("fire_secondary")):
		current_weapon.fire_secondary(!Input.is_action_just_pressed("fire_secondary"))

func _get_surface_friction():
	surfaceFriction = 1.0

	for i in range(0, get_slide_collision_count()):
		var col = get_slide_collision(i)
		# check if this even qualifies as floor
		if (col.get_angle() < floor_max_angle):
			
			if (col.get_collider().physics_material_override != null):
				surfaceFriction = col.get_collider().physics_material_override.friction
				break
	
	# Comment from source-sdk-2013/sp:gamemovement.cpp#L928
	# HACKHACK: Scale this to fudge the relationship between vphysics friction values and player friction values.
	# A value of 0.8f feels pretty normal for vphysics, whereas 1.0f is normal for players.
	# This scaling trivially makes them equivalent.  REVISIT if this affects low friction surfaces too much.
	surfaceFriction *= 1.25
	if (surfaceFriction > 1.0):
		surfaceFriction = 1.0

func _full_toss_move():
	# add velocity if player is moving
	if (forwardMove != 0.0 or sideMove != 0.0 or upMove != 0.0):
		var wishvel: Vector3
		var wishdir: Vector3
		var wishspeed: float
		
		var fmove: float
		var smove: float
		
		# detemine movement angles
		var forward = Vector3.FORWARD.rotated(Vector3.UP, rotation.y).normalized()
		var right = Vector3.RIGHT.rotated(Vector3.UP, rotation.y).normalized()
		forward = Vector3(forward.x, forward.z, forward.y)
		right = Vector3(right.x, right.z, right.y)
		
		# copy movement amounts
		fmove = forwardMove
		smove = sideMove
		
		wishvel = Vector3(
			# determine x and y parts of velocity
			forward.x * fmove + right.x * smove,
			forward.y * fmove + right.y * smove,
			# zero out z part of velocity
			0.0
		)
		
		# determine magnitude of speed of move
		wishdir = Vector3(wishvel)
		wishspeed = wishdir.length()
		wishdir = wishdir.normalized()
		
		# clamp to server defined max speed
		if ((wishspeed != 0.0) and (wishspeed > move_speed)):
			wishvel *= move_speed/wishspeed
			wishspeed = move_speed
		
		# set pmove velocity
		_accelerate(wishdir, wishspeed, Global.sv_accelerate)
	
	# if on ground and not moving, return.
	if (is_grounded() and velocity == Vector3.ZERO):
		return
	
	_check_velocity()
	_apply_gravity()
	
	_do_move_slide()

func _full_walk_move():
	_start_gravity()
	
	if (is_grounded() and Input.is_action_just_pressed("jump")):
		_do_jump()
	
	if (is_grounded()):
		velocity.z = 0
		_friction()
	
	# make sure velocity is valid
	_check_velocity()
	
	if (is_grounded()):
		_walk_move()
	else:
		_air_move()
	
	_check_velocity()
	
	# Add any remaining gravitational component
	_finish_gravity()
	
	# if we are on ground, no downward velocity
	if (is_grounded()):
		velocity.z = 0

func _check_velocity():
	if (velocity.x > Global.sv_maxvelocity):
		print_debug("PM  Got a velocity too high on X:", velocity.x)
		velocity.x = Global.sv_maxvelocity
	elif (velocity.x < -Global.sv_maxvelocity):
		print_debug("PM  Got a velocity too low on X:", velocity.x)
		velocity.x = -Global.sv_maxvelocity
	
	if (velocity.y > Global.sv_maxvelocity):
		print_debug("PM  Got a velocity too high on Y:", velocity.y)
		velocity.y = Global.sv_maxvelocity
	elif (velocity.y < -Global.sv_maxvelocity):
		print_debug("PM  Got a velocity too low on Y:", velocity.y)
		velocity.y = -Global.sv_maxvelocity
	
	if (velocity.z > Global.sv_maxvelocity):
		print_debug("PM  Got a velocity too high on Z:", velocity.z)
		velocity.z = Global.sv_maxvelocity
	elif (velocity.z < -Global.sv_maxvelocity):
		print_debug("PM  Got a velocity too low on Z:", velocity.z)
		velocity.z = -Global.sv_maxvelocity

func _walk_move():
	var wishvel: Vector3
	var wishdir: Vector3
	var wishspeed: float
	
	var fmove: float
	var smove: float
	
	# detemine movement angles
	var forward = Vector3.FORWARD.rotated(Vector3.UP, rotation.y).normalized()
	var right = Vector3.RIGHT.rotated(Vector3.UP, rotation.y).normalized()
	forward = Vector3(forward.x, forward.z, forward.y)
	right = Vector3(right.x, right.z, right.y)
	
	# copy movement amounts
	fmove = forwardMove
	smove = sideMove
	
	wishvel = Vector3(
		# determine x and y parts of velocity
		forward.x * fmove + right.x * smove,
		forward.y * fmove + right.y * smove,
		# zero out z part of velocity
		0.0
	)
	
	# determine magnitude of speed of move
	wishdir = Vector3(wishvel)
	wishspeed = wishdir.length()
	wishdir = wishdir.normalized()
	
	# clamp to server defined max speed
	if ((wishspeed != 0.0) and (wishspeed > move_speed)):
		wishvel *= move_speed/wishspeed
		wishspeed = move_speed
	
	# set pmove velocity
	velocity.z = 0
	_accelerate(wishdir, wishspeed, Global.sv_accelerate)
	velocity.z = 0
	
	# add in any base velocity to the current velocity
	# todo: base velocity
	
	# actually move
	_do_move_slide()

func _air_move():
	var wishvel: Vector3
	var wishdir: Vector3
	var wishspeed: float

	var fmove: float
	var smove: float
	
	# detemine movement angles
	var forward = Vector3.FORWARD.rotated(Vector3.UP, rotation.y).normalized()
	var right = Vector3.RIGHT.rotated(Vector3.UP, rotation.y).normalized()
	forward = Vector3(forward.x, forward.z, forward.y)
	right = Vector3(right.x, right.z, right.y)
	
	# copy movement amounts
	fmove = forwardMove
	smove = sideMove
	
	# zero out z components of movement vectors
	forward.z = 0.0
	right.z = 0.0
	
	wishvel = Vector3(
		# determine x and y parts of velocity
		forward.x * fmove + right.x * smove,
		forward.y * fmove + right.y * smove,
		# zero out z part of velocity
		0.0
	)
	
	# determine magnitude of speed of move
	wishdir = Vector3(wishvel)
	wishspeed = wishdir.length()
	wishdir = wishdir.normalized()
	
	# clamp to server defined max speed
	if ((wishspeed != 0.0) and (wishspeed > sprint_speed)):
		wishvel *= sprint_speed/wishspeed
		wishspeed = sprint_speed
	
	_air_accelerate(wishdir, wishspeed, Global.sv_airaccelerate)
	
	_do_move_slide()

func _air_accelerate(wishdir: Vector3, wishspeed: float, accel: float):
	var addspeed: float
	var accelspeed: float
	var currentspeed: float
	var wishspd := wishspeed
	
	# cap speed
	if (wishspd > 30.0):
		wishspd = 30.0
	
	# see if we are changing direction a bit
	currentspeed = velocity.dot(wishdir)
	
	# reduse wishspeed by the amount of veer.
	addspeed = wishspeed - currentspeed
	
	# if not going to add any speed, done
	if (addspeed <= 0):
		return
	
	# determine amount of acceleration
	accelspeed = accel * wishspeed * get_physics_process_delta_time() * surfaceFriction
	
	# cap at addspeed
	if (accelspeed > addspeed):
		accelspeed = addspeed
	
	# adjust velocity
	velocity += accelspeed * wishdir

func _accelerate(wishdir: Vector3, wishspeed: float, accel: float):
	var addspeed: float
	var accelspeed: float
	var currentspeed: float
	
	# see if we are changing direction a bit
	currentspeed = velocity.dot(wishdir)
	
	# reduse wishspeed by the amount of veer.
	addspeed = wishspeed - currentspeed
	
	# if not going to add any speed, done
	if (addspeed <= 0.0):
		return
	
	# determine amount of acceleration
	accelspeed = accel * wishspeed * get_physics_process_delta_time() * surfaceFriction
	
	# cap at addspeed
	if (accelspeed > addspeed):
		accelspeed = addspeed
	
	# adjust velocity
	velocity += accelspeed * wishdir

func _start_gravity():
	# todo: ent_gravity
	
	# Add gravity so they'll be in the correct position during movement
	# yes, this 0.5 looks wrong, but it's not
	velocity.z -= (Global.sv_gravity * 0.5 * get_physics_process_delta_time())
	# todo: base velocity?
	
	_check_velocity()

func _apply_gravity():
	# https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/sp/src/game/shared/gamemovement.cpp#L3104
	velocity.z -= Global.sv_gravity * get_physics_process_delta_time()
	
	_check_velocity()

func _finish_gravity():
	# Get the correct velocity for the end of the dt 
	velocity.z -= Global.sv_gravity * get_physics_process_delta_time() * 0.5
	
	_check_velocity()

func _friction():
	var speed = velocity.length()
	if (speed < 0.1):
		return
	
	var drop = 0.0
	
	# friction
	if (is_grounded()):
		var friction = surfaceFriction * Global.sv_friction
		var control = Global.sv_stopspeed if speed < Global.sv_stopspeed else speed
		drop += control * friction * get_physics_process_delta_time()
	
	# scale the velocity
	var newspeed = speed - drop
	if (newspeed < 0.0):
		newspeed = 0.0
	
	if (newspeed != speed):
		# determine proportion of old speed we are using
		newspeed /= speed
		velocity *= newspeed
	
	# todo: we should make this wishvelocity!
	#velocity -= (1.0 - newspeed) * velocity

func _do_jump():
	var flMul := sqrt(2.0 * Global.sv_gravity * Global.GAMEMOVEMENT_JUMP_HEIGHT)
	
	# Accelerate upward
	# todo: jumpfactor on surfaces!
	velocity.z += 1.0 * flMul
	
	_finish_gravity()
	
	jump_timer = Time.get_ticks_msec() + Global.GAMEMOVEMENT_JUMP_TIME

func get_eye_height() -> float:
	return view_height_stand

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
