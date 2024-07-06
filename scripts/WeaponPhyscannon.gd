class_name WeaponPhyscannon extends BaseWeapon

var punt_force: float = Global.src_vel(1500.0)
var hold_distance: float = 2.5
var fire_distance: float = Global.src_to_gd(250.0)

var holding_object = false
var held_object: RigidBody3D

func weapon_name() -> String:
	return "Gravity Gun"

func weapon_anim_tree() -> AnimationNode:
	return load("res://models/weapons/v_physcannon_animtree.tres")

func weapon_view_model() -> Resource:
	return load("res://models/weapons/weapon_physcannon.glb")

func _grab_object(object):
	held_object = object
	holding_object = true
	
	held_object.axis_lock_angular_x = true
	held_object.axis_lock_angular_y = true
	held_object.axis_lock_angular_z = true
	held_object.gravity_scale = 0.0

func _drop_object():
	held_object.axis_lock_angular_x = false
	held_object.axis_lock_angular_y = false
	held_object.axis_lock_angular_z = false
	holding_object = false
	held_object.gravity_scale = 1.0

func weapon_idle():
	if (holding_object):
		# position object
		var target_pos = get_parent().get_eye_position() + (get_parent().get_facing_vector() * hold_distance)
		held_object.linear_velocity = held_object.position.direction_to(target_pos).normalized()\
		* held_object.position.distance_to(target_pos) * 10
		
		animator["parameters/ProngPosition/blend_amount"] = lerpf(animator["parameters/ProngPosition/blend_amount"], 0.0, 0.2)
		return
		
	
	var cast_res = get_parent().cast_from_eye(fire_distance)
	if (cast_res.get("collider") != null
	and cast_res.get("collider") is RigidBody3D):
		animator["parameters/ProngPosition/blend_amount"] = lerpf(animator["parameters/ProngPosition/blend_amount"], 0.0, 0.2)
	else:
		animator["parameters/ProngPosition/blend_amount"] = lerpf(animator["parameters/ProngPosition/blend_amount"], 1.0, 0.2)

func fire_primary():
	if (holding_object):
		var impulse = get_parent().get_facing_vector() * punt_force
		
		_drop_object()
		held_object.linear_velocity += impulse
		
		animator["parameters/Fire/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		return
	else:
		var cast_res = get_parent().cast_from_eye(fire_distance)
		if (cast_res.get("collider") != null
		and cast_res.get("collider") is RigidBody3D):
			var rb3d = cast_res.get("collider") as RigidBody3D
			var impulse = get_parent().get_facing_vector() * punt_force
			
			rb3d.linear_velocity += impulse
			
			animator["parameters/Fire/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
			return
	
	animator["parameters/FireFail/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

func fire_secondary():
	if (holding_object):
		_drop_object()
	else:
		var cast_res = get_parent().cast_from_eye(fire_distance)
		if (cast_res.get("collider") != null
		and cast_res.get("collider") is RigidBody3D):
			_grab_object(cast_res.get("collider"))
