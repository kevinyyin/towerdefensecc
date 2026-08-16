extends Control

@export var color := Color(0.95, 0.8, 0.2)

func _draw() -> void:
	draw_circle(size / 2.0, size.x / 2.0, color)
