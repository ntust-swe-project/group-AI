class_name Wanderer
extends RefCounted

## Walks a colonist around the station: pick a random floor cell, follow the
## path there one cell at a time, repeat (feature 001, I1). Pure logic.

## Walking speed in cells per game second. Placeholder until seen on screen.
const CELLS_PER_SECOND := 2.0

var cell: Vector2i

var _grid: StationGrid
var _rng: RandomNumberGenerator
var _path: Array[Vector2i] = []  # cells still to step into, next one first
var _progress := 0.0  # 0..1 of the way from `cell` to `_path[0]`


func _init(grid: StationGrid, start_cell: Vector2i, rng: RandomNumberGenerator = RandomNumberGenerator.new()) -> void:
	_grid = grid
	cell = start_cell
	_rng = rng


func advance(seconds: float) -> void:
	var remaining := seconds * CELLS_PER_SECOND
	while remaining > 0.0:
		if _path.is_empty():
			_pick_new_destination()
			if _path.is_empty():
				return
		var step := minf(remaining, 1.0 - _progress)
		_progress += step
		remaining -= step
		if _progress >= 1.0:
			cell = _path.pop_front()
			_progress = 0.0


## Position in cells, between two cells while walking.
func position() -> Vector2:
	if _path.is_empty():
		return Vector2(cell)
	return Vector2(cell).lerp(Vector2(_path[0]), _progress)


func _pick_new_destination() -> void:
	var candidates := _grid.floor_cells()
	candidates.erase(cell)
	if candidates.is_empty():
		return
	var target := candidates[_rng.randi_range(0, candidates.size() - 1)]
	_path = _grid.find_path(cell, target)
	if not _path.is_empty():
		_path.pop_front()  # the first cell is where we already stand
