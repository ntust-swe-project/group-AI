extends GutTest

# A9, A10 of docs/specs/features/005-resources.md (wiring): the resource bar,
# costs in the build menu, the production section of the facility panel and
# production jobs in a colonist's list (R2, R4, R6, R8).

const MainScene := preload("res://scenes/main.tscn")
const FARM := FacilityCatalog.Kind.HYDROPONICS_BAY
const RECYCLER := FacilityCatalog.Kind.WATER_RECYCLER
const STATION := FacilityCatalog.Kind.FABRICATOR

var main: Node
var hud: CanvasLayer
var menu: Control


func before_each():
	main = add_child_autofree(MainScene.instantiate())
	main.clock.paused = true
	hud = main.get_node("Hud")
	menu = hud.get_node("%BuildMenu")


func _click(cell: Vector2i) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = main.station_map.to_global(main.station_map.cell_to_pixel(Vector2(cell)))
	main._unhandled_input(event)


func _spot(kind: FacilityCatalog.Kind) -> Vector2i:
	for cell in main.grid.walkable_cells():
		var clear := true
		for walker in main.wanderers.values():
			if Vector2(walker.cell).distance_to(Vector2(cell)) < 3.0:
				clear = false
		if clear and main.construction.can_place(kind, cell):
			return cell
	fail_test("no free spot")
	return Vector2i.ZERO


func _finish(facility: Facility) -> void:
	facility.built = true
	for cell in facility.cells():
		main.grid.set_blocked(cell, true)


## A finished farm and its click, with the panel showing it.
func _open_farm() -> Facility:
	var spot := _spot(FARM)
	var farm: Facility = main.construction.place(FARM, spot)
	_finish(farm)
	_click(spot)
	return farm


func _button(list: Control, text: String) -> Button:
	for button in list.get_children():
		if button is Button and button.text == text:
			return button
	return null


func _open_production_list() -> void:
	menu.get_node("%BuildButton").pressed.emit()
	_button(menu.get_node("%CategoryList"), "生產").pressed.emit()


func _label() -> String:
	return hud.get_node("%ResourceLabel").text


# --- resource bar (R2) ---

func test_the_resource_bar_shows_the_start_amounts():
	hud._process(0.0)
	assert_eq(_label(), "食物 6　水 8　材料 30　發展 0")


func test_placing_a_blueprint_lowers_the_materials():
	var cost := FacilityCatalog.cost_of(FARM)
	main.construction.place(FARM, _spot(FARM))
	hud._process(0.0)
	assert_eq(_label(), "食物 6　水 8　材料 %d　發展 0" % (30 - cost))


func test_a_finished_facility_raises_the_development_level():
	_open_farm()
	hud._process(0.0)
	assert_string_contains(_label(), "發展 1")


# --- build menu (R4, R8) ---

func test_the_production_category_lists_facilities_with_costs():
	_open_production_list()
	var texts: Array[String] = []
	for button in menu.get_node("%KindList").get_children():
		texts.append(button.text)
	assert_eq(texts, ["水耕艙（10）", "水回收機（10）", "製造站（10）"] as Array[String])


func test_an_unaffordable_facility_is_disabled_and_follows_the_stock():
	_open_production_list()
	var button := _button(menu.get_node("%KindList"), "水耕艙（10）")
	assert_false(button.disabled)
	main.stockpile.take(Stockpile.Kind.MATERIALS, 25)
	menu._process(0.0)
	assert_true(button.disabled)
	main.stockpile.add(Stockpile.Kind.MATERIALS, 25)
	menu._process(0.0)
	assert_false(button.disabled, "re-enabled while the list stays open")


func test_without_a_construction_every_button_stays_enabled():
	menu.construction = null
	main.stockpile.take(Stockpile.Kind.MATERIALS, 30)
	_open_production_list()
	for button in menu.get_node("%KindList").get_children():
		assert_false(button.disabled)


# --- production at work (A9) ---

func test_a_finished_farm_gets_a_producer_and_adds_food():
	var farm := _open_farm()
	main.clock.paused = false
	var before: int = main.stockpile.amount(Stockpile.Kind.FOOD)
	for i in 400:
		main._process(0.5)
	assert_ne(main.production.producer_of(farm.id), -1)
	assert_gt(main.stockpile.amount(Stockpile.Kind.FOOD), before)


# --- the facility panel (R6) ---

func test_the_panel_shows_a_production_facility():
	var farm := _open_farm()
	assert_eq(hud.get_node("%InfoTitle").text, "設施")
	assert_eq(hud.get_node("%FacilityState").text, "生產 食物 · 進度 0%")
	assert_true(hud.get_node("%PriorityRow").visible)
	assert_eq(hud.get_node("%FacilityPriority").get_selected_id(), farm.production_priority)
	assert_true(hud.get_node("%FacilityPause").visible)
	assert_eq(hud.get_node("%FacilityPause").text, "暫停生產")
	assert_true(hud.get_node("%FacilityDemolish").visible)
	assert_false(hud.get_node("%FacilityCancel").visible)


func test_the_panel_follows_production_progress():
	var farm := _open_farm()
	farm.output_done = Production.SECONDS_PER_UNIT * 0.5
	hud._process(0.0)
	assert_eq(hud.get_node("%FacilityState").text, "生產 食物 · 進度 50%")


func test_the_priority_picker_sets_the_production_priority():
	var farm := _open_farm()
	var picker: OptionButton = hud.get_node("%FacilityPriority")
	picker.select(picker.get_item_index(5))
	picker.item_selected.emit(picker.get_item_index(5))
	assert_eq(farm.production_priority, 5)


func test_pause_releases_the_producer_and_resume_brings_one_back():
	var farm := _open_farm()
	main.clock.paused = false
	main._process(0.1)
	assert_ne(main.production.producer_of(farm.id), -1)
	var pause: Button = hud.get_node("%FacilityPause")
	pause.pressed.emit()
	assert_true(farm.paused)
	hud._process(0.0)
	assert_eq(pause.text, "恢復生產")
	assert_string_contains(hud.get_node("%FacilityState").text, "（已暫停）")
	main._process(0.1)
	assert_eq(main.production.producer_of(farm.id), -1)
	pause.pressed.emit()
	assert_false(farm.paused)
	hud._process(0.0)
	assert_eq(pause.text, "暫停生產")


func test_demolishing_goes_through_production():
	var farm := _open_farm()
	main.clock.paused = false
	main._process(0.1)
	hud.get_node("%FacilityDemolish").pressed.emit()
	assert_eq(main.construction.facilities().size(), 0)
	assert_eq(main.production.producer_of(farm.id), -1)
	assert_false(hud.get_node("%InfoPanel").visible)


func test_a_living_facility_has_no_pause_button():
	var spot := _spot(FacilityCatalog.Kind.HYGIENE_STALL)
	var stall: Facility = main.construction.place(FacilityCatalog.Kind.HYGIENE_STALL, spot)
	_finish(stall)
	_click(spot)
	assert_false(hud.get_node("%FacilityPause").visible)
	assert_eq(hud.get_node("%FacilityState").text, "已完工")


func test_a_blueprint_has_no_pause_button_and_keeps_the_build_priority():
	var spot := _spot(FARM)
	var farm: Facility = main.construction.place(FARM, spot)
	_click(spot)
	assert_false(hud.get_node("%FacilityPause").visible)
	var picker: OptionButton = hud.get_node("%FacilityPriority")
	picker.select(picker.get_item_index(4))
	picker.item_selected.emit(picker.get_item_index(4))
	assert_eq(main.construction.priority_of(farm.id), 4)


# --- the colonist panel ---

func test_a_production_job_is_listed_without_a_cancel_button():
	var farm := _open_farm()
	main.clock.paused = false
	main._process(0.1)
	var id: int = main.production.producer_of(farm.id)
	assert_ne(id, -1)
	# Show the producer directly: random walkers make a click on the map unreliable.
	var colonist: Colonist = main.colony.colonists.filter(func(c): return c.id == id)[0]
	hud.show_colonist(colonist, main.wanderers[id].tasks)
	hud._process(0.0)
	assert_eq(hud.get_node("%InfoTitle").text, "殖民者")
	assert_eq(hud.get_node("%InfoName").text, colonist.name)
	assert_string_contains(hud.info_tasks_text(), "生產 水耕艙 · 優先度 2")
	assert_eq(hud.get_node("%InfoTasks").find_children("*", "Button", true, false).size(), 0)
