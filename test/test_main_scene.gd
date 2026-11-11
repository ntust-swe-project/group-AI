extends GutTest

# Wiring of scenes/main.tscn (T4). What it looks like is checked by hand (A7).

const MainScene := preload("res://scenes/main.tscn")

var main: Node


func before_each():
	main = add_child_autofree(MainScene.instantiate())


func test_builds_the_default_hall():
	assert_eq(main.grid.size, StationGrid.DEFAULT_HALL_SIZE)
	assert_eq(main.grid.kind_of(Vector2i(0, 0)), StationGrid.Cell.SPACE)
	assert_true(main.grid.is_floor(StationGrid.DEFAULT_HALL_SIZE / 2))


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
	var start := {}
	for id in main.wanderers:
		start[id] = main.wanderers[id].position()
	# Check every frame: a colonist can walk away and back to its start cell.
	var moved := {}
	for frame in 30:
		gut.simulate(main, 1, 0.1)
		for id in main.wanderers:
			assert_true(main.grid.is_floor(main.wanderers[id].cell))
			if main.wanderers[id].position() != start[id]:
				moved[id] = true
	assert_eq(moved.size(), 3)


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


# --- feature 003 T5: needs on the map (A10, A11) ---

func _first_colonist() -> Colonist:
	return main.colony.colonists[0]


func _view_of(colonist: Colonist) -> Node2D:
	for view in _colonist_views():
		if view.colonist == colonist:
			return view
	return null


func _click(map_point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = main.station_map.to_global(map_point)
	main._unhandled_input(event)


func test_needs_change_while_time_runs():
	gut.simulate(main, 10, 0.1)
	assert_lt(_first_colonist().physiology.thirst, 100.0)


func test_needs_hold_while_paused():
	# Deferred from the T1 review: main.gd must pass 0 game seconds while paused.
	main.clock.paused = true
	gut.simulate(main, 30, 0.1)
	assert_eq(_first_colonist().physiology.thirst, 100.0)
	assert_eq(_first_colonist().physiology.hunger, 100.0)


func test_needs_follow_the_game_speed():
	main.clock.speed = 2.0
	gut.simulate(main, 10, 0.1)  # one real second at 2x
	var expected := Physiology.per_second(Physiology.THIRST_DAYS) * 2.0
	assert_almost_eq(100.0 - _first_colonist().physiology.thirst, expected, 0.001)


func test_a_colonist_added_later_is_looked_after_too():
	main.get_node("Hud").get_node("%AddColonistButton").pressed.emit()
	var added: Colonist = main.colony.colonists.back()
	added.physiology.thirst = 10.0
	gut.simulate(main, 1, 0.1)
	var task: Assignment = main.wanderers[added.id].tasks.current
	assert_not_null(task, "asked for water")
	assert_eq(task.need, &"thirst")


func test_the_map_marks_the_four_supply_points():
	var labels: Dictionary = main.station_map.supply_labels()
	assert_eq(labels.size(), 4)
	assert_eq(labels[main.points.cell_for(&"hunger")], "食")
	assert_eq(labels[main.points.cell_for(&"thirst")], "水")
	assert_eq(labels[main.points.cell_for(&"relief")], "廁")
	assert_eq(labels[main.points.cell_for(&"stamina")], "睡")


func test_an_incapacitated_colonist_is_drawn_grey():
	var ann := _first_colonist()
	var view := _view_of(ann)
	assert_eq(view.body_color(), view.BODY_COLOR)
	ann.physiology.relief = 0.0  # a body need only falls, so it stays at 0 while time runs
	gut.simulate(main, 1, 0.1)
	assert_true(ann.incapacitated)
	assert_eq(view.body_color(), view.INCAPACITATED_COLOR)
	assert_true(view._drawn_incapacitated, "the dot was redrawn, not just recoloured on paper")


func test_a_colonist_who_dies_leaves_the_map():
	var ann := _first_colonist()
	ann.physiology.hunger = 0.0
	ann.physiology.thirst = 0.0
	gut.simulate(main, 1, 0.1)
	assert_false(main.colony.colonists.has(ann))
	assert_false(main.wanderers.has(ann.id))
	assert_eq(_colonist_views().size(), 2)
	assert_null(_view_of(ann))
	await get_tree().process_frame  # let queue_free finish before GUT counts orphans


func test_the_info_panel_closes_when_the_shown_colonist_dies():
	main.clock.paused = true  # keep them still while clicking
	var ann := _first_colonist()
	_click(_view_of(ann).position)
	var panel: Control = main.get_node("Hud").get_node("%InfoPanel")
	assert_true(panel.visible)
	main.clock.paused = false
	ann.physiology.hunger = 0.0
	ann.physiology.thirst = 0.0
	gut.simulate(main, 1, 0.1)
	assert_false(panel.visible)
	assert_null(main.station_map._highlighted, "the map no longer follows the dead")
	await get_tree().process_frame  # let queue_free finish before GUT counts orphans


func test_open_menus_close_when_a_colonist_dies():
	main.context_menu.open(Vector2i(28, 15), Vector2(100, 100))
	var ann := _first_colonist()
	ann.physiology.hunger = 0.0
	ann.physiology.thirst = 0.0
	gut.simulate(main, 1, 0.1)
	assert_false(main.context_menu.visible)
	await get_tree().process_frame
