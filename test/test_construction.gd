extends GutTest

# A1 and A7 of docs/specs/features/004-construction.md: placing and cancelling
# blueprints. Building, assignment of builders and demolishing come in T2-T4.

const STALL := FacilityCatalog.Kind.HYGIENE_STALL
const POD := FacilityCatalog.Kind.SLEEP_POD

var grid: StationGrid
var board: AssignmentBoard
var construction: Construction


# Room A (cells 1..6 x 1..4), joined to room B (cells 9..12 x 1..4) by a
# one-cell corridor at y = 2 (cells 7..8).
func before_each():
	grid = StationGrid.new(Vector2i(14, 6))
	grid.add_room_rect(Rect2i(1, 1, 6, 4))
	grid.add_room_rect(Rect2i(9, 1, 4, 4))
	grid.add_room_rect(Rect2i(7, 2, 2, 1))
	board = AssignmentBoard.new(grid)
	construction = Construction.new(grid, board)


func _cells(list: Array) -> Array[Vector2i]:
	var typed: Array[Vector2i] = []
	typed.assign(list)
	return typed


# --- catalog (R1, Q1) ---

func test_the_living_category_has_both_facilities():
	assert_eq(FacilityCatalog.CATEGORIES, ["生活"] as Array[String])
	assert_eq(FacilityCatalog.kinds_in("生活"), [STALL, POD] as Array[FacilityCatalog.Kind])


func test_facility_names_and_sizes():
	assert_eq(FacilityCatalog.display_name(STALL), "衛生艙")
	assert_eq(FacilityCatalog.display_name(POD), "睡眠艙")
	assert_eq(FacilityCatalog.size_of(STALL), Vector2i(1, 1))
	assert_eq(FacilityCatalog.size_of(POD), Vector2i(1, 2))


# --- A7: a new game ---

func test_a_new_game_has_no_facilities():
	assert_eq(construction.blueprints().size(), 0)
	assert_eq(construction.facilities().size(), 0)


# --- A1: placing ---

func test_placing_on_floor_makes_an_unbuilt_blueprint():
	var stall := construction.place(STALL, Vector2i(2, 2))
	assert_not_null(stall)
	assert_eq(stall.kind, STALL)
	assert_false(stall.built)
	assert_eq(stall.cells(), _cells([Vector2i(2, 2)]))
	assert_eq(construction.blueprints(), [stall] as Array[Facility])
	assert_same(construction.at(Vector2i(2, 2)), stall)


func test_a_sleep_pod_takes_two_cells():
	var pod := construction.place(POD, Vector2i(2, 2))
	assert_eq(pod.cells(), _cells([Vector2i(2, 2), Vector2i(2, 3)]))
	assert_same(construction.at(Vector2i(2, 3)), pod)


func test_ids_are_unique_and_grow():
	var a := construction.place(STALL, Vector2i(2, 2))
	var b := construction.place(STALL, Vector2i(4, 2))
	assert_lt(a.id, b.id)


func test_cannot_place_on_wall_or_outside():
	for cell in [Vector2i(0, 0), Vector2i(0, 2), Vector2i(7, 1), Vector2i(-1, 2), Vector2i(40, 40)]:
		assert_false(construction.can_place(STALL, cell), "should not place at %s" % cell)
		assert_null(construction.place(STALL, cell))
	assert_eq(construction.blueprints().size(), 0)


func test_cannot_place_on_space_inside_the_grid():
	var roomy := StationGrid.new(Vector2i(8, 8))
	roomy.add_room_rect(Rect2i(3, 3, 2, 2))
	var here := Construction.new(roomy, AssignmentBoard.new(roomy))
	assert_eq(roomy.kind_of(Vector2i(0, 0)), StationGrid.Cell.SPACE)
	assert_null(here.place(STALL, Vector2i(0, 0)))
	assert_not_null(here.place(STALL, Vector2i(3, 3)), "the room itself is fine")


func test_cannot_place_on_a_built_facility():
	var stall := construction.place(STALL, Vector2i(2, 2))
	stall.built = true  # finishing a build is T3; fake it here
	grid.set_blocked(Vector2i(2, 2), true)
	assert_null(construction.place(STALL, Vector2i(2, 2)))
	assert_null(construction.place(POD, Vector2i(2, 1)), "its second cell is the facility")
	assert_eq(construction.facilities(), [stall] as Array[Facility])


func test_cannot_place_a_pod_hanging_over_the_wall():
	assert_null(construction.place(POD, Vector2i(2, 4)), "its second cell (2, 5) is wall")


func test_cannot_place_over_another_blueprint():
	construction.place(POD, Vector2i(2, 2))
	assert_null(construction.place(STALL, Vector2i(2, 3)))
	assert_null(construction.place(POD, Vector2i(2, 1)), "overlaps at (2, 2)")


func test_cannot_place_on_a_cell_with_an_assignment():
	board.register(1, Wanderer.new(grid, Vector2i(1, 1)))
	board.create(1, Vector2i(3, 3), 1)
	assert_null(construction.place(STALL, Vector2i(3, 3)))
	assert_null(construction.place(POD, Vector2i(3, 2)), "its second cell has the assignment")


func test_cannot_place_where_it_would_cut_the_station_in_two():
	assert_null(construction.place(STALL, Vector2i(7, 2)), "the corridor is the only way through")


func test_a_pod_across_a_two_row_corridor_cuts_the_station_in_two():
	grid.add_room_rect(Rect2i(7, 3, 2, 1))  # widen the corridor to two rows
	assert_null(construction.place(POD, Vector2i(7, 2)), "covers (7, 2) and (7, 3)")
	assert_not_null(construction.place(STALL, Vector2i(7, 2)), "one cell leaves the lower row open")


func test_blueprints_already_placed_count_as_blocking():
	grid.add_room_rect(Rect2i(7, 3, 2, 1))  # widen the corridor to two rows
	assert_not_null(construction.place(STALL, Vector2i(7, 2)))
	assert_null(construction.place(STALL, Vector2i(8, 3)), "with (7, 2) taken this closes the corridor")


func test_a_blueprint_does_not_block_walking_yet():
	construction.place(POD, Vector2i(3, 1))
	var path := grid.find_path(Vector2i(2, 1), Vector2i(4, 1))
	assert_eq(path.size(), 3, "walks straight over the blueprint")


# --- cancelling a blueprint ---

func test_cancelling_removes_the_blueprint_and_frees_its_cells():
	var pod := construction.place(POD, Vector2i(2, 2))
	assert_true(construction.cancel(pod.id))
	assert_eq(construction.blueprints().size(), 0)
	assert_null(construction.at(Vector2i(2, 3)))
	assert_not_null(construction.place(STALL, Vector2i(2, 3)))


func test_cancelling_an_unknown_id_changes_nothing():
	construction.place(STALL, Vector2i(2, 2))
	assert_false(construction.cancel(999))
	assert_eq(construction.blueprints().size(), 1)
