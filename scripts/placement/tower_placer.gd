extends Node2D

@onready var _level: Node = get_parent()
@onready var _towers_container: Node2D = _level.get_node("TowersContainer")

var _armed_scene: PackedScene = null
var _is_armed := false
var _range_radius := 0.0
var _cost := 0

var _path_cells: Dictionary = {}
var _occupied_cells: Dictionary = {}

var _hover_cell := Vector2i.ZERO

func _ready() -> void:
	add_to_group(&"tower_placer")

	for cell in _level.get_path_cells():
		_path_cells[cell] = true

	for tower in _towers_container.get_children():
		_register_tower(tower)

func arm(scene: PackedScene) -> void:
	_armed_scene = scene
	var probe := scene.instantiate()
	_range_radius = probe.range_radius
	_cost = probe.cost
	probe.free()

	_is_armed = true
	_hover_cell = Grid.world_to_cell(get_global_mouse_position())
	global_position = Grid.cell_to_world(_hover_cell)
	queue_redraw()

func disarm() -> void:
	_is_armed = false
	_armed_scene = null
	queue_redraw()

func _process(_delta: float) -> void:
	if not _is_armed:
		return
	_hover_cell = Grid.world_to_cell(get_global_mouse_position())
	global_position = Grid.cell_to_world(_hover_cell)
	queue_redraw()

func _draw() -> void:
	if not _is_armed:
		return
	var valid := _is_valid_placement(_hover_cell)
	var fill_color := Color(0.2, 0.9, 0.3, 0.18) if valid else Color(0.9, 0.2, 0.2, 0.18)
	var outline_color := Color(0.2, 0.9, 0.3, 0.6) if valid else Color(0.9, 0.2, 0.2, 0.6)
	var body_color := Color(0.2, 0.35, 0.85, 0.4) if valid else Color(0.6, 0.2, 0.2, 0.4)

	draw_circle(Vector2.ZERO, _range_radius, fill_color)
	draw_arc(Vector2.ZERO, _range_radius, 0.0, TAU, 48, outline_color, 2.0)
	draw_rect(Rect2(Vector2(-16, -16), Vector2(32, 32)), body_color, true)

func _unhandled_input(event: InputEvent) -> void:
	if not _is_armed:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place_tower()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			disarm()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		disarm()

func _try_place_tower() -> void:
	if not _is_valid_placement(_hover_cell):
		return
	if not GameManager.spend_gold(_cost):
		return

	var tower := _armed_scene.instantiate()
	_towers_container.add_child(tower)
	tower.global_position = Grid.cell_to_world(_hover_cell)
	_register_tower(tower)
	disarm()

func _register_tower(tower: Node2D) -> void:
	var cell := Grid.world_to_cell(tower.global_position)
	_occupied_cells[cell] = tower
	tower.tree_exited.connect(func(): _occupied_cells.erase(cell))

func _is_valid_placement(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= _level.grid_size.x or cell.y >= _level.grid_size.y:
		return false
	if _path_cells.has(cell):
		return false
	if _occupied_cells.has(cell):
		return false
	if GameManager.gold < _cost:
		return false
	return true
