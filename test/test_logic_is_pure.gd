extends GutTest

# A6 of docs/specs/features/001-base-skeleton.md (SYSTEM.md S1): logic classes
# must run without the scene tree, so none of them may be a Node.
# Held as Variant: with a static type, GDScript rejects `is Node` at parse time.


func _assert_pure(instance: Variant) -> void:
	assert_false(instance is Node)
	assert_true(instance is RefCounted)


func test_day_clock_is_not_a_node():
	_assert_pure(DayClock.new())


func test_colony_is_not_a_node():
	_assert_pure(Colony.new())


func test_colonist_is_not_a_node():
	_assert_pure(Colonist.new(1, "Ann"))


func test_station_grid_is_not_a_node():
	_assert_pure(StationGrid.new(Vector2i(3, 3)))


func test_feature_002_classes_are_not_nodes():
	_assert_pure(Assignment.new(1, Vector2i.ZERO, 1))
	_assert_pure(TaskQueue.new())
	_assert_pure(AssignmentBoard.new(StationGrid.new(Vector2i(3, 3))))
	_assert_pure(Wanderer.new(StationGrid.new(Vector2i(3, 3)), Vector2i.ZERO))


func test_feature_003_classes_are_not_nodes():
	# A8 of docs/specs/features/003-colonist-needs.md
	var grid := StationGrid.new(Vector2i(3, 3))
	_assert_pure(Physiology.new())
	_assert_pure(Psychology.new())
	_assert_pure(SupplyPoints.new())
	_assert_pure(ColonistCare.new(AssignmentBoard.new(grid), SupplyPoints.new(), Colony.new()))


func test_feature_004_classes_are_not_nodes():
	var grid := StationGrid.new(Vector2i(3, 3))
	_assert_pure(FacilityCatalog.new())
	_assert_pure(Facility.new(1, FacilityCatalog.Kind.HYGIENE_STALL, Vector2i.ZERO))
	_assert_pure(Construction.new(grid, AssignmentBoard.new(grid)))
