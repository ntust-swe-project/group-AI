class_name Assignment
extends RefCounted

## One order from the player: go to a cell and work there (feature 002).
## For now the work is a placeholder: arrive, then wait (I1). Feature 003 also
## uses it for supply work a colonist gives itself: `need` names the need it
## refills, and the sleep pod takes longer than the rest (R7).
## A build job (feature 004) is an assignment with a facility id: the cell is
## where the builder stands, next to the blueprint.

const MIN_PRIORITY := 1
const MAX_PRIORITY := 5  # bigger is more urgent; idling counts as 0 (Q2)
## Game seconds of work at the cell before it is done (002 Q5, I6).
const DEFAULT_WORK_SECONDS := 2.0
const NO_FACILITY := -1

var id: int  # grows in creation order; ties in priority go to the smaller id
var cell: Vector2i
var priority: int
## Empty for a player's order; otherwise the Physiology need this refills.
var need: StringName
var work_seconds: float
var facility_id := NO_FACILITY  # the blueprint being built, for build jobs


func _init(assignment_id: int, target_cell: Vector2i, assignment_priority: int,
		refills: StringName = &"", seconds_of_work: float = DEFAULT_WORK_SECONDS) -> void:
	id = assignment_id
	cell = target_cell
	priority = assignment_priority
	need = refills
	work_seconds = seconds_of_work


func is_build() -> bool:
	return facility_id != NO_FACILITY
