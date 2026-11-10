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
