extends GutTest

# A5 of docs/specs/features/001-base-skeleton.md


func _is_four_way_step(a: Vector2i, b: Vector2i) -> bool:
	var d := (b - a).abs()
	return d.x + d.y == 1


func _assert_valid_path(grid: StationGrid, path: Array[Vector2i], from: Vector2i, to: Vector2i):
	assert_gt(path.size(), 0, "path should exist")
	if path.is_empty():
		return
	assert_eq(path.front(), from)
	assert_eq(path.back(), to)
	for i in path.size():
		assert_false(grid.is_wall(path[i]), "path goes through a wall at %s" % path[i])
		if i > 0:
			assert_true(_is_four_way_step(path[i - 1], path[i]), "jump between %s and %s" % [path[i - 1], path[i]])


# 5x5, wall down column 2 except the bottom row:
#   . . # . .
#   . . # . .
#   . . # . .
#   . . # . .
#   . . . . .
func _grid_with_wall_column() -> StationGrid:
	var grid := StationGrid.new(Vector2i(5, 5))
	for y in 4:
		grid.set_wall(Vector2i(2, y))
	return grid


func test_path_goes_around_a_wall():
	var grid := _grid_with_wall_column()
	var path := grid.find_path(Vector2i(0, 0), Vector2i(4, 0))
	_assert_valid_path(grid, path, Vector2i(0, 0), Vector2i(4, 0))
	assert_has(path, Vector2i(2, 4), "the only gap is at the bottom")


func test_path_to_the_same_cell_has_length_one():
	var grid := StationGrid.new(Vector2i(3, 3))
	assert_eq(grid.find_path(Vector2i(1, 1), Vector2i(1, 1)), [Vector2i(1, 1)] as Array[Vector2i])


func test_no_path_into_a_wall():
	var grid := _grid_with_wall_column()
	assert_eq(grid.find_path(Vector2i(0, 0), Vector2i(2, 0)).size(), 0)


func test_no_path_when_sealed_off():
	var grid := _grid_with_wall_column()
	grid.set_wall(Vector2i(2, 4))
	assert_eq(grid.find_path(Vector2i(0, 0), Vector2i(4, 0)).size(), 0)


func test_no_path_outside_the_grid():
	var grid := StationGrid.new(Vector2i(3, 3))
	assert_eq(grid.find_path(Vector2i(0, 0), Vector2i(5, 5)).size(), 0)


func test_hall_has_walls_all_around_and_floor_inside():
	var grid := StationGrid.make_hall(Vector2i(6, 4))
	for x in 6:
		assert_true(grid.is_wall(Vector2i(x, 0)))
		assert_true(grid.is_wall(Vector2i(x, 3)))
	for y in 4:
		assert_true(grid.is_wall(Vector2i(0, y)))
		assert_true(grid.is_wall(Vector2i(5, y)))
	for x in range(1, 5):
		for y in range(1, 3):
			assert_false(grid.is_wall(Vector2i(x, y)))


func test_cells_outside_the_grid_count_as_wall():
	var grid := StationGrid.new(Vector2i(3, 3))
	assert_true(grid.is_wall(Vector2i(-1, 0)))
	assert_true(grid.is_wall(Vector2i(3, 1)))
	assert_false(grid.is_wall(Vector2i(2, 2)))


func test_path_across_the_hall_stays_inside():
	var grid := StationGrid.make_hall(Vector2i(10, 6))
	var path := grid.find_path(Vector2i(1, 1), Vector2i(8, 4))
	_assert_valid_path(grid, path, Vector2i(1, 1), Vector2i(8, 4))
