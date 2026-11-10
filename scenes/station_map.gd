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
			var rect := Rect2(Vector2(cell) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))
			draw_rect(rect, WALL_COLOR if grid.is_wall(cell) else FLOOR_COLOR)
			draw_rect(rect, LINE_COLOR, false, 1.0)
