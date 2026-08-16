extends Control

@export var fill_color := Color(0.85, 0.15, 0.2)
@export var empty_color := Color(0.3, 0.3, 0.3)

@export var filled := true:
	set(value):
		filled = value
		queue_redraw()

func _draw() -> void:
	var color := fill_color if filled else empty_color
	var r := 7.0
	var center := size / 2.0

	draw_circle(center + Vector2(-r * 0.6, -r * 0.3), r, color)
	draw_circle(center + Vector2(r * 0.6, -r * 0.3), r, color)

	var tri := PackedVector2Array([
		center + Vector2(-r * 1.55, r * 0.15),
		center + Vector2(r * 1.55, r * 0.15),
		center + Vector2(0, r * 2.1),
	])
	draw_colored_polygon(tri, color)
