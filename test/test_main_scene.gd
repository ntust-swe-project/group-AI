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
