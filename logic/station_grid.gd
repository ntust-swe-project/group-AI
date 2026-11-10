class_name StationGrid
extends RefCounted

## The station as a grid of floor and wall cells, with pathfinding.
## Pure logic (SYSTEM.md S1); the scene decides how big a cell is on screen.

## Hall size in cells, outer wall included (Q4). With 32 px cells this is
## 1536 x 864 px, about 64% of a 1920 x 1080 screen. Tune once it is on screen.
const DEFAULT_HALL_SIZE := Vector2i(48, 27)

var size: Vector2i

var _astar := AStarGrid2D.new()


func _init(grid_size: Vector2i) -> void:
	size = grid_size
	_astar.region = Rect2i(Vector2i.ZERO, size)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.update()


## One open hall surrounded by wall (feature 001, R3).
static func make_hall(grid_size: Vector2i = DEFAULT_HALL_SIZE) -> StationGrid:
	var grid := StationGrid.new(grid_size)
	for x in grid_size.x:
		grid.set_wall(Vector2i(x, 0))
		grid.set_wall(Vector2i(x, grid_size.y - 1))
	for y in grid_size.y:
		grid.set_wall(Vector2i(0, y))
		grid.set_wall(Vector2i(grid_size.x - 1, y))
	return grid


func set_wall(cell: Vector2i, is_wall_cell: bool = true) -> void:
	_astar.set_point_solid(cell, is_wall_cell)


## Cells outside the grid count as wall.
func is_wall(cell: Vector2i) -> bool:
	return not _astar.is_in_boundsv(cell) or _astar.is_point_solid(cell)


func is_floor(cell: Vector2i) -> bool:
	return _astar.is_in_boundsv(cell) and not _astar.is_point_solid(cell)


func floor_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in size.x:
		for y in size.y:
			if is_floor(Vector2i(x, y)):
				cells.append(Vector2i(x, y))
	return cells


## Cells from `from` to `to`, both included, moving one cell up, down, left or
## right per step. Empty when either end is not floor or `to` is unreachable.
func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if not is_floor(from) or not is_floor(to):
		return []
	return _astar.get_id_path(from, to)
