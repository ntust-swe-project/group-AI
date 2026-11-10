class_name StationGrid
extends RefCounted

## The station as a grid of cells, with pathfinding. Pure logic (SYSTEM.md S1);
## the scene decides how big a cell is on screen.
##
## A new grid is all space. Rooms (rectangles, ellipses) and corridors are laid
## on top as floor, and every space cell touching a floor cell, sideways or
## diagonally, becomes wall. More rooms can be added later (feature 001, R3).
## Keep rooms at least one cell inside the grid: there is no wall beyond the
## edge, so floor on the edge would touch space directly.

enum Cell { SPACE, WALL, FLOOR }

## Hall size in cells, outer wall included (Q4, A7). With 32 px cells the
## elliptical floor covers about 60% of a 1920 x 1080 screen.
const DEFAULT_HALL_SIZE := Vector2i(56, 31)

const _NEIGHBOURS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]

var size: Vector2i

var _cells: PackedByteArray
var _astar := AStarGrid2D.new()


func _init(grid_size: Vector2i) -> void:
	size = grid_size
	_cells.resize(size.x * size.y)
	_cells.fill(Cell.SPACE)
	_astar.region = Rect2i(Vector2i.ZERO, size)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.update()
	_astar.fill_solid_region(_astar.region, true)


## One elliptical hall filling the grid inside a one-cell margin for its wall.
static func make_hall(grid_size: Vector2i = DEFAULT_HALL_SIZE) -> StationGrid:
	var grid := StationGrid.new(grid_size)
	grid.add_room_ellipse(Rect2i(Vector2i.ONE, grid_size - Vector2i(2, 2)))
	return grid


## Every cell in `rect` becomes floor. Also use it for corridors.
func add_room_rect(rect: Rect2i) -> void:
	var cells: Array[Vector2i] = []
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			cells.append(Vector2i(x, y))
	_add_floor(cells)


## Every cell whose centre lies inside the ellipse inscribed in `rect` becomes floor.
func add_room_ellipse(rect: Rect2i) -> void:
	var centre := Vector2(rect.position) + Vector2(rect.size) / 2.0
	var radius := Vector2(rect.size) / 2.0
	var cells: Array[Vector2i] = []
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var d := (Vector2(x, y) + Vector2(0.5, 0.5) - centre) / radius
			if d.length_squared() <= 1.0:
				cells.append(Vector2i(x, y))
	_add_floor(cells)


func set_wall(cell: Vector2i) -> void:
	_set_kind(cell, Cell.WALL)


func kind_of(cell: Vector2i) -> Cell:
	if not _in_bounds(cell):
		return Cell.SPACE
	return _cells[_index(cell)] as Cell


func is_wall(cell: Vector2i) -> bool:
	return kind_of(cell) == Cell.WALL


func is_floor(cell: Vector2i) -> bool:
	return kind_of(cell) == Cell.FLOOR


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


func _add_floor(cells: Array[Vector2i]) -> void:
	for cell in cells:
		if _in_bounds(cell):
			_set_kind(cell, Cell.FLOOR)
	for cell in cells:
		for d in _NEIGHBOURS:
			var next := cell + d
			if _in_bounds(next) and kind_of(next) == Cell.SPACE:
				_set_kind(next, Cell.WALL)


func _set_kind(cell: Vector2i, kind: Cell) -> void:
	_cells[_index(cell)] = kind
	_astar.set_point_solid(cell, kind != Cell.FLOOR)


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func _index(cell: Vector2i) -> int:
	return cell.y * size.x + cell.x
