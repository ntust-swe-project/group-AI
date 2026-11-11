extends GutTest

# A3 (wiring), A4, A5, A6, A7 of docs/specs/features/003-colonist-needs.md

var grid: StationGrid
var board: AssignmentBoard
var points: SupplyPoints
var colony: Colony
var care: ColonistCare
var ann: Colonist
var walker: Wanderer


# One room (cells 1..12 x 1..4) with the four supply points along its top row.
func before_each():
	grid = StationGrid.new(Vector2i(14, 6))
	grid.add_room_rect(Rect2i(1, 1, 12, 4))
	board = AssignmentBoard.new(grid)
	points = SupplyPoints.new({
		&"hunger": Vector2i(2, 1),
		&"thirst": Vector2i(4, 1),
		&"relief": Vector2i(6, 1),
		&"stamina": Vector2i(8, 1),
	})
	colony = Colony.new()
	care = ColonistCare.new(board, points, colony)
	ann = colony.colonists[0]
	_place_ann(Vector2i(11, 4))


func _place_ann(cell: Vector2i) -> void:
	walker = Wanderer.new(grid, cell)
	board.register(ann.id, walker)
	care.register(ann, walker)


func _tasks() -> Array[Assignment]:
	var all := walker.tasks.queued()
	if walker.tasks.current:
		all.push_front(walker.tasks.current)
	return all


func _supply_tasks(need: StringName) -> Array[Assignment]:
	return _tasks().filter(func(task): return task.need == need)


# --- A4: asking for supplies (R6) ---

func test_a_need_dropping_under_30_asks_for_supplies_in_the_same_advance():
	ann.physiology.thirst = 30.05
	care.advance(1.0)
	var asked := _supply_tasks(&"thirst")
	assert_eq(asked.size(), 1)
	assert_eq(asked[0].priority, 3)
	assert_eq(asked[0].cell, points.cell_for(&"thirst"))


func test_each_need_goes_to_its_own_point():
	for need in SupplyPoints.NEEDS:
		before_each()
		ann.physiology.set(need, 10.0)
		care.advance(0.0)
		assert_eq(_tasks().size(), 1, need)
		assert_eq(_supply_tasks(need).size(), 1, need)
		assert_eq(_supply_tasks(need)[0].cell, points.cell_for(need), need)


func test_exactly_30_does_not_ask():
	ann.physiology.thirst = 30.0
	care.advance(0.0)
	assert_eq(_tasks().size(), 0)


func test_body_temp_and_the_mind_never_ask_for_supplies():
	ann.physiology.body_temp = 10.0
	ann.psychology.mood = 10.0
	ann.psychology.stress = 90.0
	care.advance(0.0)
	assert_eq(_tasks().size(), 0)


func test_the_same_need_is_not_asked_twice():
	ann.physiology.thirst = 10.0
	for i in 10:
		care.advance(0.1)
	assert_eq(_supply_tasks(&"thirst").size(), 1)


func test_two_low_needs_ask_for_two_supplies():
	ann.physiology.thirst = 10.0
	ann.physiology.hunger = 10.0
	care.advance(0.0)
	assert_eq(_supply_tasks(&"thirst").size(), 1)
	assert_eq(_supply_tasks(&"hunger").size(), 1)


func test_an_urgent_order_takes_over_supplies_but_a_routine_one_does_not():
	ann.physiology.thirst = 10.0
	care.advance(0.0)
	var supply := walker.tasks.current
	assert_eq(supply.need, &"thirst")
	board.create(ann.id, Vector2i(10, 3), 2)
	assert_same(walker.tasks.current, supply, "priority 2 waits")
	var urgent := board.create(ann.id, Vector2i(10, 3), 4)
	assert_same(walker.tasks.current, urgent, "priority 4 cuts in")


# --- A5: refilling (R7) ---

func test_supplies_refill_the_need_after_two_seconds_at_the_point():
	_place_ann(points.cell_for(&"thirst"))
	ann.physiology.thirst = 20.0
	care.advance(0.0)
	care.advance(1.9)
	assert_lt(ann.physiology.thirst, 30.0, "not yet")
	assert_eq(_supply_tasks(&"thirst").size(), 1)
	care.advance(0.2)
	assert_eq(ann.physiology.thirst, 100.0)
	assert_eq(_supply_tasks(&"thirst").size(), 0, "done and gone")


func test_a_full_sleep_takes_60_seconds_and_refills_stamina():
	_place_ann(points.cell_for(&"stamina"))
	ann.physiology.stamina = 20.0
	care.advance(0.0)
	care.advance(59.0)
	assert_eq(ann.physiology.stamina, 20.0, "asleep: neither falls nor refills yet")
	care.advance(1.1)
	assert_eq(ann.physiology.stamina, 100.0)
	assert_eq(_supply_tasks(&"stamina").size(), 0, "done and gone")


func test_a_cancelled_supply_does_not_refill():
	_place_ann(points.cell_for(&"thirst"))
	ann.physiology.thirst = 20.0
	care.advance(0.0)
	board.cancel(walker.tasks.current.id)
	care.advance(3.0)
	assert_lt(ann.physiology.thirst, 30.0)


# --- A3 wiring: what counts as working, on an order, a low body (R3, R4) ---

func test_stamina_falls_on_the_way_to_the_pod():
	ann.physiology.stamina = 20.0
	care.advance(0.0)
	care.advance(1.0)
	assert_lt(ann.physiology.stamina, 20.0)


func test_stamina_falls_while_waiting_at_the_water_point():
	_place_ann(points.cell_for(&"thirst"))
	ann.physiology.thirst = 20.0
	care.advance(0.0)
	care.advance(1.0)
	assert_lt(ann.physiology.stamina, 100.0)


func test_stamina_holds_while_idle():
	care.advance(30.0)
	assert_eq(ann.physiology.stamina, 100.0)


func test_a_player_order_raises_stress():
	board.create(ann.id, Vector2i(1, 4), 1)
	care.advance(1.0)
	assert_gt(ann.psychology.stress, 0.0)


func test_supply_work_alone_does_not_raise_stress():
	ann.physiology.thirst = 20.0
	care.advance(0.0)
	care.advance(1.0)
	assert_eq(ann.psychology.stress, 0.0)


func test_mood_falls_while_a_body_need_is_low():
	ann.physiology.body_temp = 10.0  # low, and no supply point fixes it
	care.advance(1.0)
	assert_lt(ann.psychology.mood, 100.0)


# --- the four supply points (R7, Q5, Q11) ---

func test_the_hall_points_are_floor():
	var hall := StationGrid.make_hall()
	var hall_points := SupplyPoints.new()
	for need in SupplyPoints.NEEDS:
		assert_true(hall.is_floor(hall_points.cell_for(need)), need)


func test_the_hall_points_are_four_different_cells():
	var hall_points := SupplyPoints.new()
	var cells := {}
	for need in SupplyPoints.NEEDS:
		cells[hall_points.cell_for(need)] = true
	assert_eq(cells.size(), 4)


func test_only_the_sleep_pod_takes_60_seconds():
	for need in SupplyPoints.NEEDS:
		var expected := 60.0 if need == &"stamina" else Wanderer.WORK_SECONDS
		assert_eq(points.work_seconds(need), expected, need)


# --- A6: incapacitation (R8) ---

const DAY := DayClock.SECONDS_PER_DAY


func test_any_body_need_at_zero_incapacitates():
	for need in [&"hunger", &"thirst", &"body_temp", &"relief", &"stamina"]:
		before_each()
		ann.physiology.set(need, 0.0)
		care.advance(0.0)
		assert_true(ann.incapacitated, need)


func test_stress_at_100_incapacitates():
	ann.psychology.stress = 100.0
	care.advance(0.0)
	assert_true(ann.incapacitated)


func test_mood_at_0_incapacitates():
	ann.psychology.mood = 0.0
	care.advance(0.0)
	assert_true(ann.incapacitated)


func test_needs_short_of_the_ends_do_not_incapacitate():
	ann.physiology.thirst = 0.5
	ann.psychology.stress = 99.5
	ann.psychology.mood = 0.5
	care.advance(0.0)
	assert_false(ann.incapacitated)


func test_every_way_of_breaking_down_has_the_same_consequences():
	# A6: each of the three conditions, then all four consequences.
	var ways := {
		"a body need at 0": func(): ann.physiology.relief = 0.0,
		"stress at 100": func(): ann.psychology.stress = 100.0,
		"mood at 0": func(): ann.psychology.mood = 0.0,
	}
	for way in ways:
		before_each()
		board.create(ann.id, Vector2i(1, 1), 3)
		board.create(ann.id, Vector2i(1, 4), 1)
		care.advance(0.3)  # mid-step on the way
		ways[way].call()
		care.advance(0.0)
		var where := walker.position()
		care.advance(5.0)
		assert_true(ann.incapacitated, way)
		assert_eq(walker.position(), where, "%s: stops moving" % way)
		assert_eq(_tasks().size(), 0, "%s: every task cancelled" % way)
		assert_null(board.create(ann.id, Vector2i(3, 3), 5), "%s: no new orders" % way)
		assert_false(board.who_can_reach(Vector2i(3, 3)).has(ann.id), "%s: not listed" % way)


func test_a_need_reaching_zero_incapacitates_in_that_advance():
	ann.physiology.thirst = 0.1
	care.advance(1.0)
	assert_true(ann.incapacitated)


func test_the_incapacitated_stop_moving():
	board.create(ann.id, Vector2i(1, 1), 3)
	care.advance(0.3)  # mid-step on the way
	ann.psychology.stress = 100.0
	care.advance(0.0)
	var where := walker.position()
	care.advance(5.0)
	assert_eq(walker.position(), where)


func test_incapacitation_cancels_every_task():
	board.create(ann.id, Vector2i(1, 1), 3)
	board.create(ann.id, Vector2i(1, 4), 1)
	ann.psychology.stress = 100.0
	care.advance(0.0)
	assert_eq(_tasks().size(), 0)


func test_the_incapacitated_cannot_be_given_orders():
	ann.psychology.stress = 100.0
	care.advance(0.0)
	assert_null(board.create(ann.id, Vector2i(3, 3), 5))
	assert_false(board.who_can_reach(Vector2i(3, 3)).has(ann.id))


func test_the_incapacitated_do_not_ask_for_supplies():
	ann.psychology.stress = 100.0
	ann.physiology.thirst = 10.0
	care.advance(0.0)
	care.advance(1.0)
	assert_eq(_tasks().size(), 0)


func test_incapacitation_does_not_wear_off():
	ann.psychology.stress = 100.0
	care.advance(0.0)
	care.advance(30.0)
	assert_lt(ann.psychology.stress, 100.0, "stress eases off without orders")
	assert_true(ann.incapacitated, "but the colonist stays incapacitated (Q9)")


func test_needs_keep_falling_while_incapacitated():
	ann.psychology.stress = 100.0
	care.advance(0.0)
	care.advance(10.0)
	assert_lt(ann.physiology.thirst, 100.0)


# --- A7: death (R9) ---

func test_only_hunger_at_zero_is_not_death():
	ann.physiology.hunger = 0.0
	assert_eq(care.advance(0.0).size(), 0)
	assert_true(colony.colonists.has(ann))


func test_only_thirst_at_zero_is_not_death():
	ann.physiology.thirst = 0.0
	assert_eq(care.advance(0.0).size(), 0)
	assert_true(colony.colonists.has(ann))


func test_hunger_and_thirst_at_zero_is_death_and_only_for_that_colonist():
	var bo := colony.colonists[1]
	var bo_walker := Wanderer.new(grid, Vector2i(5, 3))
	board.register(bo.id, bo_walker)
	care.register(bo, bo_walker)
	ann.physiology.hunger = 0.0
	ann.physiology.thirst = 0.0
	var died := care.advance(0.0)
	assert_eq(died.size(), 1)
	assert_eq(died[0], ann.id)
	assert_false(colony.colonists.has(ann))
	assert_true(colony.colonists.has(bo))
	assert_false(bo.incapacitated)
	assert_true(board.who_can_reach(Vector2i(3, 3)).has(bo.id), "Bo can still be given orders")


func test_an_incapacitated_colonist_dies_once_hunger_and_thirst_run_out():
	ann.psychology.stress = 100.0
	care.advance(0.0)
	care.advance(DAY)  # thirst is out, hunger has a third left
	assert_true(colony.colonists.has(ann))
	var died := care.advance(DAY)
	assert_eq(died.size(), 1)
	assert_false(colony.colonists.has(ann))


func test_removing_an_unknown_colonist_changes_nothing():
	var before := colony.colonists.size()
	assert_false(colony.remove_colonist(999))
	assert_eq(colony.colonists.size(), before)


func test_the_dead_are_no_longer_looked_after():
	ann.physiology.hunger = 0.0
	ann.physiology.thirst = 0.0
	care.advance(0.0)
	assert_eq(care.advance(1.0).size(), 0, "not reported twice")
	assert_false(board.who_can_reach(Vector2i(3, 3)).has(ann.id))
