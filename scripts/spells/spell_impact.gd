extends Node2D

@export var radius := 100.0
@export var color := Color(1.0, 0.4, 0.1, 0.5)
@export var duration := 0.35

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
