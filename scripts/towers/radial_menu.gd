extends Node2D

const TowerScript = preload("res://scripts/towers/tower.gd")
const RADIUS := 60.0

@onready var _tower: Node2D = get_parent()
@onready var _button_first: Button = $ButtonFirst
@onready var _button_last: Button = $ButtonLast
@onready var _button_strongest: Button = $ButtonStrongest
@onready var _button_sell: Button = $ButtonSell

var _buttons: Array[Button] = []

func _ready() -> void:
	_buttons = [_button_first, _button_last, _button_strongest, _button_sell]
	_layout_buttons()

	_button_first.pressed.connect(_set_mode.bind(TowerScript.TargetingMode.FIRST_IN_PATH))
	_button_last.pressed.connect(_set_mode.bind(TowerScript.TargetingMode.LAST_IN_PATH))
	_button_strongest.pressed.connect(_set_mode.bind(TowerScript.TargetingMode.STRONGEST))
	_button_sell.pressed.connect(_sell)

func _layout_buttons() -> void:
	for i in _buttons.size():
		var angle := TAU * i / _buttons.size()
		var button := _buttons[i]
		var offset := Vector2(RADIUS, 0).rotated(angle)
		button.position = offset - button.custom_minimum_size * 0.5

func refresh_active_mode() -> void:
	_button_first.disabled = _tower.targeting_mode == TowerScript.TargetingMode.FIRST_IN_PATH
	_button_last.disabled = _tower.targeting_mode == TowerScript.TargetingMode.LAST_IN_PATH
	_button_strongest.disabled = _tower.targeting_mode == TowerScript.TargetingMode.STRONGEST

func _set_mode(mode: TowerScript.TargetingMode) -> void:
	_tower.targeting_mode = mode
	refresh_active_mode()

func _sell() -> void:
	GameManager.add_gold(int(_tower.cost * 0.5))
	_tower.queue_free()
