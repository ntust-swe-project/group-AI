extends GutTest

# T8 — debug buttons (A10).

const MainScene := preload("res://scenes/main.tscn")

var main: Node
var hud: Node


func before_each():
	main = add_child_autofree(MainScene.instantiate())
	hud = main.get_node("Hud")


func test_next_day_button_moves_to_the_next_day():
	hud.get_node("%NextDayButton").pressed.emit()
	assert_eq(main.clock.day, 2)


func test_add_colonist_button_adds_a_walking_colonist():
	hud.get_node("%AddColonistButton").pressed.emit()
	assert_eq(main.colony.colonists.size(), 4)
	assert_eq(main.wanderers.size(), 4)
	assert_eq(main.get_tree().get_nodes_in_group("colonist_views").size(), 4)
	var added: Colonist = main.colony.colonists.back()
	assert_true(main.grid.is_floor(main.wanderers[added.id].cell))


func test_added_colonist_can_be_clicked():
	hud.get_node("%AddColonistButton").pressed.emit()
	var added: Colonist = main.colony.colonists.back()
	var walker: Wanderer = main.wanderers[added.id]
	assert_same(main.colonist_at(main.station_map.cell_to_pixel(walker.position())), added)
