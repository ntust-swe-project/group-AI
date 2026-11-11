extends GutTest

# A2, A3, A5, A6 of docs/specs/features/002-assignment.md

var queue: TaskQueue
var _next_id := 1


func before_each():
	queue = TaskQueue.new()
	_next_id = 1


## A new assignment; ids grow in creation order.
func _task(priority: int) -> Assignment:
	var task := Assignment.new(_next_id, Vector2i(_next_id, 0), priority)
	_next_id += 1
	return task


func _ids(tasks: Array[Assignment]) -> Array[int]:
	var ids: Array[int] = []
	for task in tasks:
		ids.append(task.id)
	return ids


func test_empty_queue_is_idle_at_priority_zero():
	assert_null(queue.current)
	assert_eq(queue.current_priority(), 0)
	assert_eq(queue.queued().size(), 0)


func test_first_assignment_takes_over_idling():
	var a := _task(1)
	assert_true(queue.add(a), "current changed")
	assert_same(queue.current, a)


# A2
func test_equal_priority_waits_in_line():
	var a := _task(3)
	queue.add(a)
	var b := _task(3)
	assert_false(queue.add(b), "no takeover")
	assert_same(queue.current, a)
	assert_eq(_ids(queue.queued()), [b.id] as Array[int])


func test_lower_priority_waits_in_line():
	var a := _task(4)
	queue.add(a)
	assert_false(queue.add(_task(2)))
	assert_same(queue.current, a)


# A5
func test_more_urgent_takes_over_and_the_old_one_waits():
	var a := _task(2)
	queue.add(a)
	var b := _task(5)
	assert_true(queue.add(b))
	assert_same(queue.current, b)
	assert_eq(_ids(queue.queued()), [a.id] as Array[int])


func test_interrupted_task_goes_ahead_of_newer_ones_at_its_priority():
	var a := _task(3)
	queue.add(a)
	var b := _task(3)
	queue.add(b)
	queue.add(_task(5))
	assert_eq(_ids(queue.queued()), [a.id, b.id] as Array[int])


# A3
func test_queue_is_most_urgent_first_then_oldest_first():
	queue.add(_task(5))  # id 1, current
	var low := _task(2)
	var mid_old := _task(3)
	var high := _task(4)
	var mid_new := _task(3)
	for t in [low, mid_old, high, mid_new]:
		queue.add(t)
	assert_eq(_ids(queue.queued()), [high.id, mid_old.id, mid_new.id, low.id] as Array[int])


func test_completing_starts_the_next_most_urgent():
	queue.add(_task(5))
	var low := _task(1)
	var high := _task(4)
	queue.add(low)
	queue.add(high)
	queue.complete()
	assert_same(queue.current, high)
	queue.complete()
	assert_same(queue.current, low)
	queue.complete()
	assert_null(queue.current)
	assert_eq(queue.current_priority(), 0)


# A6
func test_cancelling_the_current_task_starts_the_next_one():
	var a := _task(4)
	var b := _task(2)
	queue.add(a)
	queue.add(b)
	assert_true(queue.cancel(a.id), "current changed")
	assert_same(queue.current, b)
	assert_eq(queue.queued().size(), 0)


func test_cancelling_a_queued_task_only_removes_it():
	var a := _task(4)
	var b := _task(2)
	queue.add(a)
	queue.add(b)
	assert_false(queue.cancel(b.id))
	assert_same(queue.current, a)
	assert_eq(queue.queued().size(), 0)


func test_cancelling_an_unknown_id_changes_nothing():
	var a := _task(4)
	queue.add(a)
	assert_false(queue.cancel(99))
	assert_same(queue.current, a)


func test_queued_returns_a_copy():
	queue.add(_task(5))
	queue.add(_task(1))
	queue.queued().clear()
	assert_eq(queue.queued().size(), 1)


func test_adding_the_same_assignment_twice_is_ignored():
	var a := _task(3)
	queue.add(a)
	assert_false(queue.add(a))
	assert_same(queue.current, a)
	assert_eq(queue.queued().size(), 0)
	queue.cancel(a.id)
	assert_null(queue.current)


# --- feature 004 R5: build jobs never wait in a queue ---

func _build(priority: int) -> Assignment:
	var task := _task(priority)
	task.facility_id = 7
	return task


func test_a_build_pushed_aside_is_dropped_not_queued():
	var build := _build(3)
	queue.add(build)
	var urgent := _task(5)
	assert_true(queue.add(urgent))
	assert_same(queue.current, urgent)
	assert_eq(queue.queued().size(), 0)


func test_an_ordinary_task_pushed_aside_still_waits():
	var errand := _task(3)
	queue.add(errand)
	queue.add(_build(4))
	assert_eq(queue.queued(), [errand] as Array[Assignment])


func test_a_build_that_is_not_more_urgent_is_not_queued():
	var errand := _task(3)
	queue.add(errand)
	assert_false(queue.add(_build(3)))
	assert_same(queue.current, errand)
	assert_eq(queue.queued().size(), 0)


func test_next_priority_is_the_first_waiting_task():
	assert_eq(queue.next_priority(), 0)
	queue.add(_task(5))
	queue.add(_task(2))
	queue.add(_task(4))
	assert_eq(queue.next_priority(), 4)
