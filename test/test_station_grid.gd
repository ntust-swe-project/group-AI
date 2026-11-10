extends GutTest

# A5 and A11 of docs/specs/features/001-base-skeleton.md

const NEIGHBOURS := [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]


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
		assert_true(grid.is_floor(path[i]), "path leaves the floor at %s" % path[i])
		if i > 0:
			assert_true(_is_four_way_step(path[i - 1], path[i]), "jump between %s and %s" % [path[i - 1], path[i]])


## A grid that is floor everywhere.
func _open_grid(size: Vector2i) -> StationGrid:
	var grid := StationGrid.new(size)
	grid.add_room_rect(Rect2i(Vector2i.ZERO, size))
	return grid


# 5x5 floor, wall down column 2 except the bottom row:
#   . . # . .
#   . . # . .
#   . . # . .
#   . . # . .
#   . . . . .
func _grid_with_wall_column() -> StationGrid:
	var grid := _open_grid(Vector2i(5, 5))
	for y in 4:
		grid.set_wall(Vector2i(2, y))
	return grid


# --- A5: pathfinding ---

func test_path_goes_around_a_wall():
	var grid := _grid_with_wall_column()
	var path := grid.find_path(Vector2i(0, 0), Vector2i(4, 0))
	_assert_valid_path(grid, path, Vector2i(0, 0), Vector2i(4, 0))
	assert_has(path, Vector2i(2, 4), "the only gap is at the bottom")


func test_path_to_the_same_cell_has_length_one():
	var grid := _open_grid(Vector2i(3, 3))
	assert_eq(grid.find_path(Vector2i(1, 1), Vector2i(1, 1)), [Vector2i(1, 1)] as Array[Vector2i])


func test_no_path_into_a_wall():
	var grid := _grid_with_wall_column()
	assert_eq(grid.find_path(Vector2i(0, 0), Vector2i(2, 0)).size(), 0)


func test_no_path_when_sealed_off():
	var grid := _grid_with_wall_column()
	grid.set_wall(Vector2i(2, 4))
	assert_eq(grid.find_path(Vector2i(0, 0), Vector2i(4, 0)).size(), 0)


func test_no_path_outside_the_grid():
	var grid := _open_grid(Vector2i(3, 3))
	assert_eq(grid.find_path(Vector2i(0, 0), Vector2i(5, 5)).size(), 0)


func test_outside_the_grid_is_space():
	var grid := _open_grid(Vector2i(3, 3))
	assert_eq(grid.kind_of(Vector2i(-1, 0)), StationGrid.Cell.SPACE)
	assert_eq(grid.kind_of(Vector2i(3, 1)), StationGrid.Cell.SPACE)
	assert_false(grid.is_floor(Vector2i(-1, 0)))


func test_a_new_grid_is_all_space():
	var grid := StationGrid.new(Vector2i(4, 3))
	assert_eq(grid.floor_cells().size(), 0)
	assert_eq(grid.kind_of(Vector2i(1, 1)), StationGrid.Cell.SPACE)


# --- A11: rooms ---

func test_ellipse_room_is_floor_inside_but_not_in_its_corners():
	var grid := StationGrid.new(Vector2i(12, 8))
	grid.add_room_ellipse(Rect2i(1, 1, 10, 6))
	assert_true(grid.is_floor(Vector2i(5, 3)), "centre is floor")
	assert_true(grid.is_floor(Vector2i(1, 3)), "left tip is floor")
	assert_false(grid.is_floor(Vector2i(1, 1)), "rect corner is outside the ellipse")
	assert_eq(grid.kind_of(Vector2i(0, 0)), StationGrid.Cell.SPACE)


func test_walls_hug_the_floor_and_nothing_else():
	var grid := StationGrid.new(Vector2i(12, 8))
	grid.add_room_ellipse(Rect2i(1, 1, 10, 6))
	_assert_walls_hug_floor(grid)


func test_default_hall_walls_hug_the_floor():
	_assert_walls_hug_floor(StationGrid.make_hall())


func _assert_walls_hug_floor(grid: StationGrid) -> void:
	for x in grid.size.x:
		for y in grid.size.y:
			var cell := Vector2i(x, y)
			var next_to_floor := false
			for d in NEIGHBOURS:
				if grid.is_floor(cell + d):
					next_to_floor = true
			match grid.kind_of(cell):
				StationGrid.Cell.WALL:
					assert_true(next_to_floor, "wall at %s touches no floor" % cell)
				StationGrid.Cell.SPACE:
					assert_false(next_to_floor, "floor at the edge of space near %s" % cell)


func test_two_rooms_joined_by_a_corridor_are_reachable():
	var grid := StationGrid.new(Vector2i(24, 10))
	grid.add_room_ellipse(Rect2i(1, 1, 8, 8))
	grid.add_room_rect(Rect2i(15, 2, 8, 6))
	assert_eq(grid.find_path(Vector2i(5, 5), Vector2i(18, 5)).size(), 0, "not joined yet")
	grid.add_room_rect(Rect2i(8, 5, 8, 1))  # corridor
	_assert_valid_path(grid, grid.find_path(Vector2i(5, 5), Vector2i(18, 5)), Vector2i(5, 5), Vector2i(18, 5))


func test_corridor_through_a_wall_turns_it_into_floor():
	var grid := StationGrid.new(Vector2i(12, 6))
	grid.add_room_rect(Rect2i(1, 1, 4, 4))
	assert_eq(grid.kind_of(Vector2i(5, 2)), StationGrid.Cell.WALL)
	grid.add_room_rect(Rect2i(5, 2, 3, 1))
	assert_true(grid.is_floor(Vector2i(5, 2)))


func test_default_hall_is_an_ellipse():
	var grid := StationGrid.make_hall()
	var centre := StationGrid.DEFAULT_HALL_SIZE / 2
	var top := Vector2i(centre.x, 2)
	var bottom := Vector2i(centre.x, StationGrid.DEFAULT_HALL_SIZE.y - 3)
	assert_true(grid.is_floor(centre))
	assert_eq(grid.kind_of(Vector2i(0, 0)), StationGrid.Cell.SPACE)
	assert_eq(grid.kind_of(Vector2i(1, 1)), StationGrid.Cell.SPACE)
	_assert_valid_path(grid, grid.find_path(top, bottom), top, bottom)
