extends CanvasLayer

@onready var _stars_label: Label = $CenterContainer/VBox/StarsLabel
@onready var _continue_button: Button = $CenterContainer/VBox/ContinueButton

func _ready() -> void:
	_stars_label.text = "You earned %d star(s)!\nTotal stars: %d" % [Upgrades.last_stars_earned, Upgrades.stars]
	_continue_button.pressed.connect(_on_continue_pressed)

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
