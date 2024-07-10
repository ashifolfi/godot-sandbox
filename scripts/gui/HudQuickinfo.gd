@tool
class_name HudQuickInfo extends Control

const icon_chl = preload("res://resource/hud/crosshair_left.svg")
const icon_chle = preload("res://resource/hud/crosshair_left_empty.svg")
const icon_chlf = preload("res://resource/hud/crosshair_left_full.svg")
const icon_chr = preload("res://resource/hud/crosshair_right.svg")
const icon_chre = preload("res://resource/hud/crosshair_right_empty.svg")
const icon_chrf = preload("res://resource/hud/crosshair_right_full.svg")

const icon_scale = 0.10

@export_range(0.0, 1.0, 0.1) var progress_health := 1.0
@export_range(0.0, 1.0, 0.1) var progress_ammo := 1.0

var prev_progress_health := 0.0
var prev_progress_ammo := 0.0

func _ready():
	# apply recolor material
	material = ShaderMaterial.new()
	material.shader = load("res://shaders/RecolorUI.gdshader")
	material.set_shader_parameter("color", Color(1.0, 0.78, 0.0, 1.0))

func _process(delta):
	if (prev_progress_ammo != progress_ammo):
		prev_progress_ammo = progress_ammo
		queue_redraw()
	
	if (prev_progress_health != progress_health):
		prev_progress_health = progress_health
		queue_redraw()

func _draw():
	var location = get_viewport_rect().size / 2
	
	var scaled_size_l = icon_chle.get_size() * icon_scale
	scaled_size_l.x *= 2
	scaled_size_l.y /= 2
	
	var scaled_size_r = icon_chre.get_size() * icon_scale
	scaled_size_r.y = -(scaled_size_r.y / 2)
	
	var progress_rect_health = Rect2(
		0.0,
		icon_chlf.get_height() * abs(1.0 - progress_health),
		icon_chlf.get_width(),
		icon_chlf.get_height() * progress_health
	)
	
	var progress_rect_ammo = Rect2(
		0.0,
		icon_chlf.get_height() * abs(1.0 - progress_ammo),
		icon_chlf.get_width(),
		icon_chlf.get_height() * progress_ammo
	)
	
	draw_set_transform(location - scaled_size_l, 0.0, Vector2(icon_scale, icon_scale))
	draw_texture(icon_chle, Vector2.ZERO)
	draw_texture_rect_region(icon_chlf, progress_rect_health, progress_rect_health)
	
	draw_set_transform(location + scaled_size_r, 0.0, Vector2(icon_scale, icon_scale))
	draw_texture(icon_chre, Vector2.ZERO)
	draw_texture_rect_region(icon_chrf, progress_rect_ammo, progress_rect_ammo)
