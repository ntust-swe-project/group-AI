class_name Construction
extends RefCounted

## Every blueprint and built facility on the station (feature 004).
## Pure logic (SYSTEM.md S1).
##
## Each blueprint is one build job in a shared pool (R5). The job is never put
## in anyone's queue: a colonist only ever holds it as the task they are doing
## now. So "who builds what" is read straight from the colonists, and nothing
## can be left behind pointing at a blueprint that is gone (A8).

const DEFAULT_PRIORITY := 3  # Q4
const MAX_BUILDERS := 2

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


## Removes a blueprint at once (I6), and its builders move on to their next
## task in this same call. False if no blueprint has that id.
func cancel(facility_id: int) -> bool:
	var blueprint := find(facility_id)
	if blueprint == null or blueprint.built:
		return false
	_release_builders(facility_id)
	_all.erase(blueprint)
	return true


## The blueprint or facility with that id, or null.
func find(facility_id: int) -> Facility:
	for facility in _all:
		if facility.id == facility_id:
			return facility
	return null


func priority_of(facility_id: int) -> int:
	var blueprint := find(facility_id)
	return blueprint.priority if blueprint else 0


## R4: changes a blueprint's priority without swapping builders. A builder
## with something more urgent waiting puts the build down for it. False (and
## no change) for an unknown id, a built facility, or a priority outside 1-5.
func set_priority(facility_id: int, priority: int) -> bool:
	var blueprint := find(facility_id)
	if blueprint == null or blueprint.built:
		return false
	if priority < Assignment.MIN_PRIORITY or priority > Assignment.MAX_PRIORITY:
		return false
	blueprint.priority = priority
	var walkers := _board.walkers()
	for colonist_id in builders_of(facility_id):
		var walker: Wanderer = walkers[colonist_id]
		walker.tasks.current.priority = priority
		if walker.tasks.next_priority() > priority:
			walker.cancel(walker.tasks.current.id)
	return true


## Ids of the colonists building this blueprint now, in the order they took it.
func builders_of(facility_id: int) -> Array[int]:
	var walkers := _board.walkers()
	var ids: Array[int] = []
	for colonist_id in walkers:
		var task: Assignment = walkers[colonist_id].tasks.current
		if task and task.facility_id == facility_id:
			ids.append(colonist_id)
	ids.sort_custom(func(a: int, b: int) -> bool:
		return walkers[a].tasks.current.id < walkers[b].tasks.current.id)
	return ids


## R5: fills each blueprint up to two builders, most urgent blueprint first
## (oldest first on a tie). A colonist only takes a job more urgent than what
## they do now, and the one with the shortest walk goes first (whoever joined
## the colony first on a tie). Call every frame.
func assign_builders() -> void:
	var queue := blueprints()
	queue.sort_custom(func(a: Facility, b: Facility) -> bool:
		return a.priority > b.priority or (a.priority == b.priority and a.id < b.id))
	for blueprint in queue:
		while builders_of(blueprint.id).size() < MAX_BUILDERS:
			var best := _nearest_free_colonist(blueprint)
			if best.is_empty():
				break
			_board.create_build(best.id, best.cell, blueprint.priority, blueprint.id)


## {id, cell} of the colonist with the shortest walk to a cell beside the
## blueprint, among those doing something less urgent; empty if nobody.
func _nearest_free_colonist(blueprint: Facility) -> Dictionary:
	var spots := _work_cells(blueprint)
	var walkers := _board.walkers()
	var best := {}
	var best_steps := INF
	for colonist_id in walkers:
		var walker: Wanderer = walkers[colonist_id]
		if walker.tasks.current_priority() >= blueprint.priority:
			continue
		for spot in spots:
			var steps := _steps(walker.cell, spot)
			if steps < best_steps:
				best_steps = steps
				best = {"id": colonist_id, "cell": spot}
	return best


## Walkable cells sharing a side with the blueprint, outside it (I3).
func _work_cells(blueprint: Facility) -> Array[Vector2i]:
	var covered := blueprint.cells()
	var spots: Array[Vector2i] = []
	for cell in covered:
		for side in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var spot: Vector2i = cell + side
			if not covered.has(spot) and not spots.has(spot) and _grid.is_walkable(spot):
				spots.append(spot)
	return spots


## Steps to walk from `from` to `to`, or INF if there is no way.
func _steps(from: Vector2i, to: Vector2i) -> float:
	if from == to:
		return 0.0
	var path := _grid.find_path(from, to)
	return INF if path.is_empty() else float(path.size() - 1)


## Everyone building this blueprint stops and moves on to their next task.
func _release_builders(facility_id: int) -> void:
	var walkers := _board.walkers()
	for colonist_id in builders_of(facility_id):
		var walker: Wanderer = walkers[colonist_id]
		walker.cancel(walker.tasks.current.id)


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
