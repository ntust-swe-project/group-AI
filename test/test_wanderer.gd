extends GutTest

# Wandering for A7 / R5 of docs/specs/features/001-base-skeleton.md


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## A rectangular room filling the grid inside a one-cell wall.
func _rect_hall(size: Vector2i) -> StationGrid:
	var grid := StationGrid.new(size)
	grid.add_room_rect(Rect2i(Vector2i.ONE, size - Vector2i(2, 2)))
	return grid


func _one_cell_of_time() -> float:
	return 1.0 / Wanderer.CELLS_PER_SECOND


func test_starts_on_its_start_cell():
	var walker := Wanderer.new(_rect_hall(Vector2i(8, 6)), Vector2i(2, 2), _rng(1))
	assert_eq(walker.cell, Vector2i(2, 2))
	assert_eq(walker.position(), Vector2(2, 2))


func test_moves_one_cell_per_cell_of_time():
	var walker := Wanderer.new(_rect_hall(Vector2i(8, 6)), Vector2i(2, 2), _rng(1))
	walker.advance(_one_cell_of_time())
	var d := (walker.cell - Vector2i(2, 2)).abs()
	assert_eq(d.x + d.y, 1)


func test_position_is_between_cells_mid_step():
	var walker := Wanderer.new(_rect_hall(Vector2i(8, 6)), Vector2i(2, 2), _rng(1))
	walker.advance(_one_cell_of_time() * 0.5)
	assert_eq(walker.cell, Vector2i(2, 2), "has not arrived yet")
	assert_almost_eq(walker.position().distance_to(Vector2(2, 2)), 0.5, 0.001)


func test_never_stands_on_a_wall_and_never_jumps():
	var grid := _rect_hall(Vector2i(10, 7))
	grid.set_wall(Vector2i(4, 2))
	grid.set_wall(Vector2i(4, 3))
	grid.set_wall(Vector2i(4, 4))
	var walker := Wanderer.new(grid, Vector2i(1, 1), _rng(7))
	var previous := walker.cell
	var visited := {}
	for i in 2000:
		walker.advance(_one_cell_of_time() * 0.3)
		assert_true(grid.is_floor(walker.cell), "on a wall at %s" % walker.cell)
		var d := (walker.cell - previous).abs()
		assert_true(d.x + d.y <= 1, "jumped from %s to %s" % [previous, walker.cell])
		previous = walker.cell
		visited[walker.cell] = true
	assert_gt(visited.size(), 5, "should actually wander around")


func test_stays_put_when_there_is_nowhere_to_go():
	var grid := _rect_hall(Vector2i(3, 3))  # a single floor cell
	var walker := Wanderer.new(grid, Vector2i(1, 1), _rng(1))
	walker.advance(10.0)
	assert_eq(walker.cell, Vector2i(1, 1))


func test_floor_cells_are_exactly_the_hall_inside():
	var floor_list := _rect_hall(Vector2i(6, 4)).floor_cells()
	assert_eq(floor_list.size(), 4 * 2)
	assert_does_not_have(floor_list, Vector2i(0, 0))
	assert_has(floor_list, Vector2i(1, 1))
	assert_has(floor_list, Vector2i(4, 2))


func test_one_big_advance_equals_many_small_ones():
	var grid := _rect_hall(Vector2i(10, 7))
	var big := Wanderer.new(grid, Vector2i(1, 1), _rng(3))
	var small := Wanderer.new(grid, Vector2i(1, 1), _rng(3))
	big.advance(_one_cell_of_time() * 3)
	for i in 3:
		small.advance(_one_cell_of_time())
	assert_eq(big.cell, small.cell)
	assert_ne(big.cell, Vector2i(1, 1))


func test_stays_on_the_floor_of_the_default_elliptical_hall():
	var grid := StationGrid.make_hall()
	var walker := Wanderer.new(grid, StationGrid.DEFAULT_HALL_SIZE / 2, _rng(11))
	for i in 2000:
		walker.advance(_one_cell_of_time() * 0.7)
		assert_true(grid.is_floor(walker.cell), "left the floor at %s" % walker.cell)


# --- feature 002 T2: doing assignments (A1, A4) ---

const WORK := Wanderer.WORK_SECONDS


func _walker_in_open_room(start := Vector2i(2, 2)) -> Wanderer:
	return Wanderer.new(_rect_hall(Vector2i(12, 8)), start, _rng(5))


func _advance_until_arrived(walker: Wanderer, cell: Vector2i) -> void:
	for i in 400:
		if walker.cell == cell and walker.remaining_steps() == 0.0:
			return
		walker.advance(_one_cell_of_time() * 0.25)
	fail_test("never arrived at %s" % cell)


func test_assigning_points_the_route_at_the_work_cell_in_the_same_call():
	var walker := _walker_in_open_room()
	walker.assign(Assignment.new(1, Vector2i(9, 5), 3))
	assert_eq(walker.destination(), Vector2i(9, 5))


func test_first_step_after_assigning_gets_closer():
	var walker := _walker_in_open_room()
	walker.advance(_one_cell_of_time() * 1.4)  # mid-step somewhere while wandering
	walker.assign(Assignment.new(1, Vector2i(9, 5), 3))
	var before := walker.remaining_steps()
	walker.advance(_one_cell_of_time() * 0.1)
	assert_lt(walker.remaining_steps(), before)


func test_mid_step_takeover_never_jumps():
	for seed_value in 20:
		var walker := Wanderer.new(_rect_hall(Vector2i(12, 8)), Vector2i(5, 3), _rng(seed_value))
		walker.advance(_one_cell_of_time() * 0.6)
		var before := walker.position()
		walker.assign(Assignment.new(1, Vector2i(1, 1), 2))
		assert_almost_eq(walker.position(), before, Vector2(0.001, 0.001), "seed %d" % seed_value)


func test_less_urgent_assignment_does_not_change_the_route():
	var walker := _walker_in_open_room()
	walker.assign(Assignment.new(1, Vector2i(9, 5), 4))
	walker.assign(Assignment.new(2, Vector2i(1, 6), 4))
	assert_eq(walker.destination(), Vector2i(9, 5))


func test_work_finishes_after_two_seconds_at_the_cell_then_wanders():
	var walker := _walker_in_open_room()
	var task := Assignment.new(1, Vector2i(6, 4), 3)
	walker.assign(task)
	_advance_until_arrived(walker, Vector2i(6, 4))
	walker.advance(WORK * 0.9)
	assert_same(walker.tasks.current, task, "still working")
	assert_eq(walker.cell, Vector2i(6, 4), "stays put while working")
	walker.advance(WORK * 0.2)
	assert_null(walker.tasks.current, "done")
	walker.advance(_one_cell_of_time() * 3)
	assert_ne(walker.position(), Vector2(6, 4), "back to wandering")


func test_no_time_no_work():
	var walker := _walker_in_open_room()
	walker.assign(Assignment.new(1, Vector2i(6, 4), 3))
	_advance_until_arrived(walker, Vector2i(6, 4))
	for i in 100:
		walker.advance(0.0)
	assert_not_null(walker.tasks.current)


func test_next_task_starts_as_soon_as_one_is_done():
	var walker := _walker_in_open_room()
	walker.assign(Assignment.new(1, Vector2i(6, 4), 3))
	walker.assign(Assignment.new(2, Vector2i(9, 2), 1))
	_advance_until_arrived(walker, Vector2i(6, 4))
	walker.advance(WORK + 0.01)
	assert_eq(walker.tasks.current.id, 2)
	assert_eq(walker.destination(), Vector2i(9, 2))


func test_interrupted_task_resumes_after_the_urgent_one():
	var walker := _walker_in_open_room()
	walker.assign(Assignment.new(1, Vector2i(9, 5), 2))
	walker.assign(Assignment.new(2, Vector2i(3, 3), 5))
	assert_eq(walker.destination(), Vector2i(3, 3))
	_advance_until_arrived(walker, Vector2i(3, 3))
	walker.advance(WORK + 0.01)
	assert_eq(walker.tasks.current.id, 1)
	assert_eq(walker.destination(), Vector2i(9, 5))


func test_cancelling_the_current_task_reroutes_at_once():
	var walker := _walker_in_open_room()
	walker.assign(Assignment.new(1, Vector2i(9, 5), 4))
	walker.assign(Assignment.new(2, Vector2i(1, 6), 2))
	walker.cancel(1)
	assert_eq(walker.tasks.current.id, 2)
	assert_eq(walker.destination(), Vector2i(1, 6))


func test_mid_step_takeover_turns_back_when_that_is_shorter():
	var walker := _walker_in_open_room(Vector2i(5, 3))
	walker.assign(Assignment.new(1, Vector2i(9, 3), 1))  # heading right
	walker.advance(_one_cell_of_time() * 0.3)  # 0.3 of the way from (5,3) to (6,3)
	var x_before := walker.position().x
	walker.assign(Assignment.new(2, Vector2i(2, 3), 5))  # urgent, behind
	walker.advance(_one_cell_of_time() * 0.1)
	assert_lt(walker.position().x, x_before, "should turn back, not finish the step first")


func test_work_time_starts_over_for_the_task_that_takes_over():
	var walker := _walker_in_open_room()
	walker.assign(Assignment.new(1, Vector2i(6, 4), 2))
	_advance_until_arrived(walker, Vector2i(6, 4))
	walker.advance(WORK * 0.75)
	walker.assign(Assignment.new(2, Vector2i(8, 4), 5))
	_advance_until_arrived(walker, Vector2i(8, 4))
	walker.advance(WORK * 0.5)
	assert_eq(walker.tasks.current.id, 2, "half the work time is not enough")


func test_cancelling_mid_step_finishes_the_step_then_wanders():
	var walker := _walker_in_open_room(Vector2i(5, 3))
	walker.assign(Assignment.new(1, Vector2i(9, 3), 1))
	walker.advance(_one_cell_of_time() * 0.3)
	var before := walker.position()
	walker.cancel(1)
	assert_almost_eq(walker.position(), before, Vector2(0.001, 0.001), "no jump")
	assert_eq(walker.destination(), Vector2i(6, 3), "only the step in progress is left")
	assert_null(walker.tasks.current)


func test_unreachable_assignment_mid_step_is_dropped_after_the_step():
	var grid := StationGrid.new(Vector2i(14, 6))
	grid.add_room_rect(Rect2i(1, 1, 6, 4))
	grid.add_room_rect(Rect2i(9, 1, 4, 4))  # a second room with no corridor
	var walker := Wanderer.new(grid, Vector2i(2, 2), _rng(1))
	walker.assign(Assignment.new(1, Vector2i(5, 2), 1))
	walker.advance(_one_cell_of_time() * 0.3)
	walker.assign(Assignment.new(2, Vector2i(10, 2), 5))  # cannot be reached
	assert_lte(walker.remaining_steps(), 1.0, "does not keep an old route")
	walker.advance(_one_cell_of_time())
	assert_eq(walker.tasks.current.id, 1, "dropped, back to the reachable one")
