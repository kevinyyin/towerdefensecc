extends Camera2D

func _ready() -> void:
	ScreenShake.register_camera(self)
