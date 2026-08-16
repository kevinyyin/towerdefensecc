extends Area2D

const TOWER_SCENES: Array[PackedScene] = [
	preload("res://scenes/towers/archer.tscn"),
	preload("res://scenes/towers/mage.tscn"),
	preload("res://scenes/towers/artillery.tscn"),
	preload("res://scenes/towers/barracks.tscn"),
]

const RADIUS := 80.0

@onready var _menu: Node2D = $Menu
@onready var _buttons: Array[Button] = [
	$Menu/ButtonArcher,
	$Menu/ButtonMage,
	$Menu/ButtonArtillery,
	$Menu/ButtonBarracks,
]

var _tower_costs: Array[int] = []

func _ready() -> void:
	add_to_group(&"build_pads")
	input_pickable = true
	get_viewport().physics_object_picking = true
	input_event.connect(_on_input_event)

	_layout_buttons()

	for i in TOWER_SCENES.size():
		var scene := TOWER_SCENES[i]
		var probe := scene.instantiate()
		var button := _buttons[i]
		button.text = "%s\n%d g" % [probe.display_name, probe.cost]
		_style_button(button, probe.get_node("Visual").color)
		_tower_costs.append(probe.cost)
		probe.free()
		button.pressed.connect(_on_tower_button_pressed.bind(i))

	GameManager.gold_changed.connect(_update_button_states)
	_update_button_states(GameManager.gold)

func _layout_buttons() -> void:
	for i in _buttons.size():
		var angle := TAU * i / _buttons.size()
		var button := _buttons[i]
		var offset := Vector2(RADIUS, 0).rotated(angle)
		button.position = offset - button.custom_minimum_size * 0.5

func _style_button(button: Button, color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var opening := not _menu.visible
		_close_other_pads()
		_menu.visible = opening

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_menu()

func close_menu() -> void:
	_menu.visible = false

func _close_other_pads() -> void:
	for pad in get_tree().get_nodes_in_group(&"build_pads"):
		if pad != self:
			pad.close_menu()

func _on_tower_button_pressed(index: int) -> void:
	if not GameManager.spend_gold(_tower_costs[index]):
		return

	var towers_container := get_tree().get_first_node_in_group(&"level").get_node("TowersContainer")
	var tower := TOWER_SCENES[index].instantiate()
	towers_container.add_child(tower)
	tower.global_position = global_position

	close_menu()
	visible = false
	input_pickable = false

func _update_button_states(new_gold: int) -> void:
	for i in _buttons.size():
		var affordable := new_gold >= _tower_costs[i]
		_buttons[i].disabled = not affordable
		_buttons[i].modulate.a = 1.0 if affordable else 0.4
