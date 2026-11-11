class_name Facility
extends RefCounted

## One blueprint or built facility (feature 004). Pure logic (SYSTEM.md S1).

var id: int
var kind: FacilityCatalog.Kind
var origin: Vector2i  # top-left cell
var built := false
var priority := Construction.DEFAULT_PRIORITY  # of its build job (R4, Q4)


func _init(facility_id: int, facility_kind: FacilityCatalog.Kind, top_left: Vector2i) -> void:
	id = facility_id
	kind = facility_kind
	origin = top_left


## The cells it covers, row by row from the top-left one.
func cells() -> Array[Vector2i]:
	return Construction.cells_for(kind, origin)
