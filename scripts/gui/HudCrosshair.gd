@tool
class_name HudCrosshair extends Control

const crosshair = preload("res://resource/hud/crosshairs.png")

func _draw():
	var location = get_viewport_rect().size / 2
	draw_texture(crosshair, location - (crosshair.get_size() / 2))
