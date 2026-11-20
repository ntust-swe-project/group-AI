extends GutTest

# A3, A4 and A7 of docs/specs/features/005-resources.md: production jobs are
# handed out like build jobs (one worker per facility), turn work time into
# stock, and never outlive their facility.

const BAY := FacilityCatalog.Kind.HYDROPONICS_BAY
const RECYCLER := FacilityCatalog.Kind.WATER_RECYCLER
const FAB := FacilityCatalog.Kind.FABRICATOR
const POD := FacilityCatalog.Kind.SLEEP_POD
const UNIT := Production.SECONDS_PER_UNIT

var grid: StationGrid
var board: AssignmentBoard
var stock: Stockpile
var construction: Construction
var production: Production
var walkers := {}  # colonist id -> Wanderer


# One open room, cells 1..16 x 1..6.
func before_each():
	grid = StationGrid.new(Vector2i(18, 8))
	grid.add_room_rect(Rect2i(1, 1, 16, 6))
	board = AssignmentBoard.new(grid)
	stock = Stockpile.new()
	stock.add(Stockpile.Kind.MATERIALS, 100)
	construction = Construction.new(grid, board, stock)
	production = Production.new(construction, board, grid, stock)
	walkers = {}


func _add(colonist_id: int, cell: Vector2i) -> Wanderer:
	var walker := Wanderer.new(grid, cell)
	walkers[colonist_id] = walker
	board.register(colonist_id, walker)
	return walker


func _tick(seconds: float) -> void:
	for walker in walkers.values():
		walker.advance(seconds)
	construction.advance(seconds)
	production.advance(seconds)
	construction.assign_builders()
	production.assign_producers()
	_assert_no_zombies()


func _run(total: float, step := 0.5) -> void:
	var left := total
	while left > 0.0:
		_tick(minf(step, left))
		left -= step


## Places `kind` and finishes it at once (what Construction does when its
## builders are done), so tests do not depend on who builds.
func _built(kind: FacilityCatalog.Kind, origin: Vector2i) -> Facility:
	var facility := construction.place(kind, origin)
	facility.built = true
	for cell in facility.cells():
		grid.set_blocked(cell, true)
	return facility


## A7: no production job is queued; <= 1 producer per facility; every producer's
## facility exists, is built and is not paused.
func _assert_no_zombies() -> void:
	var count := {}
	for colonist_id in walkers:
		var walker: Wanderer = walkers[colonist_id]
		for task in walker.tasks.queued():
			if task.producing:
				fail_test("production job in the queue of %d" % colonist_id)
		var task: Assignment = walker.tasks.current
		if task and task.producing:
			count[task.facility_id] = count.get(task.facility_id, 0) + 1
			var facility := construction.find(task.facility_id)
			if facility == null or not facility.built or facility.paused:
				fail_test("producer %d works a missing, unbuilt or paused facility" % colonist_id)
	for facility_id in count:
		if count[facility_id] > 1:
			fail_test("facility %d has %d producers" % [facility_id, count[facility_id]])


# --- A3: dispatch ---

func test_a_built_production_facility_gets_a_producer():
	var ann := _add(1, Vector2i(3, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	assert_eq(production.producer_of(bay.id), 1)
	assert_true(ann.tasks.current.producing)
	assert_true(ann.tasks.current.is_build())
	assert_eq(ann.tasks.current.priority, Production.DEFAULT_PRIORITY)


func test_the_nearest_colonist_goes():
	_add(1, Vector2i(2, 1))
	_add(2, Vector2i(7, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	assert_eq(production.producer_of(bay.id), 2)


func test_on_a_tie_the_first_to_join_goes():
	_add(1, Vector2i(6, 3))
	_add(2, Vector2i(6, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	assert_eq(production.producer_of(bay.id), 1)


func test_a_facility_never_gets_a_second_producer():
	_add(1, Vector2i(3, 3))
	_add(2, Vector2i(4, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	for i in 5:
		production.assign_producers()
	var holders := 0
	for walker in walkers.values():
		if walker.tasks.current and walker.tasks.current.producing:
			holders += 1
	assert_eq(holders, 1)
	assert_ne(production.producer_of(bay.id), -1)


func test_each_facility_gets_its_own_producer():
	_add(1, Vector2i(3, 3))
	_add(2, Vector2i(3, 5))
	var bay := _built(BAY, Vector2i(8, 1))
	var fab := _built(FAB, Vector2i(8, 5))
	production.assign_producers()
	assert_ne(production.producer_of(bay.id), -1)
	assert_ne(production.producer_of(fab.id), -1)
	assert_ne(production.producer_of(bay.id), production.producer_of(fab.id))


func test_the_most_urgent_facility_is_served_first():
	_add(1, Vector2i(3, 3))
	var bay := _built(BAY, Vector2i(8, 1))
	var fab := _built(FAB, Vector2i(8, 5))
	production.set_priority(fab.id, 4)
	production.assign_producers()
	assert_eq(production.producer_of(fab.id), 1)
	assert_eq(production.producer_of(bay.id), -1)


func test_on_equal_priority_the_smaller_id_goes_first():
	_add(1, Vector2i(3, 3))
	var bay := _built(BAY, Vector2i(8, 1))
	var fab := _built(FAB, Vector2i(8, 5))
	production.assign_producers()
	assert_eq(production.producer_of(bay.id), 1)
	assert_eq(production.producer_of(fab.id), -1)


func test_someone_busier_with_an_equal_or_more_urgent_task_is_not_taken():
	var ann := _add(1, Vector2i(3, 3))
	board.create(1, Vector2i(5, 5), 3)
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	assert_eq(production.producer_of(bay.id), -1)
	assert_eq(ann.tasks.current.priority, 3)


func test_a_blueprint_gets_no_production_job():
	_add(1, Vector2i(3, 3))
	var blueprint := construction.place(BAY, Vector2i(8, 3))
	production.assign_producers()
	assert_eq(production.producer_of(blueprint.id), -1)
	assert_false(walkers[1].tasks.current != null and walkers[1].tasks.current.producing)


func test_a_living_facility_gets_no_production_job():
	_add(1, Vector2i(3, 3))
	var pod := _built(POD, Vector2i(8, 3))
	production.assign_producers()
	assert_eq(production.producer_of(pod.id), -1)
	assert_null(walkers[1].tasks.current)


func test_a_walled_in_facility_gets_no_producer_and_no_error():
	_add(1, Vector2i(3, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	for cell in [Vector2i(7, 3), Vector2i(7, 4), Vector2i(10, 3), Vector2i(10, 4),
			Vector2i(8, 2), Vector2i(9, 2), Vector2i(8, 5), Vector2i(9, 5)]:
		grid.set_blocked(cell, true)
	production.assign_producers()
	assert_eq(production.producer_of(bay.id), -1)


func test_the_producer_does_not_stand_on_another_facility():
	_add(1, Vector2i(3, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	_built(FAB, Vector2i(10, 3))  # touches the bay's right side
	production.assign_producers()
	var cell: Vector2i = walkers[1].tasks.current.cell
	assert_null(construction.at(cell))
	assert_eq(production.producer_of(bay.id), 1)


# --- A3: output ---

func test_thirty_seconds_of_work_make_one_unit():
	_add(1, Vector2i(7, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	assert_almost_eq(UNIT, 30.0, 0.001)
	var food := stock.amount(Stockpile.Kind.FOOD)
	_run(UNIT - 1.0)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), food)
	assert_almost_eq(production.progress_of(bay.id), (UNIT - 1.0) / UNIT, 0.05)
	_run(2.0)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), food + 1)


func test_work_keeps_going_unit_after_unit():
	_add(1, Vector2i(7, 3))
	_built(BAY, Vector2i(8, 3))
	var food := stock.amount(Stockpile.Kind.FOOD)
	production.assign_producers()
	_run(UNIT * 3.0 + 1.0)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), food + 3)


func test_each_product_goes_to_its_own_stock():
	_add(1, Vector2i(3, 1))
	_add(2, Vector2i(3, 3))
	_add(3, Vector2i(3, 5))
	_built(BAY, Vector2i(8, 1))
	_built(RECYCLER, Vector2i(8, 3))
	_built(FAB, Vector2i(12, 5))
	var before := {}
	for kind in Stockpile.Kind.values():
		before[kind] = stock.amount(kind)
	_run(UNIT + 20.0)
	for kind in Stockpile.Kind.values():
		assert_eq(stock.amount(kind), before[kind] + 1, "kind %d" % kind)


func test_nothing_is_made_while_the_producer_is_still_walking():
	_add(1, Vector2i(1, 1))
	var bay := _built(BAY, Vector2i(14, 5))
	production.assign_producers()
	production.advance(5.0)
	assert_eq(production.progress_of(bay.id), 0.0)


func test_a_paused_game_makes_nothing():
	_add(1, Vector2i(7, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	_run(5.0)
	var before := production.progress_of(bay.id)
	production.advance(0.0)
	production.advance(-1.0)
	assert_eq(production.progress_of(bay.id), before)


func test_progress_is_kept_when_the_producer_leaves_and_comes_back():
	var ann := _add(1, Vector2i(7, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	_run(10.0)
	var kept := production.progress_of(bay.id)
	assert_gt(kept, 0.0)
	board.create(1, Vector2i(2, 5), 4)  # a 4-level order pulls them away
	_tick(0.1)
	assert_eq(production.producer_of(bay.id), -1)
	assert_eq(production.progress_of(bay.id), kept)
	_run(60.0)  # order done, they return to the job
	assert_eq(production.producer_of(bay.id), 1)
	assert_gt(production.progress_of(bay.id) + stock.amount(Stockpile.Kind.FOOD), kept)
	assert_not_null(ann)


# --- A4: priority, preemption, pause ---

func test_priority_can_be_changed_for_the_facility_and_its_producer():
	var ann := _add(1, Vector2i(7, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	assert_true(production.set_priority(bay.id, 4))
	assert_eq(bay.production_priority, 4)
	assert_eq(ann.tasks.current.priority, 4)
	assert_eq(production.producer_of(bay.id), 1)


func test_set_priority_refuses_bad_input():
	_add(1, Vector2i(7, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	var pod := _built(POD, Vector2i(12, 3))
	var blueprint := construction.place(FAB, Vector2i(8, 5))
	assert_false(production.set_priority(bay.id, 0))
	assert_false(production.set_priority(bay.id, 6))
	assert_false(production.set_priority(999, 3))
	assert_false(production.set_priority(pod.id, 3))
	assert_false(production.set_priority(blueprint.id, 3))
	assert_eq(bay.production_priority, Production.DEFAULT_PRIORITY)


func test_lowering_priority_below_a_waiting_task_makes_the_producer_drop_the_job():
	var ann := _add(1, Vector2i(7, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	production.set_priority(bay.id, 4)
	var order := board.create(1, Vector2i(2, 2), 3)  # waits behind the priority-4 job
	assert_eq(ann.tasks.next_priority(), 3)
	assert_eq(ann.tasks.current.facility_id, bay.id)
	assert_true(production.set_priority(bay.id, 2))
	assert_eq(ann.tasks.current.id, order.id, "the waiting order is now being done")
	assert_true(ann.tasks.queued().is_empty(), "the production job was dropped, not queued")
	assert_eq(production.producer_of(bay.id), -1)
	_assert_no_zombies()
	production.assign_producers()  # 2 < 3: the busy colonist does not take it back
	assert_eq(production.producer_of(bay.id), -1)
	_assert_no_zombies()


func test_changing_priority_with_nothing_more_urgent_waiting_keeps_the_producer():
	var ann := _add(1, Vector2i(7, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	board.create(1, Vector2i(2, 2), 1)  # waits, less urgent than any new priority below
	var job_id := ann.tasks.current.id
	for priority in [3, 5, 2]:
		assert_true(production.set_priority(bay.id, priority))
		assert_eq(production.producer_of(bay.id), 1)
		assert_eq(ann.tasks.current.id, job_id)
		assert_eq(ann.tasks.current.priority, priority)
		_assert_no_zombies()


func test_a_more_urgent_build_job_pulls_the_producer_away_and_is_not_queued():
	var ann := _add(1, Vector2i(7, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	var blueprint := construction.place(POD, Vector2i(3, 5))  # priority 3 > 2
	construction.assign_builders()
	assert_eq(ann.tasks.current.facility_id, blueprint.id)
	assert_eq(production.producer_of(bay.id), -1)
	assert_true(ann.tasks.queued().is_empty())
	_assert_no_zombies()


func test_after_the_preempting_job_the_facility_is_handed_out_again():
	var ann := _add(1, Vector2i(7, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	construction.place(POD, Vector2i(3, 5))
	_run(300.0)
	assert_eq(production.producer_of(bay.id), 1)
	assert_not_null(ann)


func test_pausing_releases_the_producer_and_nobody_takes_it():
	var ann := _add(1, Vector2i(7, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	assert_true(production.set_paused(bay.id, true))
	assert_eq(production.producer_of(bay.id), -1)
	assert_null(ann.tasks.current)
	production.assign_producers()
	assert_eq(production.producer_of(bay.id), -1)


func test_a_paused_facility_makes_nothing_and_keeps_its_progress():
	_add(1, Vector2i(7, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	_run(10.0)
	var kept := production.progress_of(bay.id)
	production.set_paused(bay.id, true)
	_run(20.0)
	assert_eq(production.progress_of(bay.id), kept)


func test_resuming_gets_a_producer_again():
	_add(1, Vector2i(7, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	production.set_paused(bay.id, true)
	production.set_paused(bay.id, false)
	production.assign_producers()
	assert_eq(production.producer_of(bay.id), 1)


func test_set_paused_refuses_unknown_and_non_production_ids():
	_add(1, Vector2i(7, 3))
	var pod := _built(POD, Vector2i(8, 3))
	assert_false(production.set_paused(999, true))
	assert_false(production.set_paused(pod.id, true))
	assert_false(pod.paused)


# --- A7: no zombie jobs ---

func test_demolishing_releases_the_producer_first():
	var ann := _add(1, Vector2i(7, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	_assert_no_zombies()
	assert_true(production.demolish(bay.id))
	_assert_no_zombies()
	assert_null(construction.find(bay.id))
	assert_null(ann.tasks.current)
	production.assign_producers()
	assert_null(ann.tasks.current)


func test_demolish_returns_false_for_an_unknown_id():
	assert_false(production.demolish(999))


func test_a_direct_construction_demolish_is_cleaned_up_by_assign_producers():
	var ann := _add(1, Vector2i(7, 3))
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	construction.demolish(bay.id)
	production.assign_producers()
	_assert_no_zombies()
	assert_null(ann.tasks.current)


func test_a_whole_scenario_leaves_no_zombies():
	var ann := _add(1, Vector2i(3, 3))
	_add(2, Vector2i(3, 5))
	var bay := _built(BAY, Vector2i(8, 3))
	_run(5.0)  # assign, produce
	construction.place(POD, Vector2i(3, 1))  # preempt
	_run(5.0)
	production.set_priority(bay.id, 5)  # change priority
	_run(5.0)
	production.set_paused(bay.id, true)  # pause
	_run(5.0)
	production.set_paused(bay.id, false)  # resume
	_run(5.0)
	board.create(1, Vector2i(2, 2), 5)  # a 5 order
	_run(5.0)
	production.demolish(bay.id)  # demolish
	_run(5.0)
	assert_not_null(ann)
