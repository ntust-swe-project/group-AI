class_name Construction
extends RefCounted

## Every blueprint and built facility on the station (feature 004).
## Pure logic (SYSTEM.md S1).

var _grid: StationGrid
var _board: AssignmentBoard
var _all: Array[Facility] = []  # in placing order
var _next_id := 1


func _init(grid: StationGrid, board: AssignmentBoard) -> void:
	_grid = grid
	_board = board


## The cells a facility of `kind` would cover with its top-left at `origin`.
static func cells_for(kind: FacilityCatalog.Kind, origin: Vector2i) -> Array[Vector2i]:
	var size := FacilityCatalog.size_of(kind)
	var cells: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			cells.append(origin + Vector2i(x, y))
	return cells


## R3: every cell is walkable floor with no blueprint, facility or assignment
## on it, and blocking them together with the other blueprints would not cut
## the station in two.
func can_place(kind: FacilityCatalog.Kind, origin: Vector2i) -> bool:
	var cells := cells_for(kind, origin)
	for cell in cells:
		if not _grid.is_walkable(cell) or at(cell) != null or not _board.at(cell).is_empty():
			return false
	for blueprint in blueprints():
		cells.append_array(blueprint.cells())
	return not _grid.would_split(cells)


## A new blueprint, or null (changing nothing) where `can_place` is false.
func place(kind: FacilityCatalog.Kind, origin: Vector2i) -> Facility:
	if not can_place(kind, origin):
		return null
	var facility := Facility.new(_next_id, kind, origin)
	_next_id += 1
	_all.append(facility)
	return facility


## Removes a blueprint at once (I6). False if no blueprint has that id.
func cancel(facility_id: int) -> bool:
	for facility in blueprints():
		if facility.id == facility_id:
			_all.erase(facility)
			return true
	return false


## The blueprint or facility covering `cell`, or null.
func at(cell: Vector2i) -> Facility:
	for facility in _all:
		if facility.cells().has(cell):
			return facility
	return null


func blueprints() -> Array[Facility]:
	return _all.filter(func(f: Facility) -> bool: return not f.built)


func facilities() -> Array[Facility]:
	return _all.filter(func(f: Facility) -> bool: return f.built)
