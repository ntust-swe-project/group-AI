extends GutTest

# Wiring of scenes/main.tscn (T4). What it looks like is checked by hand (A7).

const MainScene := preload("res://scenes/main.tscn")

var main: Node


func before_each():
	main = add_child_autofree(MainScene.instantiate())


func test_builds_the_default_hall():
	assert_eq(main.grid.size, StationGrid.DEFAULT_HALL_SIZE)
	assert_true(main.grid.is_wall(Vector2i(0, 0)))
	assert_false(main.grid.is_wall(Vector2i(1, 1)))


func test_map_draws_the_same_grid():
	assert_same(main.get_node("StationMap").grid, main.grid)


func test_time_moves_every_frame():
	gut.simulate(main, 1, DayClock.SECONDS_PER_DAY)
	assert_eq(main.clock.day, 2)


func test_main_scene_is_the_project_main_scene():
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/main.tscn")


# T5 — colonists on the map (A7)

func _colonist_views() -> Array:
	return main.get_tree().get_nodes_in_group("colonist_views")


func test_shows_one_view_per_colonist():
	assert_eq(_colonist_views().size(), 3)


func test_colonists_start_on_different_floor_cells():
	var cells := {}
	for walker in main.wanderers.values():
		assert_true(main.grid.is_floor(walker.cell))
		cells[walker.cell] = true
	assert_eq(cells.size(), 3)


func test_colonists_walk_while_time_runs_and_stay_on_floor():
	var before := {}
	for id in main.wanderers:
		before[id] = main.wanderers[id].position()
	gut.simulate(main, 30, 0.1)
	var moved := 0
	for id in main.wanderers:
		assert_true(main.grid.is_floor(main.wanderers[id].cell))
		if main.wanderers[id].position() != before[id]:
			moved += 1
	assert_eq(moved, 3)


func test_colonists_freeze_while_paused():
	main.clock.paused = true
	var before := {}
	for id in main.wanderers:
		before[id] = main.wanderers[id].position()
	gut.simulate(main, 30, 0.1)
	for id in main.wanderers:
		assert_eq(main.wanderers[id].position(), before[id])


func test_view_sits_on_its_colonist():
	gut.simulate(main, 7, 0.1)
	for view in _colonist_views():
		var walker: Wanderer = main.wanderers[view.colonist.id]
		var expected: Vector2 = (walker.position() + Vector2(0.5, 0.5)) * main.station_map.CELL_SIZE
		assert_almost_eq(view.position, expected, Vector2(0.01, 0.01))
