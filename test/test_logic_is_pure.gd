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
