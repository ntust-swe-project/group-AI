class_name Wanderer
extends RefCounted

## Moves one colonist. With nothing to do it wanders: pick a random floor cell,
## walk there, repeat (feature 001, I1). With assignments it walks to the
## current one and works there (feature 002). Pure logic; time is game time.

## Walking speed in cells per game second. Placeholder until seen on screen.
const CELLS_PER_SECOND := 2.0
## Game seconds of work for a player's assignment (002 Q5, I6). Each assignment
## carries its own work time (feature 003); this is the default it starts with.
const WORK_SECONDS := Assignment.DEFAULT_WORK_SECONDS

## The cell the current step starts from (where it stands when not walking).
## Use position() for where the colonist is drawn.
var cell: Vector2i
var tasks := TaskQueue.new()

var _grid: StationGrid
var _rng: RandomNumberGenerator
var _path: Array[Vector2i] = []  # cells still to step into, next one first
var _progress := 0.0  # 0..1 of the way from `cell` to `_path[0]`
var _worked := 0.0  # seconds of work done on the current assignment


func _init(grid: StationGrid, start_cell: Vector2i, rng: RandomNumberGenerator = RandomNumberGenerator.new()) -> void:
	_grid = grid
	cell = start_cell
	_rng = rng


## Adds an assignment. If it is more urgent than what is being done, the
## route changes in this same call (SC4), not on the next frame.
func assign(task: Assignment) -> void:
	if tasks.add(task):
		_start_current()


func cancel(task_id: int) -> void:
	if tasks.cancel(task_id):
		_start_current()


## Returns the assignments finished during this call, so the caller can tell a
## finished one from a cancelled one (feature 003: only finished supply work
## refills a need).
func advance(seconds: float) -> Array[Assignment]:
	var done: Array[Assignment] = []
	var time_left := seconds
	while time_left > 0.0:
		var task := tasks.current
		if task and _path.is_empty():
			if cell != task.cell:
				# Cannot get there (the map changed). Drop it rather than stand still.
				tasks.cancel(task.id)
				_start_current()
				continue
			var used := minf(time_left, task.work_seconds - _worked)
			_worked += used
			time_left -= used
			if _worked >= task.work_seconds:
				done.append(task)
				tasks.complete()
				_start_current()
			continue
		if _path.is_empty():
			_pick_new_destination()
			if _path.is_empty():
				return done
		var step := minf(time_left * CELLS_PER_SECOND, 1.0 - _progress)
		_progress += step
		time_left -= step / CELLS_PER_SECOND
		if _progress >= 1.0:
			cell = _path.pop_front()
			_progress = 0.0
	return done


## Position in cells, between two cells while walking.
func position() -> Vector2:
	if _path.is_empty():
		return Vector2(cell)
	return Vector2(cell).lerp(Vector2(_path[0]), _progress)


## The cell the current route ends at (where it stands if not walking).
func destination() -> Vector2i:
	return _path.back() if not _path.is_empty() else cell


## Cells left to walk on the current route.
func remaining_steps() -> float:
	return _path.size() - _progress if not _path.is_empty() else 0.0


func _start_current() -> void:
	_worked = 0.0
	if tasks.current:
		_route_to(tasks.current.cell)
	elif _progress > 0.0:
		_path = [_path[0]]  # finish the step in progress, then wander
	else:
		_path = []


## Route to `target` without jumping. Mid-step, either finish the step or turn
## back, whichever leaves less to walk, so the next advance always gets closer.
func _route_to(target: Vector2i) -> void:
	if _path.is_empty() or _progress == 0.0:
		_path = _steps_from(cell, target)
		_progress = 0.0
		return
	var next := _path[0]
	var forward := _steps_from(next, target)
	var back := _steps_from(cell, target)
	var forward_cost := (1.0 - _progress) + forward.size()
	var back_cost := _progress + back.size()
	var forward_ok := next == target or not forward.is_empty()
	var back_ok := cell == target or not back.is_empty()
	if forward_ok and (not back_ok or forward_cost <= back_cost):
		_path = [next] as Array[Vector2i]
		_path.append_array(forward)
	elif back_ok:
		var leaving := cell
		cell = next
		_path = [leaving] as Array[Vector2i]
		_path.append_array(back)
		_progress = 1.0 - _progress
	else:
		# Unreachable from both ends: finish the step; advance() then drops the task.
		_path = [next] as Array[Vector2i]


## Cells to step into from `from` to `to`, not counting `from`.
func _steps_from(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var path := _grid.find_path(from, to)
	if not path.is_empty():
		path.pop_front()
	return path


func _pick_new_destination() -> void:
	var candidates := _grid.floor_cells()
	candidates.erase(cell)
	if candidates.is_empty():
		return
	var target := candidates[_rng.randi_range(0, candidates.size() - 1)]
	_path = _steps_from(cell, target)
