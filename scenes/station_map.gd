extends Node2D

## Draws the station grid as plain rectangles (wireframe only, feature 001 R3).

## Pixels per grid cell on screen. Placeholder until it is seen on screen (Q4).
const CELL_SIZE := 32.0

const FLOOR_COLOR := Color(0.16, 0.18, 0.22)
const WALL_COLOR := Color(0.55, 0.58, 0.64)
const LINE_COLOR := Color(0.24, 0.27, 0.32)

var grid: StationGrid:
	set(value):
		grid = value
		queue_redraw()


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
