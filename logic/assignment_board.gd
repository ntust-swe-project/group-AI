class_name AssignmentBoard
extends RefCounted

## Every assignment on the station (feature 002). Hands out ids, checks an
## assignment can be done before creating it (R6), and finds it again to
## cancel (R7). The assignments themselves live in each colonist's TaskQueue,
## so finished ones disappear from here without bookkeeping. Pure logic.

var _grid: StationGrid
var _walkers := {}  # colonist id -> Wanderer
var _next_id := 1


func _init(grid: StationGrid) -> void:
	_grid = grid


func register(colonist_id: int, walker: Wanderer) -> void:
	_walkers[colonist_id] = walker


## The colonist can no longer be given assignments or listed in the menu:
## incapacitated or dead (feature 003, R8). Their tasks must be cancelled first.
func unregister(colonist_id: int) -> void:
	_walkers.erase(colonist_id)


## True when `cell` is floor that at least one colonist can walk to: the only
## cells the assignment menu opens on.
func can_assign_at(cell: Vector2i) -> bool:
	return not who_can_reach(cell).is_empty()


## Ids of the colonists who can walk to `cell`, in the order they joined.
func who_can_reach(cell: Vector2i) -> Array[int]:
	var ids: Array[int] = []
	for colonist_id in _walkers:
		if _can_reach(_walkers[colonist_id], cell):
			ids.append(colonist_id)
	return ids


## Gives colonist `colonist_id` a new assignment at `cell`. Returns null and
## changes nothing if the colonist is unknown, the priority is outside 1-5, or
## the colonist cannot walk to `cell`. A player's order leaves `need` empty;
## supply work names the need it refills and its work time (feature 003).
func create(colonist_id: int, cell: Vector2i, priority: int, need: StringName = &"",
		work_seconds: float = Assignment.DEFAULT_WORK_SECONDS) -> Assignment:
	var walker: Wanderer = _walkers.get(colonist_id)
	if walker == null:
		return null
	if priority < Assignment.MIN_PRIORITY or priority > Assignment.MAX_PRIORITY:
		return null
	if not _can_reach(walker, cell):
		return null
	var task := Assignment.new(_next_id, cell, priority, need, work_seconds)
	_next_id += 1
	walker.assign(task)
	return task


## Gives colonist `colonist_id` a build job for blueprint `facility_id`,
## standing at `cell`. Only when it is more urgent than what they do now, so it
## becomes their current task at once (feature 004, R5); otherwise null.
## Construction has already checked that they can walk to `cell`.
func create_build(colonist_id: int, cell: Vector2i, priority: int, facility_id: int) -> Assignment:
	var walker: Wanderer = _walkers.get(colonist_id)
	if walker == null or priority <= walker.tasks.current_priority():
		return null
	var task := Assignment.new(_next_id, cell, priority)
	task.facility_id = facility_id
	_next_id += 1
	walker.assign(task)
	return task


## Colonist id -> Wanderer for everyone registered, in the order they joined. A copy.
func walkers() -> Dictionary:
	return _walkers.duplicate()


## Returns false if no colonist has an assignment with that id.
func cancel(assignment_id: int) -> bool:
	var colonist_id := owner_of(assignment_id)
	if colonist_id == -1:
		return false
	_walkers[colonist_id].cancel(assignment_id)
	return true


## The colonist id holding this assignment, or -1.
func owner_of(assignment_id: int) -> int:
	for colonist_id in _walkers:
		for task in _all_tasks(_walkers[colonist_id]):
			if task.id == assignment_id:
				return colonist_id
	return -1


## Every assignment at `cell`, being done or waiting, for any colonist.
func at(cell: Vector2i) -> Array[Assignment]:
	var found: Array[Assignment] = []
	for walker in _walkers.values():
		for task in _all_tasks(walker):
			if task.cell == cell:
				found.append(task)
	return found


func _all_tasks(walker: Wanderer) -> Array[Assignment]:
	var tasks := walker.tasks.queued()
	if walker.tasks.current:
		tasks.push_front(walker.tasks.current)
	return tasks


func _can_reach(walker: Wanderer, cell: Vector2i) -> bool:
	return _grid.is_floor(cell) and (walker.cell == cell or not _grid.find_path(walker.cell, cell).is_empty())
