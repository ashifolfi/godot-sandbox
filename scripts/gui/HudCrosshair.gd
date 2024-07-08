@tool
class_name HudCrosshair extends Control

const crosshair = preload("res://resource/hud/crosshairs.png")

func _draw():
	var location = size / 2
	draw_texture(crosshair, location - (crosshair.get_size() / 2))
