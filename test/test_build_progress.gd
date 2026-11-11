extends GutTest

# A4 and A5 of docs/specs/features/004-construction.md: building takes 0.2 game
# days for one builder, 1.75x as fast for two; a finished facility blocks.

const STALL := FacilityCatalog.Kind.HYGIENE_STALL
const POD := FacilityCatalog.Kind.SLEEP_POD
const ONE_BUILDER := 0.2 * DayClock.SECONDS_PER_DAY  # Q2
const TWO_BUILDERS := ONE_BUILDER / 1.75  # Q3

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


func test_the_build_time_comes_from_the_catalog():
	assert_almost_eq(FacilityCatalog.build_seconds(STALL), ONE_BUILDER, 0.001)
	assert_almost_eq(FacilityCatalog.build_seconds(POD), ONE_BUILDER, 0.001)


# --- A4: how long it takes ---

func test_a_builder_keeps_working_past_the_placeholder_two_seconds():
	var ann := _add(1, Vector2i(4, 2))
	construction.place(STALL, Vector2i(5, 2))
	construction.assign_builders()
	ann.advance(Wanderer.WORK_SECONDS * 3)
	assert_true(ann.tasks.current.is_build(), "a build job is not done after 2 s")
	assert_true(ann.is_working())


func test_one_builder_takes_point_two_days():
	_add(1, Vector2i(4, 2))
	var stall := construction.place(STALL, Vector2i(5, 2))
	construction.assign_builders()
	_run(ONE_BUILDER - 1.0)
	assert_false(stall.built)
	assert_almost_eq(construction.progress_of(stall.id), (ONE_BUILDER - 1.0) / ONE_BUILDER, 0.01)
	_run(1.0)
	assert_true(stall.built)


func test_two_builders_are_one_point_seven_five_times_as_fast():
	_add(1, Vector2i(4, 2))
	_add(2, Vector2i(6, 2))
	var stall := construction.place(STALL, Vector2i(5, 2))
	construction.assign_builders()
	_run(TWO_BUILDERS - 1.0)
	assert_false(stall.built, "not twice as fast")
	_run(1.0)
	assert_true(stall.built)


func test_walking_there_does_not_count():
	_add(1, Vector2i(12, 4))
	var stall := construction.place(STALL, Vector2i(2, 1))
	construction.assign_builders()
	construction.advance(ONE_BUILDER)  # nobody has arrived yet
	assert_eq(construction.progress_of(stall.id), 0.0)


func test_progress_stays_when_the_builder_leaves_and_resumes_later():
	var ann := _add(1, Vector2i(4, 2))
	var stall := construction.place(STALL, Vector2i(5, 2))
	construction.assign_builders()
	_run(ONE_BUILDER / 2.0)
	var urgent := board.create(1, Vector2i(4, 4), 5)
	assert_same(ann.tasks.current, urgent)
	var before := construction.progress_of(stall.id)
	_run(2.0)  # walking there and starting the errand
	assert_eq(construction.progress_of(stall.id), before, "no progress while away")
	_run(3.0)  # errand done, back at the build
	assert_true(construction.builders_of(stall.id).has(1), "taken again once free")
	assert_false(stall.built)
	_run(ONE_BUILDER / 2.0)
	assert_true(stall.built, "half was already done")


# --- A5: a finished facility ---

func test_a_finished_facility_blocks_and_its_builders_move_on():
	var ann := _add(1, Vector2i(4, 2))
	var errand := board.create(1, Vector2i(12, 4), 1)
	var pod := construction.place(POD, Vector2i(5, 2))
	construction.assign_builders()
	_run(ONE_BUILDER)
	assert_true(pod.built)
	assert_eq(construction.facilities(), [pod] as Array[Facility])
	assert_eq(construction.blueprints().size(), 0)
	assert_true(grid.is_blocked(Vector2i(5, 2)))
	assert_true(grid.is_blocked(Vector2i(5, 3)))
	assert_same(ann.tasks.current, errand, "back to the errand")
	var path := grid.find_path(Vector2i(4, 2), Vector2i(6, 2))
	assert_false(path.has(Vector2i(5, 2)), "paths go round it")


func test_someone_standing_on_it_is_moved_to_free_floor():
	_add(1, Vector2i(4, 2))
	var stall := construction.place(STALL, Vector2i(5, 2))
	construction.assign_builders()
	_run(ONE_BUILDER - 1.0)
	var bob := _add(2, Vector2i(5, 2))  # blueprints can be walked on
	construction.advance(1.0)  # only build, so bob stays put until it is done
	assert_true(stall.built)
	assert_true(grid.is_walkable(bob.cell), "not left inside the facility")
	var d: Vector2i = (bob.cell - Vector2i(5, 2)).abs()
	assert_eq(d.x + d.y, 1, "moved to the nearest free cell")


func test_someone_walking_through_goes_round_once_it_is_finished():
	_add(1, Vector2i(5, 1))
	var stall := construction.place(STALL, Vector2i(5, 2))
	construction.assign_builders()
	_run(ONE_BUILDER - 0.5)
	# Bob joins now, on a 5 so he never builds, heading along row 2 through (5, 2).
	var bob := _add(2, Vector2i(3, 2))
	board.create(2, Vector2i(9, 2), 5)
	assert_eq(bob.remaining_steps(), 6.0, "straight through the blueprint")
	var arrived := false
	var rerouted := false
	for i in 120:  # 6 s; the way round is 8 steps at 2 per second
		var before := bob.remaining_steps()
		_tick(0.05)
		if stall.built and not rerouted:
			rerouted = true
			assert_gt(bob.remaining_steps(), before - 0.2, "the route got longer when it was finished")
		assert_false(grid.is_blocked(bob.cell), "bob walked into the facility at step %d" % i)
		arrived = arrived or bob.cell == Vector2i(9, 2)
	assert_true(stall.built)
	assert_true(arrived, "bob still got to his errand")


func test_a_builder_never_stands_on_another_blueprint():
	_add(1, Vector2i(1, 2))
	var first := construction.place(STALL, Vector2i(3, 2))
	var second := construction.place(STALL, Vector2i(5, 2))
	construction.assign_builders()
	for colonist_id in construction.builders_of(first.id) + construction.builders_of(second.id):
		var spot: Vector2i = walkers[colonist_id].tasks.current.cell
		assert_null(construction.at(spot), "works from %s, which is a blueprint" % spot)


func test_wandering_never_picks_a_blocked_cell():
	var ann := _add(1, Vector2i(1, 1))
	var stall := construction.place(STALL, Vector2i(3, 3))
	construction.assign_builders()
	_run(ONE_BUILDER + 5.0)
	assert_true(stall.built)
	for i in 400:
		ann.advance(0.5)
		assert_false(grid.is_blocked(ann.cell))
		assert_false(grid.is_blocked(ann.destination()))

