extends Node2D

## Owns the logic objects and drives them each frame (feature 001).
## Logic lives in logic/; this script only connects it to what is on screen.

const ColonistView := preload("res://scenes/colonist_view.tscn")

var clock := DayClock.new()
var grid := StationGrid.make_hall()
var colony := Colony.new()
var wanderers := {}  # colonist id -> Wanderer

var _views := {}  # colonist id -> colonist view node
var _rng := RandomNumberGenerator.new()

@onready var station_map: Node2D = $StationMap
@onready var hud: CanvasLayer = $Hud


func _ready() -> void:
	station_map.grid = grid
	hud.clock = clock
	hud.refresh()
	station_map.position = ((get_viewport_rect().size - station_map.pixel_size()) / 2.0).round()
	for colonist in colony.colonists:
		_show_colonist(colonist)


func _process(delta: float) -> void:
	# Colonists move in game time: frozen while paused or after day 30, faster at higher speed.
	var game_seconds := 0.0 if clock.paused or clock.is_finished() else delta * clock.speed
	clock.advance(delta)
	for id in wanderers:
		wanderers[id].advance(game_seconds)
		_views[id].position = station_map.cell_to_pixel(wanderers[id].position())


func _show_colonist(colonist: Colonist) -> void:
	var walker := Wanderer.new(grid, _free_floor_cell(), _rng)
	wanderers[colonist.id] = walker
	var view := ColonistView.instantiate()
	view.colonist = colonist
	view.position = station_map.cell_to_pixel(walker.position())
	station_map.add_child(view)
	_views[colonist.id] = view


## A random floor cell no colonist stands on, or any floor cell if all are taken.
func _free_floor_cell() -> Vector2i:
	var taken := {}
	for walker in wanderers.values():
		taken[walker.cell] = true
	var cells := grid.floor_cells().filter(func(c): return not taken.has(c))
	if cells.is_empty():
		cells = grid.floor_cells()
	return cells[_rng.randi_range(0, cells.size() - 1)]
