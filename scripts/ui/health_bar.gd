extends Node2D

@export var width := 28.0
@export var height := 4.0
@export var background_color := Color(0.15, 0.15, 0.15, 0.85)
@export var fill_color := Color(0.2, 0.85, 0.3, 1.0)

var fraction := 1.0:
	set(value):
		fraction = clamp(value, 0.0, 1.0)
		queue_redraw()

func _draw() -> void:
	var half_w := width / 2.0
	draw_rect(Rect2(-half_w, 0.0, width, height), background_color)
	draw_rect(Rect2(-half_w, 0.0, width * fraction, height), fill_color)
