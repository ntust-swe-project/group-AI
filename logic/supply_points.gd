class_name SupplyPoints
extends RefCounted

## The four placeholder supply points (feature 003, R7, I1): food, water, toilet
## and the rest area, each refilling one Physiology need. A later feature will
## replace them with facilities; until then construction may not cover them
## (R12). Pure logic.

## The needs a supply point refills, named as Physiology's properties (R6).
const NEEDS: Array[StringName] = [&"hunger", &"thirst", &"relief", &"stamina"]

## Where they stand in the default hall: left, middle and right of its centre
## row, and the rest area above the middle (Q5). The tests check they are floor.
const HALL_CELLS := {
	&"hunger": Vector2i(14, 15),
	&"thirst": Vector2i(28, 15),
	&"relief": Vector2i(42, 15),
	&"stamina": Vector2i(28, 8),
}

## A full rest takes a minute of game time (Q11); the others take as long as a
## player's assignment (Q6).
const REST_SECONDS := 60.0

var _cells: Dictionary


## `cells` maps each of NEEDS to a cell; tests pass a smaller map of their own.
func _init(cells: Dictionary = HALL_CELLS) -> void:
	_cells = cells


func cell_for(need: StringName) -> Vector2i:
	return _cells[need]


func work_seconds(need: StringName) -> float:
	return REST_SECONDS if need == &"stamina" else Assignment.DEFAULT_WORK_SECONDS


## Every supply point's cell, for construction to keep clear (R12).
func cells() -> Array[Vector2i]:
	var all: Array[Vector2i] = []
	for need in NEEDS:
		all.append(cell_for(need))
	return all
