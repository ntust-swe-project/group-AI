extends GutTest

# A11 of docs/specs/features/005-resources.md (R11, Q6): producing wears people
# out, so low-priority production stops at Stress 70 and only picks up people
# below 40. Priority 4-5 production, building and orders ignore the limits.

const BAY := FacilityCatalog.Kind.HYDROPONICS_BAY
const RECYCLER := FacilityCatalog.Kind.WATER_RECYCLER
const FAB := FacilityCatalog.Kind.FABRICATOR

var grid: StationGrid
var board: AssignmentBoard
var stock: Stockpile
var colony: Colony
var construction: Construction
var production: Production
var walkers := {}  # colonist id -> Wanderer


# One open room, cells 1..16 x 1..6; three colonists with ids 1..3.
func before_each():
	grid = StationGrid.new(Vector2i(18, 8))
	grid.add_room_rect(Rect2i(1, 1, 16, 6))
	board = AssignmentBoard.new(grid)
	stock = Stockpile.new()
	stock.add(Stockpile.Kind.MATERIALS, 100)
	colony = Colony.new()
	construction = Construction.new(grid, board, stock)
	production = Production.new(construction, board, grid, stock, colony)
	walkers = {}
	for colonist in colony.colonists:
		var walker := Wanderer.new(grid, Vector2i(3 + colonist.id, 3))
		walkers[colonist.id] = walker
		board.register(colonist.id, walker)


func _stress(colonist_id: int, value: float) -> void:
	colony.colonists[colonist_id - 1].psychology.stress = value


func _only(colonist_id: int) -> void:
	# Everyone else is too stressed to produce, so the answer is unambiguous.
	for colonist in colony.colonists:
		if colonist.id != colonist_id:
			colonist.psychology.stress = 95.0


func _built(kind: FacilityCatalog.Kind, origin: Vector2i) -> Facility:
	var facility := construction.place(kind, origin)
	facility.built = true
	for cell in facility.cells():
		grid.set_blocked(cell, true)
	return facility


func _tick(seconds: float) -> void:
	for walker in walkers.values():
		walker.advance(seconds)
	production.advance(seconds)
	production.assign_producers()
	for id in walkers:
		for task in walkers[id].tasks.queued():
			if task.producing:
				fail_test("production job in the queue of %d" % id)


func test_a_producer_who_reaches_the_limit_puts_the_job_down_unqueued():
	_only(1)
	_stress(1, 0.0)
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	assert_eq(production.producer_of(bay.id), 1)
	_stress(1, 70.0)
	_tick(0.1)
	assert_eq(production.producer_of(bay.id), -1)
	assert_true(walkers[1].tasks.queued().is_empty())
	assert_null(walkers[1].tasks.current)


func test_a_producer_below_the_limit_keeps_working():
	_only(1)
	_stress(1, 0.0)
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	_stress(1, 69.9)
	_tick(0.1)
	assert_eq(production.producer_of(bay.id), 1)


func test_a_producer_between_the_limits_keeps_working():
	_only(1)
	_stress(1, 0.0)
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	_stress(1, 55.0)
	for i in 5:
		_tick(0.1)
	assert_eq(production.producer_of(bay.id), 1)


func test_nobody_at_or_above_the_resume_line_is_sent_to_produce():
	var bay := _built(BAY, Vector2i(8, 3))
	for value in [40.0, 55.0, 69.0, 90.0]:
		_stress(1, value)
		_stress(2, 99.0)
		_stress(3, 99.0)
		production.assign_producers()
		assert_eq(production.producer_of(bay.id), -1, "stress %s" % value)


func test_someone_below_the_resume_line_is_sent():
	_only(1)
	_stress(1, 39.0)
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	assert_eq(production.producer_of(bay.id), 1)


func test_a_released_producer_is_not_picked_again_until_stress_is_below_40():
	_only(1)
	_stress(1, 0.0)
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	_stress(1, 70.0)
	_tick(0.1)
	assert_eq(production.producer_of(bay.id), -1)
	_stress(1, 50.0)  # cooled, but not enough
	_tick(0.1)
	assert_eq(production.producer_of(bay.id), -1)
	_stress(1, 39.9)
	_tick(0.1)
	assert_eq(production.producer_of(bay.id), 1)


func test_the_job_goes_to_a_rested_colonist_instead():
	_stress(1, 80.0)
	_stress(2, 10.0)
	_stress(3, 80.0)
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	assert_eq(production.producer_of(bay.id), 2)


func test_priority_4_and_5_facilities_ignore_both_limits():
	for priority in [4, 5]:
		var bay := _built(BAY, Vector2i(8, 3)) if priority == 4 else _built(RECYCLER, Vector2i(11, 3))
		assert_true(production.set_priority(bay.id, priority))
		_only(1)
		_stress(1, 90.0)  # the 3 colonists cannot all be excluded: 2 and 3 are 95
		production.assign_producers()
		assert_ne(production.producer_of(bay.id), -1, "assigned at priority %d" % priority)
		_tick(0.1)
		_tick(0.1)
		assert_ne(production.producer_of(bay.id), -1, "kept at priority %d" % priority)


func test_a_build_job_still_goes_to_a_stressed_colonist():
	_stress(1, 90.0)
	_stress(2, 90.0)
	_stress(3, 90.0)
	var blueprint := construction.place(BAY, Vector2i(8, 3))
	construction.assign_builders()
	assert_gt(construction.builders_of(blueprint.id).size(), 0)


func test_without_a_colony_stress_is_ignored():
	var plain := Production.new(construction, board, grid, stock)
	_stress(1, 99.0)
	_stress(2, 99.0)
	_stress(3, 99.0)
	var bay := _built(BAY, Vector2i(8, 3))
	plain.assign_producers()
	assert_ne(plain.producer_of(bay.id), -1)
	plain.assign_producers()
	assert_ne(plain.producer_of(bay.id), -1)


func test_a_colonist_missing_from_the_colony_is_not_a_candidate():
	_only(1)
	_stress(1, 0.0)
	colony.remove_colonist(1)
	var bay := _built(BAY, Vector2i(8, 3))
	production.assign_producers()
	assert_eq(production.producer_of(bay.id), -1)
