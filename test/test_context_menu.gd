extends GutTest

# T6 — right-click opens a context menu; "指派工作" opens the assignment submenu (A7, A9).

const MainScene := preload("res://scenes/main.tscn")

var main: Node
var context: Control
var assign: Control


func before_each():
	main = add_child_autofree(MainScene.instantiate())
	main.clock.paused = true
	context = main.get_node("Hud").get_node("%ContextMenu")
	assign = main.get_node("Hud").get_node("%AssignMenu")


func _click_cell(cell: Vector2i, button := MOUSE_BUTTON_RIGHT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = main.station_map.to_global(main.station_map.cell_to_pixel(Vector2(cell)))
	main._unhandled_input(event)


func _centre() -> Vector2i:
	return StationGrid.DEFAULT_HALL_SIZE / 2


func test_right_click_on_floor_opens_the_context_menu_only():
	_click_cell(_centre())
	assert_true(context.visible)
	assert_false(assign.visible, "the submenu waits for 指派工作")
	assert_eq(context.cell, _centre())


func test_context_menu_offers_assign_work():
	_click_cell(_centre())
	assert_eq(context.get_node("%AssignButton").text, "指派工作")


func test_choosing_assign_work_opens_the_submenu_for_that_cell():
	_click_cell(_centre())
	context.get_node("%AssignButton").pressed.emit()
	assert_false(context.visible)
	assert_true(assign.visible)
	assert_eq(assign.cell, _centre())


func test_no_context_menu_on_space():
	_click_cell(Vector2i(0, 0))
	assert_false(context.visible)
	assert_false(assign.visible)


func test_a_new_right_click_closes_an_open_submenu():
	_click_cell(_centre())
	context.get_node("%AssignButton").pressed.emit()
	_click_cell(_centre() + Vector2i(1, 0))
	assert_false(assign.visible)
	assert_true(context.visible)


func test_left_click_closes_both():
	_click_cell(_centre())
	_click_cell(_centre() + Vector2i(1, 0), MOUSE_BUTTON_LEFT)
	assert_false(context.visible)
	_click_cell(_centre())
	context.get_node("%AssignButton").pressed.emit()
	_click_cell(_centre() + Vector2i(1, 0), MOUSE_BUTTON_LEFT)
	assert_false(assign.visible)


func test_no_context_menu_on_a_wall():
	var wall := Vector2i(_centre().x, 0)
	while not main.grid.is_wall(wall):
		wall.y += 1
	_click_cell(wall)
	assert_false(context.visible)
