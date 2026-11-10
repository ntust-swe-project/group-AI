extends PanelContainer

## Assignment submenu, opened from the context menu's 指派工作 (feature 002,
## R1, R7, I4): pick who and how urgent, or cancel what is already assigned there. It only reports choices;
## main.gd talks to the AssignmentBoard.

signal assign_requested(colonist_id: int, priority: int)
signal cancel_requested(assignment_id: int)

## Priority picked when the menu opens. A UI default, not a game rule.
const DEFAULT_PRIORITY := 3

## The cell the menu was opened on.
var cell: Vector2i


func _ready() -> void:
	%ExecuteButton.pressed.connect(_on_execute_pressed)
	%CloseButton.pressed.connect(close)
	for level in range(Assignment.MIN_PRIORITY, Assignment.MAX_PRIORITY + 1):
		%PriorityPicker.add_item(str(level), level)


## `existing` holds one Dictionary per assignment at the cell:
## {"id": int, "name": String, "priority": int}.
func open(at_cell: Vector2i, screen_position: Vector2, colonists: Array[Colonist], existing: Array) -> void:
	cell = at_cell
	%Title.text = "指派到 (%d, %d)" % [cell.x, cell.y]
	%ColonistPicker.clear()
	for colonist in colonists:
		%ColonistPicker.add_item(colonist.name, colonist.id)
	%PriorityPicker.select(%PriorityPicker.get_item_index(DEFAULT_PRIORITY))
	show_existing(existing)
	visible = true
	reset_size()
	var room := get_viewport_rect().size - size
	position = screen_position.clamp(Vector2.ZERO, room.max(Vector2.ZERO))


func show_existing(existing: Array) -> void:
	for child in %ExistingList.get_children():
		%ExistingList.remove_child(child)
		child.queue_free()
	%ExistingTitle.visible = not existing.is_empty()
	for entry in existing:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "%s · 優先度 %d" % [entry.name, entry.priority]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cancel := Button.new()
		cancel.text = "取消"
		cancel.focus_mode = Control.FOCUS_NONE
		cancel.pressed.connect(cancel_requested.emit.bind(entry.id))
		row.add_child(label)
		row.add_child(cancel)
		%ExistingList.add_child(row)
	reset_size()


func close() -> void:
	visible = false


func _on_execute_pressed() -> void:
	if %ColonistPicker.item_count == 0:
		return
	assign_requested.emit(%ColonistPicker.get_selected_id(), %PriorityPicker.get_selected_id())
