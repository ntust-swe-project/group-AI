extends PanelContainer

## Right-click menu on a cell (feature 002, R1): a list of actions. For now the
## only one is 指派工作, which opens the assignment menu as a submenu. Add more
## buttons here as features need them (Q7).

signal assign_chosen

## The cell the menu was opened on.
var cell: Vector2i
## Where it was opened, so a submenu can open in the same place.
var opened_at: Vector2


func _ready() -> void:
	%AssignButton.pressed.connect(_on_assign_pressed)


func open(at_cell: Vector2i, screen_position: Vector2) -> void:
	cell = at_cell
	opened_at = screen_position
	visible = true
	reset_size()
	var room := get_viewport_rect().size - size
	position = screen_position.clamp(Vector2.ZERO, room.max(Vector2.ZERO))


func close() -> void:
	visible = false


func _on_assign_pressed() -> void:
	close()
	assign_chosen.emit()
