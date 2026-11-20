extends GutTest

# A2 (R3) of docs/specs/features/005-resources.md: supply points draw on the stockpile.

var grid: StationGrid
var board: AssignmentBoard
var points: SupplyPoints
var colony: Colony
var stock: Stockpile
var care: ColonistCare
var ann: Colonist
var walker: Wanderer


# Same hall as test_colonist_care; Ann starts standing on the food point.
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
	stock = Stockpile.new()
	care = ColonistCare.new(board, points, colony, stock)
	ann = colony.colonists[0]
	walker = _place(ann, Vector2i(2, 1))


func _place(colonist: Colonist, cell: Vector2i) -> Wanderer:
	var w := Wanderer.new(grid, cell)
	board.register(colonist.id, w)
	care.register(colonist, w)
	return w


func _supply_task(w: Wanderer, need: StringName) -> Assignment:
	var all := w.tasks.queued()
	if w.tasks.current:
		all.push_front(w.tasks.current)
	for task in all:
		if task.need == need:
			return task
	return null


# Hungry Ann asks, then (standing on the point) pays on the next advance.
func _ann_hungry_and_paid() -> void:
	ann.physiology.hunger = 10.0
	care.advance(0.0)
	care.advance(0.1)


func test_starting_the_refill_takes_one_food_and_finishing_fills_hunger():
	ann.physiology.hunger = 10.0
	care.advance(0.0)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 6, "asking alone costs nothing")
	care.advance(0.1)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 5, "paid on starting")
	care.advance(2.5)
	assert_eq(ann.physiology.hunger, Physiology.FULL)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 5, "not charged twice")


func test_pulled_away_halfway_refunds_the_food():
	_ann_hungry_and_paid()
	care.advance(0.5)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 5)
	var order := board.create(ann.id, Vector2i(10, 4), 4)
	care.advance(0.0)
	assert_not_null(order)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 6, "refunded")
	assert_true(_supply_task(walker, &"hunger").on_hold, "back in line on hold")


func test_a_player_cancelling_a_paid_supply_refunds_the_food():
	_ann_hungry_and_paid()
	var task := _supply_task(walker, &"hunger")
	assert_false(task.on_hold, "paid and under way")
	assert_true(board.cancel(task.id))
	care.advance(0.0)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 6, "refunded")


func test_a_resumed_supply_pays_again_exactly_once():
	_ann_hungry_and_paid()
	board.create(ann.id, Vector2i(3, 1), 4)
	care.advance(0.0)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 6)
	for i in 40:
		care.advance(0.25)
	assert_gt(ann.physiology.hunger, 90.0, "refilled, then fell a little")
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 5, "one portion for one refill")


func test_two_colonists_for_the_last_food_only_one_starts():
	var bo := colony.colonists[1]
	var bo_walker := _place(bo, Vector2i(2, 1))
	stock.take(Stockpile.Kind.FOOD, 5)
	ann.physiology.hunger = 10.0
	bo.physiology.hunger = 10.0
	care.advance(0.0)
	care.advance(0.1)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 0)
	assert_false(_supply_task(walker, &"hunger").on_hold, "first in order got it")
	assert_true(_supply_task(bo_walker, &"hunger").on_hold, "the other waits")
	for i in 20:
		care.advance(0.25)
	assert_gt(ann.physiology.hunger, 90.0, "refilled, then fell a little")
	assert_lt(bo.physiology.hunger, 10.0, "Bo never started")
	assert_true(bo_walker.is_at_task())


func test_with_no_food_the_colonist_waits_at_the_point_until_some_is_added():
	stock.take(Stockpile.Kind.FOOD, 6)
	ann.physiology.hunger = 10.0
	care.advance(0.0)
	var before := ann.physiology.hunger
	for i in 20:
		care.advance(0.5)
	assert_true(walker.is_at_task(), "still standing at the point")
	assert_lte(ann.physiology.hunger, before, "hunger does not recover")
	stock.add(Stockpile.Kind.FOOD, 1)
	care.advance(0.1)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 0)
	care.advance(2.5)
	assert_eq(ann.physiology.hunger, Physiology.FULL)


func test_waiting_for_food_counts_as_work_and_can_be_interrupted_by_a_4():
	stock.take(Stockpile.Kind.FOOD, 6)
	ann.physiology.hunger = 10.0
	care.advance(0.0)
	var stamina := ann.physiology.stamina
	care.advance(10.0)
	assert_lt(ann.physiology.stamina, stamina, "waiting is work for Stamina")
	var order := board.create(ann.id, Vector2i(10, 4), 4)
	assert_not_null(order)
	assert_eq(walker.tasks.current, order)
	care.advance(1.0)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 0, "nothing to refund or take")
	assert_true(_supply_task(walker, &"hunger").on_hold)


func test_incapacitation_refunds_a_paid_supply():
	_ann_hungry_and_paid()
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 5)
	ann.physiology.relief = 0.0
	care.advance(0.1)
	assert_true(ann.incapacitated)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 6)


# Death only comes through breaking down (003 R9): here both happen in the same
# advance, so this pins that path, not a separate "death" refund.
func test_breaking_down_and_dying_in_one_step_refunds_a_paid_supply():
	_ann_hungry_and_paid()
	ann.physiology.hunger = 0.0
	ann.physiology.thirst = 0.0
	var died := care.advance(0.1)
	assert_eq(died, [ann.id] as Array[int])
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 6)


func test_thirst_draws_on_water_the_same_way():
	walker = _place(ann, Vector2i(4, 1))
	ann.physiology.thirst = 10.0
	care.advance(0.0)
	care.advance(0.1)
	assert_eq(stock.amount(Stockpile.Kind.WATER), 7)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 6)
	care.advance(2.5)
	assert_eq(ann.physiology.thirst, Physiology.FULL)
	assert_eq(stock.amount(Stockpile.Kind.WATER), 7)


func test_empty_water_makes_the_colonist_wait():
	walker = _place(ann, Vector2i(4, 1))
	stock.take(Stockpile.Kind.WATER, 8)
	ann.physiology.thirst = 10.0
	care.advance(0.0)
	care.advance(5.0)
	assert_lt(ann.physiology.thirst, 10.0)
	stock.add(Stockpile.Kind.WATER, 1)
	care.advance(0.1)
	care.advance(2.5)
	assert_eq(ann.physiology.thirst, Physiology.FULL)


func test_relief_and_rest_never_touch_the_stock():
	walker = _place(ann, Vector2i(6, 1))
	ann.physiology.relief = 10.0
	care.advance(0.0)
	care.advance(3.0)
	assert_eq(ann.physiology.relief, Physiology.FULL)
	walker = _place(ann, Vector2i(8, 1))
	ann.physiology.stamina = 10.0
	care.advance(0.0)
	care.advance(1.0)
	for kind in [Stockpile.Kind.FOOD, Stockpile.Kind.WATER, Stockpile.Kind.MATERIALS]:
		assert_eq(stock.amount(kind), Stockpile.START[kind])


func test_without_a_stockpile_supplies_are_free_as_in_003():
	care = ColonistCare.new(board, points, colony)
	walker = _place(ann, Vector2i(2, 1))
	ann.physiology.hunger = 10.0
	care.advance(0.0)
	assert_false(_supply_task(walker, &"hunger").on_hold)
	care.advance(2.5)
	assert_eq(ann.physiology.hunger, Physiology.FULL)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 6)
