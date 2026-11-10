class_name Assignment
extends RefCounted

## One order from the player: go to a cell and work there (feature 002).
## For now the work is a placeholder: arrive, then wait (I1).

const MIN_PRIORITY := 1
const MAX_PRIORITY := 5  # bigger is more urgent; idling counts as 0 (Q2)

var id: int  # grows in creation order; ties in priority go to the smaller id
var cell: Vector2i
var priority: int


func _init(assignment_id: int, target_cell: Vector2i, assignment_priority: int) -> void:
	id = assignment_id
	cell = target_cell
	priority = assignment_priority
