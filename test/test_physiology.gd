extends GutTest

# A1, A2 of docs/specs/features/003-colonist-needs.md

const DAY := DayClock.SECONDS_PER_DAY


func test_new_body_is_full():
	var body := Physiology.new()
	for value in [body.hunger, body.thirst, body.body_temp, body.relief, body.stamina]:
		assert_eq(value, 100.0)


func test_one_day_empties_thirst_and_relief():
	var body := Physiology.new()
	body.advance(DAY)
	assert_almost_eq(body.thirst, 0.0, 0.001)
	assert_almost_eq(body.relief, 0.0, 0.001)


func test_one_day_leaves_a_third_of_hunger():
	var body := Physiology.new()
	body.advance(DAY)
	assert_almost_eq(body.hunger, 100.0 / 3.0, 0.001)


func test_body_temp_does_not_change_with_time():
	# No zones or event flags yet (SC7), so body temperature stays put.
	var body := Physiology.new()
	body.advance(DAY * 3)
	assert_eq(body.body_temp, 100.0)


func test_needs_stop_at_zero():
	var body := Physiology.new()
	body.advance(DAY * 3)
	assert_eq(body.hunger, 0.0)
	assert_eq(body.thirst, 0.0)
	assert_eq(body.relief, 0.0)


func test_no_game_time_no_change():
	# The scene passes 0 game seconds while paused (A2).
	var body := Physiology.new()
	body.advance(0.0)
	assert_eq(body.hunger, 100.0)
	assert_eq(body.thirst, 100.0)
	assert_eq(body.relief, 100.0)


func test_twice_the_game_time_twice_the_change():
	# At 2x the scene passes twice the game seconds for the same real time (A2).
	var slow := Physiology.new()
	var fast := Physiology.new()
	slow.advance(10.0)
	fast.advance(20.0)
	assert_lt(slow.thirst, 100.0, "must actually change, or 0 == 2 * 0 passes")
	assert_almost_eq(100.0 - fast.thirst, 2.0 * (100.0 - slow.thirst), 0.001)


func test_many_small_steps_equal_one_big_step():
	# Frames vary in length; the result must not depend on how time is sliced.
	var stepped := Physiology.new()
	for i in 60:
		stepped.advance(1.0)
	var jumped := Physiology.new()
	jumped.advance(60.0)
	assert_almost_eq(stepped.hunger, jumped.hunger, 0.001)
	assert_almost_eq(stepped.thirst, jumped.thirst, 0.001)
	assert_almost_eq(stepped.relief, jumped.relief, 0.001)
