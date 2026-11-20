extends GutTest

# A11 of docs/specs/features/005-resources.md: with main's wiring, three
# colonists who build the three production facilities and then produce for
# three game days must not be incapacitated by Stress (R11, Q6).

const FACILITIES: Array[FacilityCatalog.Kind] = [
	FacilityCatalog.Kind.HYDROPONICS_BAY,
	FacilityCatalog.Kind.WATER_RECYCLER,
	FacilityCatalog.Kind.FABRICATOR,
]
const STEP := 0.1  # game seconds per frame
const DAYS := 3
const MIN_WORK_SECONDS := 60.0  # two units of work; a regression where nobody produces gives 0

var grid: StationGrid
var colony: Colony
var board: AssignmentBoard
var stockpile: Stockpile
var care: ColonistCare
var construction: Construction
var production: Production
var _rng := RandomNumberGenerator.new()


# The same objects, in the same order, as scenes/main.gd.
func _build_world(seed_value: int) -> void:
	_rng.seed = seed_value
	grid = StationGrid.make_hall()
	colony = Colony.new()
	board = AssignmentBoard.new(grid)
	var points := SupplyPoints.new()
	stockpile = Stockpile.new()
	care = ColonistCare.new(board, points, colony, stockpile)
	construction = Construction.new(grid, board, stockpile)
	production = Production.new(construction, board, grid, stockpile, colony)
	construction.reserve_cells(points.cells())
	var floor_cells := grid.walkable_cells()
	for colonist in colony.colonists:
		var walker := Wanderer.new(grid, floor_cells[_rng.randi() % floor_cells.size()], _rng)
		board.register(colonist.id, walker)
		care.register(colonist, walker)


func _place_all() -> Array[Facility]:
	var placed: Array[Facility] = []
	for kind in FACILITIES:
		for cell in grid.walkable_cells():
			if construction.can_place(kind, cell):
				placed.append(construction.place(kind, cell))
				break
	return placed


func _run_simulation(seed_value: int) -> void:
	_build_world(seed_value)
	var placed := _place_all()
	assert_eq(placed.size(), 3, "all three facilities could be placed")
	var max_stress := 0.0
	var last_progress := {}  # facility id -> output_done at the previous step
	var worked := {}  # facility id -> seconds of production work seen
	var steps := int(DAYS * DayClock.SECONDS_PER_DAY / STEP)
	for i in steps:
		# main._process: care (moves everyone), then construction, then production.
		care.advance(STEP)
		construction.advance(STEP)
		construction.assign_builders()
		production.advance(STEP)
		production.assign_producers()
		for colonist in colony.colonists:
			max_stress = maxf(max_stress, colonist.psychology.stress)
		for facility in placed:
			var now := facility.output_done
			var delta: float = now - last_progress.get(facility.id, 0.0)
			# One step is far shorter than a unit, so at most one unit rolls over.
			worked[facility.id] = worked.get(facility.id, 0.0) + (delta if delta >= 0.0 else delta + Production.SECONDS_PER_UNIT)
			last_progress[facility.id] = now
	for facility in placed:
		assert_true(facility.built, "%s was built" % FacilityCatalog.display_name(facility.kind))
	assert_eq(colony.colonists.size(), 3, "everyone is alive")
	for colonist in colony.colonists:
		assert_false(colonist.incapacitated, "%s is not incapacitated" % colonist.name)
	for facility in placed:
		var seconds: float = worked.get(facility.id, 0.0)
		gut.p("%s worked %.1f s" % [FacilityCatalog.display_name(facility.kind), seconds])
		assert_gt(seconds, MIN_WORK_SECONDS, "%s really produced" % FacilityCatalog.display_name(facility.kind))
	assert_lt(max_stress, 100.0, "nobody's Stress ever filled up")
	gut.p("max Stress seen (seed %d): %.1f" % [seed_value, max_stress])


func test_three_colonists_survive_three_days_of_production():
	_run_simulation(1)


func test_another_seed_survives_too():
	_run_simulation(20260)
