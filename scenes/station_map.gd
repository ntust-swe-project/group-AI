extends Node2D

## Draws the station grid as plain rectangles (wireframe only, feature 001 R3).

## Pixels per grid cell on screen. Placeholder until it is seen on screen (Q4).
const CELL_SIZE := 32.0

const FLOOR_COLOR := Color(0.16, 0.18, 0.22)
const WALL_COLOR := Color(0.55, 0.58, 0.64)
const LINE_COLOR := Color(0.24, 0.27, 0.32)
const MARK_COLOR := Color(1.0, 0.85, 0.35)
const MARK_FONT_SIZE := 12
const SUPPLY_COLOR := Color(0.45, 0.8, 0.95)
const SUPPLY_FONT_SIZE := 16
## What each supply point shows on the map (feature 003, A10).
const SUPPLY_LABELS := {&"hunger": "食", &"thirst": "水", &"relief": "廁", &"stamina": "睡"}
const BLUEPRINT_COLOR := Color(0.35, 0.6, 0.95, 0.3)
const BLUEPRINT_EDGE_COLOR := Color(0.45, 0.7, 1.0)
const FACILITY_COLOR := Color(0.3, 0.5, 0.8)
const FACILITY_EDGE_COLOR := Color(0.75, 0.85, 1.0)
const FACILITY_FONT_SIZE := 9  # three characters must fit in one 32 px cell
const GHOST_OK_COLOR := Color(0.45, 0.85, 0.55)
const GHOST_BAD_COLOR := Color(0.95, 0.4, 0.4)

var grid: StationGrid:
	set(value):
		grid = value
		queue_redraw()

var supply_points: SupplyPoints:
	set(value):
		supply_points = value
		queue_redraw()
var construction: Construction  # blueprints and facilities to draw (feature 004)

var _highlighted: TaskQueue  # the selected colonist's tasks, or null
var _ghost := {}  # {kind, cell, valid} while placing (feature 004, R2), else empty
var _drawn := []  # drawn_facilities() as of the last redraw
var _markers := Node2D.new()  # drawn above the floor, below the colonists


func _ready() -> void:
	_markers.draw.connect(_draw_markers)
	add_child(_markers)
	move_child(_markers, 0)


func _process(_delta: float) -> void:
	# Tasks finish and move on while selected. Blueprints and facilities are
	# redrawn only when one is placed, finished or removed (feature 004).
	var drawn := drawn_facilities()
	if _highlighted or drawn != _drawn:
		_drawn = drawn
		_markers.queue_redraw()


## Mark the cells of one colonist's tasks (feature 002, I7); null clears.
func highlight(tasks: TaskQueue) -> void:
	_highlighted = tasks
	_markers.queue_redraw()


## While placing: a dashed outline of the facility under the mouse, green
## where it fits and red where it does not (feature 004, R2, R3).
func set_ghost(kind: FacilityCatalog.Kind, cell: Vector2i, valid: bool) -> void:
	_ghost = {"kind": kind, "cell": cell, "valid": valid}
	_markers.queue_redraw()


func clear_ghost() -> void:
	_ghost = {}
	_markers.queue_redraw()


## What is drawn for each blueprint and facility, in placing order: [{id, built}].
func drawn_facilities() -> Array:
	var drawn := []
	for facility in _facilities():
		drawn.append({"id": facility.id, "built": facility.built})
	return drawn


func _facilities() -> Array[Facility]:
	if construction == null:
		return []
	var all := construction.blueprints() + construction.facilities()
	all.sort_custom(func(a: Facility, b: Facility) -> bool: return a.id < b.id)
	return all


## {kind, cell, valid}, or empty when not placing.
func ghost() -> Dictionary:
	return _ghost.duplicate()


## What is marked now, current task first: [{cell, priority, current}].
func marked_cells() -> Array:
	var marks := []
	if _highlighted == null:
		return marks
	if _highlighted.current:
		marks.append(_mark(_highlighted.current, true))
	for task in _highlighted.queued():
		marks.append(_mark(task, false))
	return marks


## The supply points as drawn: {cell: label}. Empty until they are set.
func supply_labels() -> Dictionary:
	var labels := {}
	if supply_points:
		for need in SupplyPoints.NEEDS:
			labels[supply_points.cell_for(need)] = SUPPLY_LABELS[need]
	return labels


func pixel_size() -> Vector2:
	return Vector2(grid.size) * CELL_SIZE if grid else Vector2.ZERO


## Pixel position of a (possibly fractional) cell's centre, in map coordinates.
func cell_to_pixel(cell_position: Vector2) -> Vector2:
	return (cell_position + Vector2(0.5, 0.5)) * CELL_SIZE


func _draw() -> void:
	if grid == null:
		return
	for x in grid.size.x:
		for y in grid.size.y:
			var cell := Vector2i(x, y)
			match grid.kind_of(cell):
				StationGrid.Cell.FLOOR:
					draw_rect(_cell_rect(cell), FLOOR_COLOR)
				StationGrid.Cell.WALL:
					draw_rect(_cell_rect(cell), WALL_COLOR)
	_draw_grid_lines()
	_draw_supply_points()


## A thin frame and one character per supply point, under the task markers.
func _draw_supply_points() -> void:
	var font := ThemeDB.fallback_font
	var labels := supply_labels()
	for cell in labels:
		var rect := _cell_rect(cell)
		draw_rect(rect.grow(-4.0), SUPPLY_COLOR, false, 1.0)
		var baseline := rect.position + Vector2(0, (CELL_SIZE + SUPPLY_FONT_SIZE) / 2.0 - 2.0)
		draw_string(font, baseline, labels[cell], HORIZONTAL_ALIGNMENT_CENTER, CELL_SIZE,
			SUPPLY_FONT_SIZE, SUPPLY_COLOR)


## Each cell edge is drawn once. Width -1 draws a thin line that stays one
## screen pixel wide however the window is scaled, so lines look even (A7).
func _draw_grid_lines() -> void:
	for x in grid.size.x + 1:
		for y in grid.size.y + 1:
			var corner := Vector2(x, y) * CELL_SIZE
			# Left edge of cell (x, y): between (x - 1, y) and (x, y).
			if _is_drawn(Vector2i(x - 1, y)) or _is_drawn(Vector2i(x, y)):
				draw_line(corner, corner + Vector2(0, CELL_SIZE), LINE_COLOR, -1.0)
			# Top edge of cell (x, y): between (x, y - 1) and (x, y).
			if _is_drawn(Vector2i(x, y - 1)) or _is_drawn(Vector2i(x, y)):
				draw_line(corner, corner + Vector2(CELL_SIZE, 0), LINE_COLOR, -1.0)


func _is_drawn(cell: Vector2i) -> bool:
	return grid.kind_of(cell) != StationGrid.Cell.SPACE


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))


func _mark(task: Assignment, is_current: bool) -> Dictionary:
	return {"cell": task.cell, "priority": task.priority, "current": is_current}


## Solid frame for the task being done, dashed for queued ones, priority in the corner.
func _draw_markers() -> void:
	var font := ThemeDB.fallback_font
	_draw_facilities(font)
	_draw_ghost()
	for mark in marked_cells():
		var rect := _cell_rect(mark.cell).grow(-2.0)
		if mark.current:
			_markers.draw_rect(rect, MARK_COLOR, false, 2.0)
		else:
			var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
			for i in 4:
				_markers.draw_dashed_line(corners[i], corners[(i + 1) % 4], MARK_COLOR, 2.0, 4.0)
		_markers.draw_string(font, rect.position + Vector2(3, MARK_FONT_SIZE), str(mark.priority),
			HORIZONTAL_ALIGNMENT_LEFT, -1, MARK_FONT_SIZE, MARK_COLOR)


func _draw_ghost() -> void:
	if _ghost.is_empty():
		return
	var rect := Rect2(Vector2(_ghost.cell) * CELL_SIZE, Vector2(FacilityCatalog.size_of(_ghost.kind)) * CELL_SIZE)
	_draw_dashed_rect(rect.grow(-1.0), GHOST_OK_COLOR if _ghost.valid else GHOST_BAD_COLOR)


func _draw_dashed_rect(rect: Rect2, color: Color) -> void:
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in 4:
		_markers.draw_dashed_line(corners[i], corners[(i + 1) % 4], color, 2.0, 4.0)


## Blueprints are see-through with a thin edge; facilities are solid. Both are
## labelled with their name (feature 004, R2, R7).
func _draw_facilities(font: Font) -> void:
	for facility in _facilities():
		var rect := Rect2(Vector2(facility.origin) * CELL_SIZE, Vector2(FacilityCatalog.size_of(facility.kind)) * CELL_SIZE).grow(-1.0)
		if facility.built:
			_markers.draw_rect(rect, FACILITY_COLOR)
			_markers.draw_rect(rect, FACILITY_EDGE_COLOR, false, 1.0)
		else:
			_markers.draw_rect(rect, BLUEPRINT_COLOR)
			_markers.draw_rect(rect, BLUEPRINT_EDGE_COLOR, false, 1.0)
		var label := FacilityCatalog.display_name(facility.kind)
		_markers.draw_string(font, rect.position + Vector2(1, rect.size.y / 2.0 + FACILITY_FONT_SIZE / 2.0), label,
			HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 2.0, FACILITY_FONT_SIZE, FACILITY_EDGE_COLOR)
