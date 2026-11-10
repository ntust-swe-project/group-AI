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
	return main.get_node("Hud").get_node("%InfoTasks").text


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
