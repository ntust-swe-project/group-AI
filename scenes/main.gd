extends Node2D

## Owns the logic objects and drives them each frame (feature 001).
## Logic lives in logic/; this script only connects it to what is on screen.

var clock := DayClock.new()
var grid := StationGrid.make_hall()

@onready var station_map: Node2D = $StationMap


func _ready() -> void:
	station_map.grid = grid
	station_map.position = ((get_viewport_rect().size - station_map.pixel_size()) / 2.0).round()


func _process(delta: float) -> void:
	clock.advance(delta)
