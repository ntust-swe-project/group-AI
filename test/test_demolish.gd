extends GutTest

# A6 of docs/specs/features/004-construction.md: demolishing a facility.

const STALL := FacilityCatalog.Kind.HYGIENE_STALL
const POD := FacilityCatalog.Kind.SLEEP_POD
const ONE_BUILDER := 0.2 * DayClock.SECONDS_PER_DAY  # Q2

var grid: StationGrid
var board: AssignmentBoard
var construction: Construction
var walkers := {}  # colonist id -> Wanderer


# One open room, cells 1..12 x 1..4.
func before_each():
	grid = StationGrid.new(Vector2i(14, 6))
	grid.add_room_rect(Rect2i(1, 1, 12, 4))
	board = AssignmentBoard.new(grid)
	construction = Construction.new(grid, board)
	walkers = {}


func _add(colonist_id: int, cell: Vector2i) -> Wanderer:
	var walker := Wanderer.new(grid, cell)
	walkers[colonist_id] = walker
	board.register(colonist_id, walker)
	return walker


## What main.gd does each frame: move everyone, build, hand out jobs.
func _tick(seconds: float) -> void:
	for walker in walkers.values():
		walker.advance(seconds)
	construction.advance(seconds)
	construction.assign_builders()


func _run(total: float, step := 0.5) -> void:
	var left := total
	while left > 0.0:
		_tick(minf(step, left))
		left -= step


func _build_stall_at(cell: Vector2i) -> Facility:
	_add(1, cell + Vector2i.LEFT)
	var stall := construction.place(STALL, cell)
	construction.assign_builders()
	_run(ONE_BUILDER)
	return stall


func test_demolishing_removes_the_facility_and_frees_its_cells():
	var stall := _build_stall_at(Vector2i(5, 2))
	assert_true(stall.built)
	assert_true(construction.demolish(stall.id))
	assert_eq(construction.facilities().size(), 0)
	assert_null(construction.at(Vector2i(5, 2)))
	assert_true(grid.is_walkable(Vector2i(5, 2)))
	var path := grid.find_path(Vector2i(4, 2), Vector2i(6, 2))
	assert_eq(path.size(), 3, "straight through again")
	assert_not_null(construction.place(POD, Vector2i(5, 2)), "the cell can be built on again")
	_assert_no_build_jobs("after demolishing")


func test_demolishing_a_pod_frees_both_cells():
	_add(1, Vector2i(4, 2))
	var pod := construction.place(POD, Vector2i(5, 2))
	construction.assign_builders()
	_run(ONE_BUILDER)
	assert_true(construction.demolish(pod.id))
	for cell in [Vector2i(5, 2), Vector2i(5, 3)]:
		assert_true(grid.is_walkable(cell))
		var path := grid.find_path(Vector2i(4, cell.y), Vector2i(6, cell.y))
		assert_eq(path.size(), 3, "straight through %s again" % cell)
	_assert_no_build_jobs("after demolishing")


func test_after_demolishing_colonists_take_the_shorter_way():
	var stall := _build_stall_at(Vector2i(5, 2))
	for y in [1, 3]:
		grid.set_wall(Vector2i(5, y))  # column 5 is open only at the stall and at y = 4
	var bob := _add(2, Vector2i(3, 2))
	board.create(2, Vector2i(7, 2), 5)
	assert_eq(bob.remaining_steps(), 8.0, "round by row 4 while the stall stands")
	construction.demolish(stall.id)
	assert_eq(bob.remaining_steps(), 4.0, "re-planned straight through at once")


## A8 for demolishing: no build job is left on anyone.
func _assert_no_build_jobs(step: String) -> void:
	for id in walkers:
		var tasks: TaskQueue = walkers[id].tasks
		assert_false(tasks.current != null and tasks.current.is_build(), "%s: colonist %d still building" % [step, id])
		for task in tasks.queued():
			assert_false(task.is_build(), "%s: colonist %d has a build job waiting" % [step, id])


func test_only_built_facilities_can_be_demolished():
	var stall := construction.place(STALL, Vector2i(5, 2))
	assert_false(construction.demolish(stall.id), "a blueprint is cancelled, not demolished")
	assert_eq(construction.blueprints(), [stall] as Array[Facility])
	assert_false(construction.demolish(999))


func test_cancel_does_not_remove_a_built_facility():
	var stall := _build_stall_at(Vector2i(5, 2))
	assert_false(construction.cancel(stall.id))
	assert_eq(construction.facilities(), [stall] as Array[Facility])
