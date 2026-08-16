extends Area2D

const TOWER_SCENES: Array[PackedScene] = [
	preload("res://scenes/towers/archer.tscn"),
	preload("res://scenes/towers/mage.tscn"),
	preload("res://scenes/towers/artillery.tscn"),
	preload("res://scenes/towers/barracks.tscn"),
]

@onready var _menu: Control = $Menu
@onready var _buttons: Array[Button] = [
	$Menu/Panel/Buttons/ButtonArcher,
	$Menu/Panel/Buttons/ButtonMage,
	$Menu/Panel/Buttons/ButtonArtillery,
	$Menu/Panel/Buttons/ButtonBarracks,
]

var _tower_costs: Array[int] = []

func _ready() -> void:
	add_to_group(&"build_pads")
	input_pickable = true
	get_viewport().physics_object_picking = true
	input_event.connect(_on_input_event)

	for i in TOWER_SCENES.size():
		var scene := TOWER_SCENES[i]
		var probe := scene.instantiate()
		var button := _buttons[i]
		button.text = "%s\n%d g" % [probe.display_name, probe.cost]
		_tower_costs.append(probe.cost)
		probe.free()
		button.pressed.connect(_on_tower_button_pressed.bind(i))

	GameManager.gold_changed.connect(_update_button_states)
	_update_button_states(GameManager.gold)

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
