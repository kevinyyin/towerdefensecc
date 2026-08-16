extends CanvasLayer

@onready var _fullscreen_check: CheckButton = $CenterContainer/VBox/FullscreenCheck
@onready var _back_button: Button = $CenterContainer/VBox/BackButton

func _ready() -> void:
	_fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_back_button.pressed.connect(_on_back_pressed)

func _on_fullscreen_toggled(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
