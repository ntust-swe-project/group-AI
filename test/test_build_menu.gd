extends GutTest

# A9 of docs/specs/features/004-construction.md (wiring): the build menu in
# the bottom-right corner, and placing blueprints with the mouse.

const MainScene := preload("res://scenes/main.tscn")
const STALL := FacilityCatalog.Kind.HYGIENE_STALL
const POD := FacilityCatalog.Kind.SLEEP_POD

var main: Node
var menu: Control


func before_each():
	main = add_child_autofree(MainScene.instantiate())
	main.clock.paused = true
	menu = main.get_node("Hud").get_node("%BuildMenu")


func _cell_event(event: InputEvent, cell: Vector2i) -> void:
	event.position = main.station_map.to_global(main.station_map.cell_to_pixel(Vector2(cell)))
	main._unhandled_input(event)


func _move_to(cell: Vector2i) -> void:
	_cell_event(InputEventMouseMotion.new(), cell)


func _click(cell: Vector2i, button := MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	_cell_event(event, cell)


func _press_escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	main._unhandled_input(event)


func _button(list: Control, text: String) -> Button:
	for button in list.get_children():
		if button is Button and button.text == text:
			return button
	return null


func _texts(list: Control) -> Array[String]:
	var texts: Array[String] = []
	for button in list.get_children():
		if button is Button and button.visible:
			texts.append(button.text)
	return texts


func _choose(kind_text: String) -> void:
	menu.get_node("%BuildButton").pressed.emit()
	_button(menu.get_node("%CategoryList"), "生活").pressed.emit()
	_button(menu.get_node("%KindList"), kind_text).pressed.emit()


## Near the middle of the hall, but below it: the very middle is feature 003's
## water point, where nothing may be built (003 R12).
func _centre() -> Vector2i:
	return StationGrid.DEFAULT_HALL_SIZE / 2 + Vector2i(0, 4)


func _a_wall_cell() -> Vector2i:
	var cell := Vector2i(_centre().x, 0)
	while not main.grid.is_wall(cell):
		cell.y += 1
	return cell


# --- the menu (R1) ---

func test_the_menu_sits_in_the_bottom_right_corner():
	var screen: Vector2 = main.get_viewport_rect().size
	var rect: Rect2 = menu.get_node("%BuildButton").get_global_rect()
	assert_gt(rect.position.x, screen.x * 0.8)
	assert_gt(rect.position.y, screen.y * 0.85)
	assert_lte(rect.end.x, screen.x)
	assert_lte(rect.end.y, screen.y)


func test_only_the_build_button_shows_at_start():
	assert_eq(menu.get_node("%BuildButton").text, "建造")
	assert_false(menu.get_node("%CategoryList").visible)
	assert_false(menu.get_node("%KindList").visible)


func test_build_opens_the_categories_and_a_category_its_facilities():
	menu.get_node("%BuildButton").pressed.emit()
	assert_true(menu.get_node("%CategoryList").visible)
	assert_eq(_texts(menu.get_node("%CategoryList")), ["生活"] as Array[String])
	assert_false(menu.get_node("%KindList").visible)
	_button(menu.get_node("%CategoryList"), "生活").pressed.emit()
	assert_true(menu.get_node("%KindList").visible)
	assert_eq(_texts(menu.get_node("%KindList")), ["衛生艙", "睡眠艙"] as Array[String])


func test_the_lists_open_above_and_left_of_the_build_button():
	menu.get_node("%BuildButton").pressed.emit()
	_button(menu.get_node("%CategoryList"), "生活").pressed.emit()
	await get_tree().process_frame  # let the containers lay out
	assert_gt(menu.get_node("%CategoryList").size.y, 0.0)
	assert_gt(menu.get_node("%KindList").size.y, 0.0)
	var screen: Vector2 = main.get_viewport_rect().size
	var build: Rect2 = menu.get_node("%BuildButton").get_global_rect()
	var category: Rect2 = menu.get_node("%CategoryList").get_global_rect()
	var kinds: Rect2 = menu.get_node("%KindList").get_global_rect()
	assert_lte(category.end.y, build.position.y + 1.0, "categories above 建造")
	assert_lte(kinds.end.x, category.position.x + 1.0, "facilities to the left")
	assert_gte(category.position.y, 0.0, "still on screen")
	assert_lte(kinds.end.y, screen.y)


func test_build_again_closes_everything():
	menu.get_node("%BuildButton").pressed.emit()
	_button(menu.get_node("%CategoryList"), "生活").pressed.emit()
	menu.get_node("%BuildButton").pressed.emit()
	assert_false(menu.get_node("%CategoryList").visible)
	assert_false(menu.get_node("%KindList").visible)


# --- placing (R2, R3) ---

func test_choosing_a_facility_starts_placing_it_and_folds_the_menu():
	_choose("睡眠艙")
	assert_eq(main.placing_kind(), POD)
	assert_false(menu.get_node("%CategoryList").visible)


func test_the_ghost_follows_the_mouse_and_says_if_it_fits():
	_choose("衛生艙")
	_move_to(_centre())
	var ghost: Dictionary = main.station_map.ghost()
	assert_eq(ghost.kind, STALL)
	assert_eq(ghost.cell, _centre())
	assert_true(ghost.valid)
	_move_to(_a_wall_cell())
	assert_false(main.station_map.ghost().valid)


func test_no_ghost_when_not_placing():
	_move_to(_centre())
	assert_true(main.station_map.ghost().is_empty())


func test_left_click_places_a_blueprint_and_keeps_placing():
	_choose("衛生艙")
	_click(_centre())
	_click(_centre() + Vector2i(3, 0))
	assert_eq(main.construction.blueprints().size(), 2)
	assert_eq(main.placing_kind(), STALL)


func test_clicking_a_colonist_while_placing_does_not_select_them():
	var walker: Wanderer = main.wanderers.values()[0]
	_choose("衛生艙")
	_click(walker.cell)
	assert_false(main.get_node("Hud").get_node("%InfoPanel").visible)
	assert_eq(main.station_map.marked_cells().size(), 0)


func test_left_click_on_a_wall_places_nothing():
	_choose("衛生艙")
	_click(_a_wall_cell())
	assert_eq(main.construction.blueprints().size(), 0)


func test_escape_stops_placing():
	_choose("衛生艙")
	_move_to(_centre())
	_press_escape()
	assert_eq(main.placing_kind(), -1)
	assert_true(main.station_map.ghost().is_empty())
	_click(_centre())
	assert_eq(main.construction.blueprints().size(), 0)


func test_right_click_stops_placing_without_opening_the_context_menu():
	_choose("衛生艙")
	_click(_centre(), MOUSE_BUTTON_RIGHT)
	assert_eq(main.placing_kind(), -1)
	assert_false(main.get_node("Hud").get_node("%ContextMenu").visible)
	_click(_centre(), MOUSE_BUTTON_RIGHT)
	assert_true(main.get_node("Hud").get_node("%ContextMenu").visible, "back to normal")


func test_colonists_take_the_job_while_the_game_runs():
	_choose("衛生艙")
	_click(_centre())
	var stall: Facility = main.construction.blueprints()[0]
	main.clock.paused = false
	main._process(0.1)
	assert_gt(main.construction.builders_of(stall.id).size(), 0)


func test_nothing_is_built_while_paused():
	var walker: Wanderer = main.wanderers.values()[0]
	var spot: Vector2i = walker.cell + Vector2i.RIGHT
	if not main.construction.can_place(STALL, spot):
		spot = walker.cell + Vector2i.LEFT
	var stall: Facility = main.construction.place(STALL, spot)
	assert_not_null(stall, "a free cell beside the first colonist")
	for i in 3:
		main._process(5.0)  # paused since before_each
	assert_eq(main.construction.progress_of(stall.id), 0.0)
	main.clock.paused = false
	for i in 3:
		main._process(1.0)
	assert_gt(main.construction.progress_of(stall.id), 0.0)


func test_build_menu_and_right_click_menu_never_show_together():
	_click(_centre(), MOUSE_BUTTON_RIGHT)
	menu.get_node("%BuildButton").pressed.emit()
	assert_false(main.get_node("Hud").get_node("%ContextMenu").visible, "建造 closes the right-click menu")
	_click(_centre() + Vector2i(1, 0))
	assert_false(menu.get_node("%CategoryList").visible, "a click on the map folds the build menu")
