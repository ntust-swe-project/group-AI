extends GutTest

# A4 of docs/specs/features/001-base-skeleton.md


func _names(colony: Colony) -> Array[String]:
	var result: Array[String] = []
	for colonist in colony.colonists:
		result.append(colonist.name)
	return result


func _has_duplicates(values: Array) -> bool:
	var seen := {}
	for value in values:
		if seen.has(value):
			return true
		seen[value] = true
	return false


func test_new_colony_has_three_colonists():
	assert_eq(Colony.new().colonists.size(), 3)


func test_initial_names_are_unique():
	assert_false(_has_duplicates(_names(Colony.new())))


func test_initial_names_come_from_the_name_table():
	for colonist_name in _names(Colony.new()):
		assert_has(ColonistNames.ALL, colonist_name)


func test_adding_a_colonist_adds_exactly_one():
	var colony := Colony.new()
	colony.add_colonist()
	assert_eq(colony.colonists.size(), 4)


func test_added_colonist_is_returned_and_kept():
	var colony := Colony.new()
	var added := colony.add_colonist()
	assert_has(colony.colonists, added)


func test_added_colonist_name_is_unique():
	var colony := Colony.new()
	for i in 10:
		colony.add_colonist()
	assert_false(_has_duplicates(_names(colony)))


func test_ids_are_unique():
	var colony := Colony.new()
	for i in 10:
		colony.add_colonist()
	var ids := []
	for colonist in colony.colonists:
		ids.append(colonist.id)
	assert_false(_has_duplicates(ids))


func test_running_out_of_names_still_gives_unique_names():
	var colony := Colony.new(PackedStringArray(["Ann", "Bob", "Cy"]))
	colony.add_colonist()
	colony.add_colonist()
	assert_eq(colony.colonists.size(), 5)
	assert_false(_has_duplicates(_names(colony)))


func test_name_table_has_no_duplicates():
	assert_false(_has_duplicates(Array(ColonistNames.ALL)))
