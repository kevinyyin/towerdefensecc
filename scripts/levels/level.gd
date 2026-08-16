extends Node2D

const TILE_SOURCE_ID := 0
const GRASS_ATLAS_COORDS := Vector2i(16, 14)
const PATH_ATLAS_COORDS := Vector2i(2, 2)

# The undead tileset's native tile size is 16px, while gameplay cells (Grid.CELL_SIZE)
# are 64px, so each gameplay cell is painted as a 4x4 block of TileMapLayer cells.
const TILES_PER_CELL := 4

@export var grid_size := Vector2i(16, 9)
@export var path_cells: Array[Vector2i] = [
	Vector2i(0, 4),
	Vector2i(3, 4),
	Vector2i(3, 1),
	Vector2i(7, 1),
	Vector2i(7, 6),
	Vector2i(11, 6),
	Vector2i(11, 2),
	Vector2i(15, 2),
]

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

func _ready() -> void:
	add_to_group(&"level")
	_paint_grid()

func _paint_grid() -> void:
	for x in grid_size.x:
		for y in grid_size.y:
			_paint_cell(Vector2i(x, y), GRASS_ATLAS_COORDS)

	for cell in _all_path_cells():
		_paint_cell(cell, PATH_ATLAS_COORDS)

func _paint_cell(cell: Vector2i, atlas_coords: Vector2i) -> void:
	for sub_x in TILES_PER_CELL:
		for sub_y in TILES_PER_CELL:
			var sub_cell := cell * TILES_PER_CELL + Vector2i(sub_x, sub_y)
			tile_map_layer.set_cell(sub_cell, TILE_SOURCE_ID, atlas_coords)

# path_cells only marks the turns; this walks the straight runs between them
# so every tile the enemy actually crosses gets painted, not just the corners.
func _all_path_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i in path_cells.size() - 1:
		cells.append_array(_cells_between(path_cells[i], path_cells[i + 1]))
	cells.append(path_cells[-1])
	return cells

func _cells_between(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var step := Vector2i(sign(b.x - a.x), sign(b.y - a.y))
	var cell := a
	while cell != b:
		cells.append(cell)
		cell += step
	return cells

func get_world_path() -> Array[Vector2]:
	var world_path: Array[Vector2] = []
	for cell in path_cells:
		world_path.append(Grid.cell_to_world(cell))
	return world_path

func get_path_cells() -> Array[Vector2i]:
	return _all_path_cells()

func get_nearest_path_point(world_pos: Vector2) -> Vector2:
	var nearest := Grid.cell_to_world(path_cells[0])
	var nearest_dist := world_pos.distance_to(nearest)
	for cell in _all_path_cells():
		var point := Grid.cell_to_world(cell)
		var dist := world_pos.distance_to(point)
		if dist < nearest_dist:
			nearest = point
			nearest_dist = dist
	return nearest
