class_name Colonist
extends RefCounted

## One colonist: identity (feature 001, R4) plus body and mind (feature 003,
## R1). Body and mind stay two objects (SYSTEM.md SC2).

var id: int
var name: String
var physiology := Physiology.new()
var psychology := Psychology.new()


func _init(colonist_id: int, colonist_name: String) -> void:
	id = colonist_id
	name = colonist_name
