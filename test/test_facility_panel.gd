extends GutTest

# A10 of docs/specs/features/004-construction.md (wiring): blueprints and
# facilities on the map, the info panel's facility section, and build jobs in
# a colonist's list without a cancel button (R4, R7, R8).

const MainScene := preload("res://scenes/main.tscn")
const STALL := FacilityCatalog.Kind.HYGIENE_STALL

var main: Node
var hud: CanvasLayer


func before_each():
	main = add_child_autofree(MainScene.instantiate())
	main.clock.paused = true
	hud = main.get_node("Hud")


func _click(cell: Vector2i) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = main.station_map.to_global(main.station_map.cell_to_pixel(Vector2(cell)))
	main._unhandled_input(event)


## A floor cell at least 3 cells from every colonist, where a stall fits.
func _free_spot() -> Vector2i:
	for cell in main.grid.walkable_cells():
		var clear := true
		for walker in main.wanderers.values():
			if Vector2(walker.cell).distance_to(Vector2(cell)) < 3.0:
				clear = false
		if clear and main.construction.can_place(STALL, cell):
			return cell
	fail_test("no free spot")
	return Vector2i.ZERO


## Finishing a build takes 0.2 game days; fake it the way Construction does.
func _finish(facility: Facility) -> void:
	facility.built = true
	for cell in facility.cells():
		main.grid.set_blocked(cell, true)


func _priority_picker() -> OptionButton:
	return hud.get_node("%FacilityPriority")


# --- the map ---

func test_the_map_draws_blueprints_and_facilities():
	var stall: Facility = main.construction.place(STALL, _free_spot())
	assert_eq(main.station_map.drawn_facilities(), [{"id": stall.id, "built": false}])
	_finish(stall)
	assert_eq(main.station_map.drawn_facilities(), [{"id": stall.id, "built": true}])


# --- a blueprint in the panel (R4) ---

func test_clicking_a_blueprint_shows_it_with_priority_and_cancel():
	var spot := _free_spot()
	main.construction.place(STALL, spot)
	_click(spot)
	assert_true(hud.get_node("%InfoPanel").visible)
	assert_eq(hud.get_node("%InfoTitle").text, "藍圖")
	assert_eq(hud.get_node("%InfoName").text, "衛生艙")
	assert_eq(_priority_picker().get_selected_id(), 3)
	assert_true(hud.get_node("%FacilityCancel").visible)
	assert_false(hud.get_node("%FacilityDemolish").visible)
	assert_false(hud.get_node("%InfoTasks").visible, "no colonist task list")


func test_changing_the_priority_in_the_panel():
	var spot := _free_spot()
	var stall: Facility = main.construction.place(STALL, spot)
	_click(spot)
	var picker := _priority_picker()
	picker.select(picker.get_item_index(5))
	picker.item_selected.emit(picker.get_item_index(5))
	assert_eq(main.construction.priority_of(stall.id), 5)


func test_cancelling_from_the_panel_removes_the_blueprint():
	var spot := _free_spot()
	main.construction.place(STALL, spot)
	_click(spot)
	hud.get_node("%FacilityCancel").pressed.emit()
	assert_eq(main.construction.blueprints().size(), 0)
	assert_false(hud.get_node("%InfoPanel").visible)


func test_the_panel_follows_build_progress():
	var spot := _free_spot()
	var stall: Facility = main.construction.place(STALL, spot)
	_click(spot)
	assert_string_contains(hud.get_node("%FacilityState").text, "0%")
	stall.work_done = FacilityCatalog.build_seconds(STALL) * 0.25
	hud._process(0.0)
	assert_string_contains(hud.get_node("%FacilityState").text, "25%")


func test_the_panel_closes_when_the_blueprint_goes_away_elsewhere():
	var spot := _free_spot()
	var stall: Facility = main.construction.place(STALL, spot)
	_click(spot)
	main.construction.cancel(stall.id)
	hud._process(0.0)
	assert_false(hud.get_node("%InfoPanel").visible)


func test_the_map_redraws_when_a_blueprint_is_placed():
	main.station_map._process(0.0)
	var before: Array = main.station_map._drawn.duplicate()
	main.construction.place(STALL, _free_spot())
	main.station_map._process(0.0)
	assert_ne(main.station_map._drawn, before, "the drawn list was refreshed")


# --- a facility in the panel (R8) ---

func test_a_finished_facility_offers_demolish_only():
	var spot := _free_spot()
	var stall: Facility = main.construction.place(STALL, spot)
	_finish(stall)
	_click(spot)
	assert_eq(hud.get_node("%InfoTitle").text, "設施")
	assert_true(hud.get_node("%FacilityDemolish").visible)
	assert_false(hud.get_node("%FacilityCancel").visible)
	assert_false(hud.get_node("%PriorityRow").visible)


func test_demolishing_from_the_panel_frees_the_cell():
	var spot := _free_spot()
	var stall: Facility = main.construction.place(STALL, spot)
	_finish(stall)
	_click(spot)
	hud.get_node("%FacilityDemolish").pressed.emit()
	assert_eq(main.construction.facilities().size(), 0)
	assert_true(main.grid.is_walkable(spot))
	assert_false(hud.get_node("%InfoPanel").visible)


func test_the_panel_switches_when_the_blueprint_is_finished():
	var spot := _free_spot()
	var stall: Facility = main.construction.place(STALL, spot)
	_click(spot)
	_finish(stall)
	hud._process(0.0)
	assert_eq(hud.get_node("%InfoTitle").text, "設施")
	assert_true(hud.get_node("%FacilityDemolish").visible)


func test_clicking_a_colonist_after_a_facility_shows_the_colonist():
	var spot := _free_spot()
	main.construction.place(STALL, spot)
	_click(spot)
	var walker: Wanderer = main.wanderers.values()[0]
	_click(walker.cell)
	assert_eq(hud.get_node("%InfoTitle").text, "殖民者")
	assert_true(hud.get_node("%InfoTasks").visible)
	assert_false(hud.get_node("%FacilityBox").visible)


# --- build jobs in a colonist's list (R8) ---

func test_a_build_job_is_listed_without_a_cancel_button():
	var walker: Wanderer = main.wanderers.values()[0]
	var colonist_id: int = main.wanderers.keys()[0]
	main.board.create(colonist_id, walker.cell, 1)  # an ordinary errand, to compare
	var placed: Facility = null
	for offset in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2), Vector2i(2, 2), Vector2i(-2, -2)]:
		placed = main.construction.place(STALL, walker.cell + offset)
		if placed:
			break
	assert_not_null(placed, "a stall two cells from the colonist")
	main.construction.set_priority(main.construction.blueprints()[0].id, 5)
	main.construction.assign_builders()
	assert_true(walker.tasks.current.is_build())
	_click(walker.cell)
	hud._process(0.0)
	assert_string_contains(hud.info_tasks_text(), "建造 衛生艙")
	var buttons: Array = hud.get_node("%InfoTasks").find_children("*", "Button", true, false)
	assert_eq(buttons.size(), 1, "only the errand can be cancelled")


# --- R9 / A7: new colonists ---

func test_new_colonists_never_start_inside_a_facility():
	# Block all floor but a handful of cells (as if covered by facilities), so a
	# spawn that ignored blocking would land in one almost every time.
	var open: Array = main.grid.walkable_cells().slice(0, 5)
	for cell in main.grid.floor_cells():
		if not open.has(cell):
			main.grid.set_blocked(cell, true)
	for i in 10:
		main._on_add_colonist_requested()
	for walker in main.wanderers.values().slice(3):
		assert_has(open, walker.cell)


func test_a_new_game_has_no_facilities():
	assert_eq(main.construction.blueprints().size(), 0)
	assert_eq(main.construction.facilities().size(), 0)
