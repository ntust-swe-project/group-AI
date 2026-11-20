class_name Production
extends RefCounted

## Production facilities at work (feature 005, R5, R6). Pure logic.
##
## Deliberately a copy of Construction's build-job dispatch (the team chose
## duplication over refactoring feature 004; the ~40 duplicated lines are known
## technical debt). A production job is an Assignment with a facility id and
## `producing = true`, so like a build job it is never queued: pushed aside, it
## is dropped and handed out again. "Who produces what" is read straight from
## the colonists, so no job can outlive its facility (A7).

const DEFAULT_PRIORITY := 2  # Q3
const SECONDS_PER_UNIT := 0.1 * DayClock.SECONDS_PER_DAY  # Q3: one unit per 0.1 day of work

var _construction: Construction
var _board: AssignmentBoard
var _grid: StationGrid
var _stockpile: Stockpile


func _init(construction: Construction, board: AssignmentBoard, grid: StationGrid, stockpile: Stockpile) -> void:
	_construction = construction
	_board = board
	_grid = grid
	_stockpile = stockpile


## R5: gives each built, unpaused production facility without a producer one,
## most urgent facility first (smaller id on a tie). A colonist only takes a
## job more urgent than what they do now, and the one with the shortest walk
## goes first (whoever joined the colony first on a tie). Also lets go of any
## producer whose facility is gone, unbuilt or paused. Call every frame.
func assign_producers() -> void:
	_release_stale()
	var queue: Array[Facility] = _construction.facilities().filter(
		func(f: Facility) -> bool: return _is_production(f) and not f.paused)
	queue.sort_custom(func(a: Facility, b: Facility) -> bool:
		return a.production_priority > b.production_priority \
				or (a.production_priority == b.production_priority and a.id < b.id))
	for facility in queue:
		if producer_of(facility.id) != -1:
			continue
		var best := _nearest_free_colonist(facility)
		if not best.is_empty():
			_board.create_production(best.id, best.cell, facility.production_priority, facility.id)


## R5: adds `seconds` of game time of work from each producer standing at their
## work cell; every full `SECONDS_PER_UNIT` puts one unit in the stock. Time
## when nobody is there does not count; progress is kept when they leave.
func advance(seconds: float) -> void:
	if seconds <= 0.0:
		return
	var walkers := _board.walkers()
	for facility in _construction.facilities():
		if not _is_production(facility) or facility.paused:
			continue
		var colonist_id := producer_of(facility.id)
		if colonist_id == -1 or not walkers[colonist_id].is_working():
			continue
		facility.output_done += seconds
		while facility.output_done >= SECONDS_PER_UNIT:
			facility.output_done -= SECONDS_PER_UNIT
			_stockpile.add(FacilityCatalog.product_of(facility.kind), 1)


## The colonist whose current task is this facility's production job, or -1.
func producer_of(facility_id: int) -> int:
	var walkers := _board.walkers()
	for colonist_id in walkers:
		var task: Assignment = walkers[colonist_id].tasks.current
		if task and task.producing and task.facility_id == facility_id:
			return colonist_id
	return -1


## 0..1 of the way to the next unit; 0 for an unknown or non-production id.
func progress_of(facility_id: int) -> float:
	var facility := _construction.find(facility_id)
	if facility == null or not _is_production(facility):
		return 0.0
	return facility.output_done / SECONDS_PER_UNIT


## R6: changes a facility's production priority without swapping the producer,
## who puts the job down if something more urgent is waiting. False (no
## change) for an unknown, unbuilt or non-production id, or a priority outside 1-5.
func set_priority(facility_id: int, priority: int) -> bool:
	var facility := _construction.find(facility_id)
	if facility == null or not _is_production(facility):
		return false
	if priority < Assignment.MIN_PRIORITY or priority > Assignment.MAX_PRIORITY:
		return false
	facility.production_priority = priority
	var colonist_id := producer_of(facility_id)
	if colonist_id != -1:
		var walker: Wanderer = _board.walkers()[colonist_id]
		walker.tasks.current.priority = priority
		if walker.tasks.next_priority() > priority:
			walker.cancel(walker.tasks.current.id)
	return true


## R6: a paused facility's producer puts the job down at once and nobody takes
## it until it is resumed. False for an unknown, unbuilt or non-production id.
func set_paused(facility_id: int, paused: bool) -> bool:
	var facility := _construction.find(facility_id)
	if facility == null or not _is_production(facility):
		return false
	facility.paused = paused
	if paused:
		_release(facility_id)
	return true


## R8: the producer moves on first, then the facility is removed (A7).
func demolish(facility_id: int) -> bool:
	_release(facility_id)
	return _construction.demolish(facility_id)


## A built facility that makes something.
func _is_production(facility: Facility) -> bool:
	return facility.built and FacilityCatalog.product_of(facility.kind) != -1


func _release(facility_id: int) -> void:
	var colonist_id := producer_of(facility_id)
	if colonist_id != -1:
		var walker: Wanderer = _board.walkers()[colonist_id]
		walker.cancel(walker.tasks.current.id)


## Drops production jobs whose facility is gone, unbuilt or paused.
func _release_stale() -> void:
	var walkers := _board.walkers()
	for colonist_id in walkers:
		var walker: Wanderer = walkers[colonist_id]
		var task: Assignment = walker.tasks.current
		if task == null or not task.producing:
			continue
		var facility := _construction.find(task.facility_id)
		if facility == null or not _is_production(facility) or facility.paused:
			walker.cancel(task.id)


## {id, cell} of the colonist with the shortest walk to a cell beside the
## facility, among those doing something less urgent; empty if nobody.
func _nearest_free_colonist(facility: Facility) -> Dictionary:
	var spots := _work_cells(facility)
	var walkers := _board.walkers()
	var best := {}
	var best_steps := INF
	for colonist_id in walkers:
		var walker: Wanderer = walkers[colonist_id]
		if walker.tasks.current_priority() >= facility.production_priority:
			continue
		for spot in spots:
			var steps := _steps(walker.cell, spot)
			if steps < best_steps:
				best_steps = steps
				best = {"id": colonist_id, "cell": spot}
	return best


## Walkable cells sharing a side with the facility, not on any blueprint or
## facility, so finishing a blueprint never bumps the producer.
func _work_cells(facility: Facility) -> Array[Vector2i]:
	var spots: Array[Vector2i] = []
	for cell in facility.cells():
		for side in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var spot: Vector2i = cell + side
			if not spots.has(spot) and _grid.is_walkable(spot) and _construction.at(spot) == null:
				spots.append(spot)
	return spots


## Steps to walk from `from` to `to`, or INF if there is no way.
func _steps(from: Vector2i, to: Vector2i) -> float:
	if from == to:
		return 0.0
	var path := _grid.find_path(from, to)
	return INF if path.is_empty() else float(path.size() - 1)
