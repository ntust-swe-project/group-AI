extends GutTest

# A7 (logic half) of docs/specs/features/002-assignment.md

var grid: StationGrid
var board: AssignmentBoard
var ann: Wanderer
var bob: Wanderer


# Room A (cells 1..6 x 1..4) where both colonists stand, and room B
# (cells 9..12 x 1..4) with no corridor to it.
func before_each():
	grid = StationGrid.new(Vector2i(14, 6))
	grid.add_room_rect(Rect2i(1, 1, 6, 4))
	grid.add_room_rect(Rect2i(9, 1, 4, 4))
	board = AssignmentBoard.new(grid)
	ann = Wanderer.new(grid, Vector2i(2, 2))
	bob = Wanderer.new(grid, Vector2i(5, 3))
	board.register(1, ann)
	board.register(2, bob)


func test_creating_gives_the_colonist_the_assignment():
	var task := board.create(1, Vector2i(4, 2), 3)
	assert_not_null(task)
	assert_same(ann.tasks.current, task)
	assert_eq(board.owner_of(task.id), 1)


func test_ids_are_unique_and_grow():
	var a := board.create(1, Vector2i(4, 2), 3)
	var b := board.create(2, Vector2i(3, 3), 3)
	var c := board.create(1, Vector2i(5, 1), 1)
	assert_lt(a.id, b.id)
	assert_lt(b.id, c.id)


func test_no_assignment_on_wall_space_or_outside():
	for cell in [Vector2i(0, 0), Vector2i(7, 2), Vector2i(8, 2), Vector2i(-3, 1), Vector2i(40, 40)]:
		assert_null(board.create(1, cell, 3), "cell %s" % cell)
	assert_null(ann.tasks.current)


func test_no_assignment_the_colonist_cannot_reach():
	assert_null(board.create(1, Vector2i(10, 2), 3))
	assert_null(ann.tasks.current)


func test_priority_must_be_one_to_five():
	assert_null(board.create(1, Vector2i(4, 2), 0))
	assert_null(board.create(1, Vector2i(4, 2), 6))
	assert_not_null(board.create(1, Vector2i(4, 2), 1))
	assert_not_null(board.create(1, Vector2i(4, 3), 5))


func test_unknown_colonist_gets_nothing():
	assert_null(board.create(99, Vector2i(4, 2), 3))


func test_cancel_finds_the_right_colonist():
	var a := board.create(1, Vector2i(4, 2), 3)
	var b := board.create(2, Vector2i(3, 3), 3)
	assert_true(board.cancel(b.id))
	assert_null(bob.tasks.current)
	assert_same(ann.tasks.current, a)
	assert_false(board.cancel(b.id), "already gone")
	assert_false(board.cancel(1234))


func test_lists_every_assignment_at_a_cell_current_or_waiting():
	var a := board.create(1, Vector2i(4, 2), 5)
	var b := board.create(1, Vector2i(4, 2), 2)  # waits in Ann's queue
	var c := board.create(2, Vector2i(4, 2), 3)
	board.create(2, Vector2i(3, 3), 1)
	var ids := []
	for task in board.at(Vector2i(4, 2)):
		ids.append(task.id)
	ids.sort()
	assert_eq(ids, [a.id, b.id, c.id])


func test_finished_assignments_are_no_longer_listed():
	board.create(1, Vector2i(2, 2), 3)  # where Ann already stands
	ann.advance(Wanderer.WORK_SECONDS + 0.01)
	assert_eq(board.at(Vector2i(2, 2)).size(), 0)


func test_menu_opens_only_on_floor_someone_can_reach():
	assert_true(board.can_assign_at(Vector2i(4, 2)))
	assert_false(board.can_assign_at(Vector2i(7, 2)), "wall")
	assert_false(board.can_assign_at(Vector2i(0, 0)), "space")
	assert_false(board.can_assign_at(Vector2i(10, 2)), "floor nobody can reach")


func test_who_can_reach_lists_only_colonists_who_can_walk_there():
	var cyd := Wanderer.new(grid, Vector2i(10, 2))  # stands in room B
	board.register(3, cyd)
	assert_eq(board.who_can_reach(Vector2i(4, 2)), [1, 2] as Array[int])
	assert_eq(board.who_can_reach(Vector2i(11, 3)), [3] as Array[int])
	assert_true(board.can_assign_at(Vector2i(11, 3)), "someone can reach room B now")
