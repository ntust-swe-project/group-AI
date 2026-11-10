class_name TaskQueue
extends RefCounted

## One colonist's to-do list (feature 002, R3, R4). The current task is the
## one being done; the rest wait, most urgent first, then oldest first.

## The task being done, or null while idling.
var current: Assignment = null

var _waiting: Array[Assignment] = []


func current_priority() -> int:
	return current.priority if current else 0


## Returns true when `current` changed: the new task is more urgent than what
## is being done, so it takes over now and the old one goes back in line.
## Adding a task already here (same id) does nothing.
func add(task: Assignment) -> bool:
	if _has(task.id):
		return false
	if task.priority > current_priority():
		if current:
			_wait(current)
		current = task
		return true
	_wait(task)
	return false


## The current task is done; start the next one (or idle).
func complete() -> void:
	current = _next()


## Returns true when `current` changed.
func cancel(task_id: int) -> bool:
	if current and current.id == task_id:
		current = _next()
		return true
	for i in _waiting.size():
		if _waiting[i].id == task_id:
			_waiting.remove_at(i)
			break
	return false


## Waiting tasks in the order they will be done. A copy.
func queued() -> Array[Assignment]:
	return _waiting.duplicate()


func _has(task_id: int) -> bool:
	if current and current.id == task_id:
		return true
	return _waiting.any(func(t): return t.id == task_id)


func _wait(task: Assignment) -> void:
	var i := 0
	while i < _waiting.size() and _comes_before(_waiting[i], task):
		i += 1
	_waiting.insert(i, task)


func _comes_before(a: Assignment, b: Assignment) -> bool:
	return a.priority > b.priority or (a.priority == b.priority and a.id < b.id)


func _next() -> Assignment:
	return _waiting.pop_front() if not _waiting.is_empty() else null
