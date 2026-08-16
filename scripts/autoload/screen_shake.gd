extends Node

@export var decay := 5.0
@export var max_offset := 24.0

var _trauma := 0.0
var _camera: Camera2D = null
var _rng := RandomNumberGenerator.new()

func register_camera(camera: Camera2D) -> void:
	_camera = camera

func shake(amount: float) -> void:
	_trauma = max(_trauma, clamp(amount, 0.0, 1.0))

func _process(delta: float) -> void:
	if _trauma > 0.0:
		_trauma = max(_trauma - decay * delta, 0.0)

	if _camera == null:
		return

	if _trauma > 0.0:
		var power := _trauma * _trauma
		_camera.offset = Vector2(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0)
		) * max_offset * power
	else:
		_camera.offset = Vector2.ZERO
