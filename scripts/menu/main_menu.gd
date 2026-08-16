extends CanvasLayer

@onready var _start_button: Button = $CenterContainer/VBox/StartButton
@onready var _upgrades_button: Button = $CenterContainer/VBox/UpgradesButton
@onready var _settings_button: Button = $CenterContainer/VBox/SettingsButton

func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_upgrades_button.pressed.connect(_on_upgrades_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)

func _on_start_pressed() -> void:
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_upgrades_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/upgrades_menu.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/settings_menu.tscn")
