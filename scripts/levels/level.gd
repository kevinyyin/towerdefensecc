extends Node2D

const TILE_SOURCE_ID := 0
const GRASS_ATLAS_COORDS := Vector2i(0, 0)
const PATH_ATLAS_COORDS := Vector2i(1, 0)

@export var grid_size := Vector2i(12, 8)
@export var path_cells: Array[Vector2i] = [
	Vector2i(0, 4),
	Vector2i(6, 4),
	Vector2i(6, 1),
	Vector2i(11, 1),
]

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

func _ready() -> void:
	add_to_group(&"level")
	_paint_grid()

func _paint_grid() -> void:
	for x in grid_size.x:
		for y in grid_size.y:
			tile_map_layer.set_cell(Vector2i(x, y), TILE_SOURCE_ID, GRASS_ATLAS_COORDS)

	for cell in _all_path_cells():
		tile_map_layer.set_cell(cell, TILE_SOURCE_ID, PATH_ATLAS_COORDS)

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
