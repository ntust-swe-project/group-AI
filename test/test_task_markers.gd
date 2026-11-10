extends GutTest

# T7 — the selected colonist's task cells are marked on the map (A10, I7).

const MainScene := preload("res://scenes/main.tscn")

var main: Node


func before_each():
	main = add_child_autofree(MainScene.instantiate())
	main.clock.paused = true


func _left_click(map_point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = main.station_map.to_global(map_point)
	main._unhandled_input(event)


func _select(colonist: Colonist) -> void:
	_left_click(main.station_map.cell_to_pixel(main.wanderers[colonist.id].position()))


func _marks() -> Array:
	return main.station_map.marked_cells()


func test_nothing_is_marked_without_a_selection():
	var c: Colonist = main.colony.colonists[0]
	main.board.create(c.id, Vector2i(20, 12), 3)
	assert_eq(_marks().size(), 0)


func test_selected_colonist_has_current_and_queued_cells_marked():
	var c: Colonist = main.colony.colonists[0]
	main.board.create(c.id, Vector2i(20, 12), 2)
	main.board.create(c.id, Vector2i(22, 12), 5)  # takes over
	_select(c)
	var marks := _marks()
	assert_eq(marks.size(), 2)
	assert_eq(marks[0], {"cell": Vector2i(22, 12), "priority": 5, "current": true})
	assert_eq(marks[1], {"cell": Vector2i(20, 12), "priority": 2, "current": false})


func test_only_the_selected_colonists_cells_are_marked():
	var a: Colonist = main.colony.colonists[0]
	var b: Colonist = main.colony.colonists[1]
	main.board.create(a.id, Vector2i(20, 12), 3)
	main.board.create(b.id, Vector2i(30, 12), 3)
	_select(a)
	assert_eq(_marks().size(), 1)
	assert_eq(_marks()[0].cell, Vector2i(20, 12))


func test_marks_follow_a_cancel_and_clear_on_deselect():
	var c: Colonist = main.colony.colonists[0]
	var task: Assignment = main.board.create(c.id, Vector2i(20, 12), 3)
	_select(c)
	main.board.cancel(task.id)
	assert_eq(_marks().size(), 0, "read live, not copied")
	main.board.create(c.id, Vector2i(21, 12), 3)
	_left_click(Vector2(-500, -500))  # empty space
	assert_eq(_marks().size(), 0)
