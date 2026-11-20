class_name Stockpile
extends RefCounted

## The one shared stock of the whole station (feature 005, R1): food, water and
## materials, each a whole number that is never below zero. No capacity limit,
## and it does not matter where anything is kept. Pure logic (SYSTEM.md S1, R10).

enum Kind { FOOD, WATER, MATERIALS }

## Q1: what a new game starts with.
const START := {Kind.FOOD: 6, Kind.WATER: 8, Kind.MATERIALS: 30}

var _amounts := START.duplicate()


func amount(kind: Kind) -> int:
	return _amounts[kind]


## Raises by `n`. A negative `n` is a caller's bug: reported, nothing changes
## (it would break "never below zero").
func add(kind: Kind, n: int) -> void:
	if n < 0:
		push_error("Stockpile.add: n must not be negative (got %d)" % n)
		return
	_amounts[kind] += n


## True and lowered by `n`; false (nothing changes) if fewer than `n` are held.
## A negative `n` is reported and refused the same way as in `add`.
func take(kind: Kind, n: int) -> bool:
	if n < 0:
		push_error("Stockpile.take: n must not be negative (got %d)" % n)
		return false
	if _amounts[kind] < n:
		return false
	_amounts[kind] -= n
	return true
