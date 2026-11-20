extends GutTest

# A1, A5 and A6 of docs/specs/features/005-resources.md: what facilities cost
# (R7), and the development level (R9).

const STALL := FacilityCatalog.Kind.HYGIENE_STALL
const POD := FacilityCatalog.Kind.SLEEP_POD
const BAY := FacilityCatalog.Kind.HYDROPONICS_BAY
const RECYCLER := FacilityCatalog.Kind.WATER_RECYCLER
const FABRICATOR := FacilityCatalog.Kind.FABRICATOR
const ONE_BUILDER := 0.2 * DayClock.SECONDS_PER_DAY

var grid: StationGrid
var board: AssignmentBoard
var stock: Stockpile
var construction: Construction
var walkers := {}


# One open room, cells 1..12 x 1..4.
func before_each():
	grid = StationGrid.new(Vector2i(14, 6))
	grid.add_room_rect(Rect2i(1, 1, 12, 4))
	board = AssignmentBoard.new(grid)
	stock = Stockpile.new()
	construction = Construction.new(grid, board, stock)
	walkers = {}
	_add(1, Vector2i(1, 4))  # the builder


func _add(colonist_id: int, cell: Vector2i) -> Wanderer:
	var walker := Wanderer.new(grid, cell)
	walkers[colonist_id] = walker
	board.register(colonist_id, walker)
	return walker


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


func _build(kind: FacilityCatalog.Kind, origin: Vector2i) -> Facility:
	var facility := construction.place(kind, origin)
	construction.assign_builders()
	_run(ONE_BUILDER + 30.0)  # the build, plus the walk to it
	return facility


func _materials() -> int:
	return stock.amount(Stockpile.Kind.MATERIALS)


# --- catalog (R4, Q2) ---

func test_the_production_category_lists_the_three_facilities():
	assert_eq(FacilityCatalog.CATEGORIES, ["生活", "生產"] as Array[String])
	assert_eq(FacilityCatalog.kinds_in("生產"), [BAY, RECYCLER, FABRICATOR] as Array[FacilityCatalog.Kind])


func test_production_facility_names_sizes_and_build_time():
	assert_eq(FacilityCatalog.display_name(BAY), "水耕艙")
	assert_eq(FacilityCatalog.display_name(RECYCLER), "水回收機")
	assert_eq(FacilityCatalog.display_name(FABRICATOR), "製造站")
	for kind in [BAY, RECYCLER, FABRICATOR]:
		assert_eq(FacilityCatalog.size_of(kind), Vector2i(2, 2))
		assert_almost_eq(FacilityCatalog.build_seconds(kind), ONE_BUILDER, 0.001)


func test_costs():
	assert_eq(FacilityCatalog.cost_of(STALL), 5)
	assert_eq(FacilityCatalog.cost_of(POD), 10)
	assert_eq(FacilityCatalog.cost_of(BAY), 10)
	assert_eq(FacilityCatalog.cost_of(RECYCLER), 10)
	assert_eq(FacilityCatalog.cost_of(FABRICATOR), 10)


func test_products():
	assert_eq(FacilityCatalog.product_of(BAY), Stockpile.Kind.FOOD)
	assert_eq(FacilityCatalog.product_of(RECYCLER), Stockpile.Kind.WATER)
	assert_eq(FacilityCatalog.product_of(FABRICATOR), Stockpile.Kind.MATERIALS)
	assert_eq(FacilityCatalog.product_of(STALL), -1)
	assert_eq(FacilityCatalog.product_of(POD), -1)


# --- A1 ---

func test_a_new_game_has_development_level_zero():
	assert_eq(construction.development_level(), 0)


# --- A5: paying ---

func test_placing_takes_the_cost():
	construction.place(BAY, Vector2i(2, 2))
	assert_eq(_materials(), 20)


func test_cancelling_a_blueprint_refunds_everything():
	var bay := construction.place(BAY, Vector2i(2, 2))
	assert_true(construction.cancel(bay.id))
	assert_eq(_materials(), 30)


func test_demolishing_refunds_nothing():
	var stall := _build(STALL, Vector2i(5, 2))
	assert_eq(_materials(), 25)
	assert_true(construction.demolish(stall.id))
	assert_eq(_materials(), 25)


func test_placing_fails_without_enough_materials_and_changes_nothing():
	stock.take(Stockpile.Kind.MATERIALS, 25)  # 5 left
	assert_false(construction.can_afford(POD))
	assert_false(construction.can_place(POD, Vector2i(2, 2)), "the ghost turns invalid")
	assert_null(construction.place(POD, Vector2i(2, 2)))
	assert_eq(_materials(), 5)
	assert_eq(construction.blueprints().size(), 0)


func test_exactly_enough_materials_is_enough():
	stock.take(Stockpile.Kind.MATERIALS, 25)
	assert_true(construction.can_afford(STALL))
	assert_not_null(construction.place(STALL, Vector2i(2, 2)))
	assert_eq(_materials(), 0)


func test_placing_until_the_materials_run_out_stops_placement():
	# 30 materials = three 10-material facilities.
	for i in 3:
		assert_not_null(construction.place(BAY, Vector2i(1 + i * 3, 1)), "placement %d" % i)
	assert_eq(_materials(), 0)
	assert_false(construction.can_place(RECYCLER, Vector2i(1, 3)))
	assert_null(construction.place(RECYCLER, Vector2i(1, 3)))
	assert_eq(_materials(), 0)


func test_a_refund_lets_you_place_again():
	for i in 3:
		construction.place(BAY, Vector2i(1 + i * 3, 1))
	var last := construction.blueprints()[2]
	construction.cancel(last.id)
	assert_true(construction.can_place(RECYCLER, Vector2i(1, 3)))


func test_a_blocked_cell_still_costs_nothing():
	construction.place(STALL, Vector2i(2, 2))
	assert_null(construction.place(POD, Vector2i(2, 2)))
	assert_eq(_materials(), 25, "only the first one was paid for")


func test_without_a_stockpile_everything_is_free():
	var free := Construction.new(grid, board)
	assert_true(free.can_afford(BAY))
	assert_not_null(free.place(BAY, Vector2i(2, 2)))
	assert_eq(_materials(), 30)


# --- A6: development level ---

func test_a_blueprint_does_not_count():
	construction.place(BAY, Vector2i(2, 2))
	assert_eq(construction.development_level(), 0)


func test_a_finished_facility_adds_its_cost():
	_build(STALL, Vector2i(5, 2))
	assert_eq(construction.development_level(), 5)


func test_development_level_sums_all_finished_facilities():
	_build(STALL, Vector2i(5, 2))
	_build(BAY, Vector2i(7, 2))
	assert_eq(construction.development_level(), 15)


func test_demolishing_lowers_the_level_again():
	var stall := _build(STALL, Vector2i(5, 2))
	var bay := _build(BAY, Vector2i(7, 2))
	construction.demolish(stall.id)
	assert_eq(construction.development_level(), 10)
	construction.demolish(bay.id)
	assert_eq(construction.development_level(), 0)
