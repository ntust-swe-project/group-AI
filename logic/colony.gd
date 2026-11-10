class_name Colony
extends RefCounted

## The set of colonists. Never assume a fixed size (SYSTEM.md SC1).

const INITIAL_COLONISTS := 3  # Q2

var colonists: Array[Colonist] = []

var _names: PackedStringArray
var _next_id := 1
var _rng := RandomNumberGenerator.new()


func _init(names: PackedStringArray = ColonistNames.ALL) -> void:
	_names = names
	for i in INITIAL_COLONISTS:
		add_colonist()


func add_colonist() -> Colonist:
	var colonist := Colonist.new(_next_id, _pick_unused_name())
	_next_id += 1
	colonists.append(colonist)
	return colonist


func _pick_unused_name() -> String:
	var used := {}
	for colonist in colonists:
		used[colonist.name] = true

	var unused: Array[String] = []
	for name in _names:
		if not used.has(name):
			unused.append(name)
	if not unused.is_empty():
		return unused[_rng.randi_range(0, unused.size() - 1)]

	# Every name is taken: reuse one with a number until it is unique.
	var base := _names[_rng.randi_range(0, _names.size() - 1)] if not _names.is_empty() else "Colonist"
	var n := 2
	while used.has("%s %d" % [base, n]):
		n += 1
	return "%s %d" % [base, n]
