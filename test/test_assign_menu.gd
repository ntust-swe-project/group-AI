extends GutTest

# T4 — assignment menu (A7 first half, A9 wiring); reached through the context menu since T6.

const MainScene := preload("res://scenes/main.tscn")

var main: Node
var menu: Control


func before_each():
	main = add_child_autofree(MainScene.instantiate())
	main.clock.paused = true
	menu = main.get_node("Hud").get_node("%AssignMenu")


func _click_cell(cell: Vector2i, button := MOUSE_BUTTON_RIGHT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = main.station_map.to_global(main.station_map.cell_to_pixel(Vector2(cell)))
	main._unhandled_input(event)
	# Right-click opens the context menu; the assignment menu is its submenu (T6).
	var context: Control = main.get_node("Hud").get_node("%ContextMenu")
	if button == MOUSE_BUTTON_RIGHT and context.visible:
		context.get_node("%AssignButton").pressed.emit()


func _centre() -> Vector2i:
	return StationGrid.DEFAULT_HALL_SIZE / 2


func _pick(path: String, index: int) -> void:
	var picker: OptionButton = menu.get_node(path)
	picker.select(index)


func test_menu_is_hidden_at_start():
	assert_false(menu.visible)


func test_right_click_on_floor_opens_the_menu_for_that_cell():
	_click_cell(_centre())
	assert_true(menu.visible)
	assert_eq(menu.cell, _centre())


func test_right_click_on_space_or_wall_does_not_open_it():
	_click_cell(Vector2i(0, 0))  # space
	assert_false(menu.visible)
	var wall := Vector2i(_centre().x, 0)
	while not main.grid.is_wall(wall):
		wall.y += 1
	_click_cell(wall)
	assert_false(menu.visible)


func test_menu_lists_every_colonist_and_priorities_one_to_five():
	_click_cell(_centre())
	var people: OptionButton = menu.get_node("%ColonistPicker")
	var levels: OptionButton = menu.get_node("%PriorityPicker")
	assert_eq(people.item_count, main.colony.colonists.size())
	assert_eq(levels.item_count, 5)
	assert_eq(levels.get_item_id(0), 1)
	assert_eq(levels.get_item_id(4), 5)


func test_executing_assigns_the_chosen_colonist_and_closes():
	_click_cell(_centre())
	_pick("%ColonistPicker", 1)
	_pick("%PriorityPicker", 4)  # priority 5
	menu.get_node("%ExecuteButton").pressed.emit()
	var chosen: Colonist = main.colony.colonists[1]
	var task: Assignment = main.wanderers[chosen.id].tasks.current
	assert_not_null(task)
	assert_eq(task.cell, _centre())
	assert_eq(task.priority, 5)
	assert_eq(main.wanderers[chosen.id].destination(), _centre(), "route set at once (SC4)")
	assert_false(menu.visible)


func test_menu_lists_the_cells_assignments_and_can_cancel_them():
	var chosen: Colonist = main.colony.colonists[0]
	main.board.create(chosen.id, _centre(), 3)
	_click_cell(_centre())
	var buttons: Array = menu.get_node("%ExistingList").find_children("*", "Button", true, false)
	assert_eq(buttons.size(), 1)
	buttons[0].pressed.emit()
	assert_eq(main.board.at(_centre()).size(), 0)
	assert_null(main.wanderers[chosen.id].tasks.current)


func test_close_button_and_left_click_close_the_menu():
	_click_cell(_centre())
	menu.get_node("%CloseButton").pressed.emit()
	assert_false(menu.visible)
	_click_cell(_centre())
	_click_cell(_centre() + Vector2i(1, 0), MOUSE_BUTTON_LEFT)
	assert_false(menu.visible)


func test_added_colonists_show_up_in_the_menu():
	main.get_node("Hud").get_node("%AddColonistButton").pressed.emit()
	_click_cell(_centre())
	assert_eq(menu.get_node("%ColonistPicker").item_count, 4)


func test_finished_assignments_drop_off_the_open_menu():
	var chosen: Colonist = main.colony.colonists[0]
	var walker: Wanderer = main.wanderers[chosen.id]
	main.board.create(chosen.id, walker.cell, 3)  # where they stand: only the work time left
	_click_cell(walker.cell)
	assert_eq(menu.get_node("%ExistingList").get_child_count(), 1)
	main.clock.paused = false
	gut.simulate(main, 1, Wanderer.WORK_SECONDS + 0.1)
	assert_eq(menu.get_node("%ExistingList").get_child_count(), 0)


func test_adding_a_colonist_closes_the_menu():
	_click_cell(_centre())
	main.get_node("Hud").get_node("%AddColonistButton").pressed.emit()
	assert_false(menu.visible)
