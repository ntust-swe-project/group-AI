extends PanelContainer

## Assignment submenu, opened from the context menu's 指派工作 (feature 002,
## R1): pick who and how urgent. Cancelling lives in the info panel (I8).
## It only reports choices; main.gd talks to the AssignmentBoard.

signal assign_requested(colonist_id: int, priority: int)

## Priority picked when the menu opens. A UI default, not a game rule.
const DEFAULT_PRIORITY := 3

## The cell the menu was opened on.
var cell: Vector2i


func _ready() -> void:
	%ExecuteButton.pressed.connect(_on_execute_pressed)
	%CloseButton.pressed.connect(close)
	for level in range(Assignment.MIN_PRIORITY, Assignment.MAX_PRIORITY + 1):
		%PriorityPicker.add_item(str(level), level)


func open(at_cell: Vector2i, screen_position: Vector2, colonists: Array[Colonist]) -> void:
	cell = at_cell
	%Title.text = "指派到 (%d, %d)" % [cell.x, cell.y]
	%ColonistPicker.clear()
	for colonist in colonists:
		%ColonistPicker.add_item(colonist.name, colonist.id)
	%PriorityPicker.select(%PriorityPicker.get_item_index(DEFAULT_PRIORITY))
	visible = true
	reset_size()
	var room := get_viewport_rect().size - size
	position = screen_position.clamp(Vector2.ZERO, room.max(Vector2.ZERO))


func close() -> void:
	visible = false


func _on_execute_pressed() -> void:
	if %ColonistPicker.item_count == 0:
		return
	assign_requested.emit(%ColonistPicker.get_selected_id(), %PriorityPicker.get_selected_id())
