class_name Colonist
extends RefCounted

## One colonist. For now only identity (feature 001, R4); needs come later.

var id: int
var name: String


func _init(colonist_id: int, colonist_name: String) -> void:
	id = colonist_id
	name = colonist_name
