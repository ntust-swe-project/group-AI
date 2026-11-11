extends GutTest

# T7 — click a colonist to see their name (A9).

const MainScene := preload("res://scenes/main.tscn")

var main: Node
var panel: Control


func before_each():
	main = add_child_autofree(MainScene.instantiate())
	main.clock.paused = true  # keep colonists still while we click them
	panel = main.get_node("Hud").get_node("%InfoPanel")


func _click(map_point: Vector2, button := MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = main.station_map.to_global(map_point)
	main._unhandled_input(event)


func _first_view() -> Node2D:
	return main.get_tree().get_nodes_in_group("colonist_views")[0]


func test_panel_is_hidden_at_start():
	assert_false(panel.visible)


func test_clicking_a_colonist_shows_their_name():
	var view := _first_view()
	_click(view.position)
	assert_true(panel.visible)
	assert_eq(main.get_node("Hud").get_node("%InfoName").text, view.colonist.name)


func test_clicking_near_the_dot_still_counts():
	var view := _first_view()
	_click(view.position + Vector2(8, 0))
	assert_true(panel.visible)


func test_clicking_empty_floor_closes_the_panel():
	var view := _first_view()
	_click(view.position)
	_click(_empty_floor_point())
	assert_false(panel.visible)


func test_right_click_does_nothing():
	_click(_first_view().position, MOUSE_BUTTON_RIGHT)
	assert_false(panel.visible)


## A floor cell centre at least 3 cells from every colonist.
func _empty_floor_point() -> Vector2:
	var cell_size: float = main.station_map.CELL_SIZE
	for cell in main.grid.floor_cells():
		var point: Vector2 = main.station_map.cell_to_pixel(Vector2(cell))
		var clear := true
		for view in main.get_tree().get_nodes_in_group("colonist_views"):
			if view.position.distance_to(point) < cell_size * 3:
				clear = false
		if clear:
			return point
	fail_test("no empty floor found")
	return Vector2.ZERO


# feature 002 T5 — the panel lists what the colonist is doing (A10)

func _tasks_text() -> String:
	return main.get_node("Hud").info_tasks_text()


func _cancel_buttons() -> Array:
	return main.get_node("Hud").get_node("%InfoTasks").find_children("*", "Button", true, false)


func test_idle_colonist_shows_wandering_and_an_empty_queue():
	_click(_first_view().position)
	assert_string_contains(_tasks_text(), "閒晃")
	assert_string_contains(_tasks_text(), "排隊：無")


func test_panel_lists_current_then_queued_in_order():
	var view := _first_view()
	var id: int = view.colonist.id
	main.board.create(id, Vector2i(20, 12), 2)
	main.board.create(id, Vector2i(22, 12), 5)  # takes over
	main.board.create(id, Vector2i(24, 12), 1)
	_click(main.station_map.cell_to_pixel(main.wanderers[id].position()))
	gut.simulate(main, 1, 0.0)
	var text := _tasks_text()
	assert_string_contains(text, "(22, 12) · 優先度 5")
	var first_queued := text.find("(20, 12) · 優先度 2")
	var second_queued := text.find("(24, 12) · 優先度 1")
	assert_gt(first_queued, text.find("(22, 12)"), "current comes first")
	assert_gt(second_queued, first_queued, "queue is most urgent first")


func test_panel_follows_changes_while_open():
	var view := _first_view()
	var id: int = view.colonist.id
	_click(view.position)
	var task: Assignment = main.board.create(id, Vector2i(20, 12), 3)
	gut.simulate(main, 1, 0.0)
	assert_string_contains(_tasks_text(), "(20, 12)")
	main.board.cancel(task.id)
	gut.simulate(main, 1, 0.0)
	assert_string_contains(_tasks_text(), "閒晃")


# feature 002 T8 — cancel from the panel (A6, A10, I8)

func _busy_first_colonist() -> Colonist:
	var c: Colonist = _first_view().colonist
	main.board.create(c.id, Vector2i(22, 12), 5)
	main.board.create(c.id, Vector2i(20, 12), 2)
	_click(main.station_map.cell_to_pixel(main.wanderers[c.id].position()))
	gut.simulate(main, 1, 0.0)
	return c


func test_every_listed_task_has_a_cancel_button():
	_busy_first_colonist()
	assert_eq(_cancel_buttons().size(), 2)


func test_cancelling_the_current_task_starts_the_next_one():
	var c := _busy_first_colonist()
	_cancel_buttons()[0].pressed.emit()  # current: (22, 12)
	var tasks: TaskQueue = main.wanderers[c.id].tasks
	assert_eq(tasks.current.cell, Vector2i(20, 12))
	assert_eq(main.wanderers[c.id].destination(), Vector2i(20, 12), "rerouted at once")
	gut.simulate(main, 1, 0.0)
	assert_eq(_cancel_buttons().size(), 1)


func test_cancelling_a_queued_task_only_removes_it():
	var c := _busy_first_colonist()
	_cancel_buttons()[1].pressed.emit()  # queued: (20, 12)
	var tasks: TaskQueue = main.wanderers[c.id].tasks
	assert_eq(tasks.current.cell, Vector2i(22, 12))
	assert_eq(tasks.queued().size(), 0)


func test_buttons_are_not_rebuilt_while_nothing_changes():
	_busy_first_colonist()
	var button: Button = _cancel_buttons()[0]
	gut.simulate(main, 5, 0.0)
	assert_true(is_instance_valid(button) and button.is_inside_tree(), "same button, still clickable")


# --- feature 003 T6: needs in the panel (A9, A11, R5, R10, I7) ---

func _hud_label(unique_name: String) -> Label:
	return main.get_node("Hud").get_node("%" + unique_name)


func _lines(unique_name: String) -> PackedStringArray:
	return _hud_label(unique_name).text.split("\n")


func _show_first_colonist() -> Colonist:
	var view := _first_view()
	_click(view.position)
	return view.colonist


func test_body_and_mind_are_two_separate_sections():
	_show_first_colonist()
	assert_eq(_hud_label("InfoBodyTitle").text, "生理")
	assert_eq(_hud_label("InfoMindTitle").text, "心理")
	var body := _hud_label("InfoBody").text
	var mind := _hud_label("InfoMind").text
	for name in ["吃", "喝", "體溫", "排泄", "體力"]:
		assert_string_contains(body, name)
		assert_false(mind.contains(name), "%s belongs to the body only" % name)
	for name in ["壓力", "心情"]:
		assert_string_contains(mind, name)
		assert_false(body.contains(name), "%s belongs to the mind only" % name)


func test_a_new_colonist_shows_full_needs_and_no_stress():
	_show_first_colonist()
	assert_string_contains(_hud_label("InfoBody").text, "喝 100")
	assert_string_contains(_hud_label("InfoMind").text, "壓力 0")


func test_values_follow_the_clock():
	_show_first_colonist()
	main.clock.paused = false
	gut.simulate(main, 30, 1.0)  # 30 game seconds: thirst 100 -> 90
	assert_string_contains(_hud_label("InfoBody").text, "喝 90")


func test_values_hold_while_paused():
	_show_first_colonist()
	var before := _hud_label("InfoBody").text
	gut.simulate(main, 30, 1.0)
	assert_eq(_hud_label("InfoBody").text, before)


func test_the_incapacitated_are_marked():
	var c := _show_first_colonist()
	assert_false(_hud_label("InfoStatus").visible)
	c.physiology.relief = 0.0
	main.clock.paused = false
	gut.simulate(main, 1, 0.1)
	assert_true(_hud_label("InfoStatus").visible)
	assert_eq(_hud_label("InfoStatus").text, "失能")
	assert_false(_tasks_text().contains("閒晃"), "not wandering: cannot move")
	assert_string_contains(_tasks_text(), "失能")
	await get_tree().process_frame  # let the old task rows free before GUT counts orphans


func test_supply_work_is_listed_by_name():
	var c: Colonist = _first_view().colonist
	c.physiology.thirst = 10.0
	main.clock.paused = false
	gut.simulate(main, 1, 0.01)  # asks for water
	main.clock.paused = true
	_click(main.station_map.cell_to_pixel(main.wanderers[c.id].position()))
	gut.simulate(main, 1, 0.0)
	var text := _tasks_text()
	assert_string_contains(text, "前往水補給站 · 優先度 3")
	var water: Vector2i = main.points.cell_for(&"thirst")
	assert_false(text.contains("(%d, %d)" % [water.x, water.y]), "no cell for supply work")
	await get_tree().process_frame  # let the old task rows free before GUT counts orphans


func test_0_and_100_are_shown_only_when_really_reached():
	# They are where a colonist breaks down (R8), so the panel must not show them early.
	var c := _show_first_colonist()
	c.physiology.thirst = 0.4
	c.psychology.stress = 99.6
	gut.simulate(main, 1, 0.0)
	assert_has(_lines("InfoBody"), "喝 1")
	assert_has(_lines("InfoMind"), "壓力 99")
	await get_tree().process_frame  # let the old task rows free before GUT counts orphans


func test_just_under_30_is_not_shown_as_30():
	# Under 30 a need is already low and supplies are on the way (R6).
	var c := _show_first_colonist()
	c.physiology.thirst = 29.6
	gut.simulate(main, 1, 0.0)
	assert_has(_lines("InfoBody"), "喝 29")
	await get_tree().process_frame  # let the old task rows free before GUT counts orphans


func test_every_supply_point_has_a_name_for_the_queue():
	var names: Dictionary = main.get_node("Hud").SUPPLY_NAMES
	for need in SupplyPoints.NEEDS:
		assert_true(names.has(need), "%s has no name in the panel" % need)
