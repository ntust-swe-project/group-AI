extends GutTest

# A2, A3 and A8 of docs/specs/features/004-construction.md: build jobs live in
# a shared pool and are handed out by priority, at most two builders each.

const STALL := FacilityCatalog.Kind.HYGIENE_STALL

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


func _is_build(task: Assignment) -> bool:
	return task != null and task.facility_id != Assignment.NO_FACILITY


## A8: no build job waits in a queue, every builder's blueprint exists, and no
## blueprint has more than two builders.
func _assert_no_zombies(step: String) -> void:
	var counts := {}
	for id in walkers:
		var tasks: TaskQueue = walkers[id].tasks
		for task in tasks.queued():
			assert_false(_is_build(task), "%s: colonist %d has a build job waiting" % [step, id])
		if _is_build(tasks.current):
			var blueprint := construction.find(tasks.current.facility_id)
			assert_true(blueprint != null and not blueprint.built, "%s: colonist %d builds something gone" % [step, id])
			counts[tasks.current.facility_id] = counts.get(tasks.current.facility_id, 0) + 1
	for facility_id in counts:
		assert_lte(counts[facility_id], 2, "%s: blueprint %d has too many builders" % [step, facility_id])


# --- A2: a blueprint's job ---

func test_a_new_blueprint_has_a_priority_3_job_and_no_builders():
	_add(1, Vector2i(1, 1))
	var stall := construction.place(STALL, Vector2i(5, 2))
	assert_eq(construction.priority_of(stall.id), 3)
	assert_eq(construction.builders_of(stall.id).size(), 0)
	_assert_no_zombies("placed")


func test_an_idle_colonist_takes_the_job_next_to_the_blueprint():
	var ann := _add(1, Vector2i(1, 1))
	var stall := construction.place(STALL, Vector2i(5, 2))
	construction.assign_builders()
	assert_true(_is_build(ann.tasks.current))
	assert_eq(ann.tasks.current.facility_id, stall.id)
	assert_eq(ann.tasks.current.priority, 3)
	var d: Vector2i = (ann.tasks.current.cell - Vector2i(5, 2)).abs()
	assert_eq(d.x + d.y, 1, "works from a cell beside it")
	assert_eq(construction.builders_of(stall.id), [1] as Array[int])
	_assert_no_zombies("assigned")


func test_priority_must_be_1_to_5():
	var stall := construction.place(STALL, Vector2i(5, 2))
	assert_false(construction.set_priority(stall.id, 0))
	assert_false(construction.set_priority(stall.id, 6))
	assert_false(construction.set_priority(999, 4))
	assert_eq(construction.priority_of(stall.id), 3)


func test_raising_priority_keeps_the_builder_and_pulls_in_one_more():
	var ann := _add(1, Vector2i(4, 2))
	var bob := _add(2, Vector2i(8, 2))
	var stall := construction.place(STALL, Vector2i(5, 2))
	board.create(2, Vector2i(10, 4), 3)  # bob is busy with a 3
	construction.assign_builders()
	assert_eq(construction.builders_of(stall.id), [1] as Array[int])
	assert_true(construction.set_priority(stall.id, 4))
	assert_eq(ann.tasks.current.priority, 4, "ann's job follows the new priority")
	construction.assign_builders()
	assert_eq(construction.builders_of(stall.id), [1, 2] as Array[int])
	assert_eq(bob.tasks.queued().size(), 1, "bob's 3 waits")
	_assert_no_zombies("raised")


func test_lowering_below_a_waiting_task_sends_the_builder_to_it():
	var ann := _add(1, Vector2i(4, 2))
	var stall := construction.place(STALL, Vector2i(5, 2))
	construction.set_priority(stall.id, 4)
	construction.assign_builders()
	var errand := board.create(1, Vector2i(10, 4), 3)
	assert_true(_is_build(ann.tasks.current), "the 3 waits behind the 4")
	construction.set_priority(stall.id, 2)
	assert_same(ann.tasks.current, errand)
	assert_eq(construction.builders_of(stall.id).size(), 0)
	_assert_no_zombies("lowered")
	construction.assign_builders()
	assert_same(ann.tasks.current, errand, "a 3 is more urgent than the 2 build")
	_assert_no_zombies("reassigned")


func test_lowering_with_nothing_more_urgent_keeps_building():
	var ann := _add(1, Vector2i(4, 2))
	var stall := construction.place(STALL, Vector2i(5, 2))
	construction.set_priority(stall.id, 4)
	construction.assign_builders()
	construction.set_priority(stall.id, 1)
	assert_true(_is_build(ann.tasks.current))
	assert_eq(ann.tasks.current.priority, 1)
	_assert_no_zombies("lowered, nothing waiting")


# --- A3: who takes the job ---

func test_a_build_pulls_people_off_less_urgent_work_only():
	var ann := _add(1, Vector2i(4, 2))
	var bob := _add(2, Vector2i(6, 2))
	var stall := construction.place(STALL, Vector2i(5, 3))
	construction.set_priority(stall.id, 4)
	var ann_errand := board.create(1, Vector2i(10, 4), 3)
	var bob_errand := board.create(2, Vector2i(10, 1), 4)
	construction.assign_builders()
	assert_true(_is_build(ann.tasks.current), "ann drops her 3")
	assert_eq(ann.tasks.queued(), [ann_errand] as Array[Assignment], "and it goes back in her queue")
	assert_same(bob.tasks.current, bob_errand, "bob keeps his 4")
	_assert_no_zombies("pulled")


func test_only_the_two_nearest_go():
	_add(1, Vector2i(3, 2))
	_add(2, Vector2i(12, 4))
	_add(3, Vector2i(7, 2))
	var stall := construction.place(STALL, Vector2i(5, 2))
	construction.assign_builders()
	assert_eq(construction.builders_of(stall.id), [1, 3] as Array[int])
	assert_null(walkers[2].tasks.current)
	_assert_no_zombies("two nearest")


func test_nearest_is_by_walking_distance():
	# A wall from (6, 1) to (6, 3), so from (7, 1) the way to (5, 2) goes round.
	# Counting cells as the crow flies, ann and bob are nearest (3 each) and
	# cara is furthest (5); on foot ann needs 7 steps, bob 3, cara 5.
	var stall := construction.place(STALL, Vector2i(4, 2))
	for y in range(1, 4):
		grid.set_wall(Vector2i(6, y))
	var ann := _add(1, Vector2i(7, 1))
	_add(2, Vector2i(2, 4))
	_add(3, Vector2i(8, 4))
	construction.assign_builders()
	assert_eq(construction.builders_of(stall.id), [2, 3] as Array[int])
	assert_null(ann.tasks.current, "close as the crow flies, far on foot")
	_assert_no_zombies("walking distance")


func test_the_more_urgent_blueprint_is_staffed_first():
	_add(1, Vector2i(1, 1))
	var low := construction.place(STALL, Vector2i(3, 2))
	var high := construction.place(STALL, Vector2i(10, 2))
	construction.set_priority(low.id, 2)
	construction.set_priority(high.id, 4)
	construction.assign_builders()
	assert_eq(construction.builders_of(high.id), [1] as Array[int])
	assert_eq(construction.builders_of(low.id).size(), 0)
	_assert_no_zombies("by priority")


func test_on_equal_priority_the_older_blueprint_is_staffed_first():
	# Both colonists stand beside the newer one, but the older one comes first.
	_add(1, Vector2i(9, 2))
	_add(2, Vector2i(11, 2))
	var older := construction.place(STALL, Vector2i(3, 2))
	var newer := construction.place(STALL, Vector2i(10, 2))
	construction.assign_builders()
	assert_eq(construction.builders_of(older.id), [1, 2] as Array[int])
	assert_eq(construction.builders_of(newer.id).size(), 0)
	_assert_no_zombies("by age")


func test_a_preempted_builder_drops_the_job_and_someone_else_fills_in():
	var ann := _add(1, Vector2i(4, 2))
	_add(2, Vector2i(6, 2))
	_add(3, Vector2i(12, 4))
	var stall := construction.place(STALL, Vector2i(5, 2))
	construction.assign_builders()
	assert_eq(construction.builders_of(stall.id), [1, 2] as Array[int])
	var urgent := board.create(1, Vector2i(1, 4), 5)
	assert_same(ann.tasks.current, urgent)
	assert_eq(ann.tasks.queued().size(), 0, "the build did not go back in her queue")
	assert_eq(construction.builders_of(stall.id), [2] as Array[int])
	_assert_no_zombies("preempted")
	construction.assign_builders()
	assert_eq(construction.builders_of(stall.id), [2, 3] as Array[int])
	_assert_no_zombies("refilled")


func test_nobody_takes_a_job_they_cannot_reach():
	var stall := construction.place(STALL, Vector2i(5, 2))
	_add(1, Vector2i(1, 1))
	for y in range(1, 5):
		grid.set_wall(Vector2i(2, y))  # shut ann into column 1 after placing
	construction.assign_builders()
	assert_null(walkers[1].tasks.current)
	assert_eq(construction.builders_of(stall.id).size(), 0)


# --- cancelling ---

func test_cancelling_a_blueprint_frees_its_builders_at_once():
	var ann := _add(1, Vector2i(4, 2))
	var bob := _add(2, Vector2i(6, 2))
	var stall := construction.place(STALL, Vector2i(5, 2))
	var errand := board.create(2, Vector2i(10, 4), 1)
	construction.assign_builders()
	construction.cancel(stall.id)
	assert_null(ann.tasks.current)
	assert_same(bob.tasks.current, errand, "bob goes back to his errand")
	_assert_no_zombies("cancelled")
