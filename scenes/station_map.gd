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

var grid: StationGrid:
	set(value):
		grid = value
		queue_redraw()

var supply_points: SupplyPoints:
	set(value):
		supply_points = value
		queue_redraw()

var _highlighted: TaskQueue  # the selected colonist's tasks, or null
var _markers := Node2D.new()  # drawn above the floor, below the colonists


func _ready() -> void:
	_markers.draw.connect(_draw_markers)
	add_child(_markers)
	move_child(_markers, 0)


func _process(_delta: float) -> void:
	if _highlighted:
		_markers.queue_redraw()  # tasks finish and move on while selected


## Mark the cells of one colonist's tasks (feature 002, I7); null clears.
func highlight(tasks: TaskQueue) -> void:
	_highlighted = tasks
	_markers.queue_redraw()


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
