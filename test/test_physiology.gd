extends GutTest

# A1, A2, A3 of docs/specs/features/003-colonist-needs.md

const DAY := DayClock.SECONDS_PER_DAY


func test_new_body_is_full():
	var body := Physiology.new()
	for value in [body.hunger, body.thirst, body.body_temp, body.relief, body.stamina]:
		assert_eq(value, 100.0)


func test_one_day_empties_thirst_and_relief():
	var body := Physiology.new()
	body.advance(DAY, false)
	assert_almost_eq(body.thirst, 0.0, 0.001)
	assert_almost_eq(body.relief, 0.0, 0.001)


func test_one_day_leaves_a_third_of_hunger():
	var body := Physiology.new()
	body.advance(DAY, false)
	assert_almost_eq(body.hunger, 100.0 / 3.0, 0.001)


func test_body_temp_does_not_change_with_time():
	# No zones or event flags yet (SC7), so body temperature stays put.
	var body := Physiology.new()
	body.advance(DAY * 3, false)
	assert_eq(body.body_temp, 100.0)


func test_needs_stop_at_zero():
	var body := Physiology.new()
	body.advance(DAY * 3, false)
	assert_eq(body.hunger, 0.0)
	assert_eq(body.thirst, 0.0)
	assert_eq(body.relief, 0.0)


func test_no_game_time_no_change():
	# The scene passes 0 game seconds while paused (A2).
	var body := Physiology.new()
	body.advance(0.0, false)
	assert_eq(body.hunger, 100.0)
	assert_eq(body.thirst, 100.0)
	assert_eq(body.relief, 100.0)


func test_twice_the_game_time_twice_the_change():
	# At 2x the scene passes twice the game seconds for the same real time (A2).
	var slow := Physiology.new()
	var fast := Physiology.new()
	slow.advance(10.0, false)
	fast.advance(20.0, false)
	assert_lt(slow.thirst, 100.0, "must actually change, or 0 == 2 * 0 passes")
	assert_almost_eq(100.0 - fast.thirst, 2.0 * (100.0 - slow.thirst), 0.001)


func test_many_small_steps_equal_one_big_step():
	# Frames vary in length; the result must not depend on how time is sliced.
	var stepped := Physiology.new()
	for i in 60:
		stepped.advance(1.0, false)
	var jumped := Physiology.new()
	jumped.advance(60.0, false)
	assert_almost_eq(stepped.hunger, jumped.hunger, 0.001)
	assert_almost_eq(stepped.thirst, jumped.thirst, 0.001)
	assert_almost_eq(stepped.relief, jumped.relief, 0.001)


# --- A3: Stamina falls with work and only with work (R3) ---

func test_stamina_falls_while_working():
	var body := Physiology.new()
	body.advance(30.0, true)
	assert_lt(body.stamina, 100.0)


func test_stamina_holds_when_not_working():
	# Idle, incapacitated or resting: no change. Only a full rest refills it (T3).
	var body := Physiology.new()
	body.stamina = 50.0
	body.advance(30.0, false)
	assert_eq(body.stamina, 50.0)


func test_stamina_takes_one_day_of_work_to_empty():
	# Half a day, not a whole one: at a full day the clamp hides a rate that is too fast.
	var body := Physiology.new()
	body.advance(DAY / 2.0, true)
	assert_almost_eq(body.stamina, 50.0, 0.001)


func test_stamina_stops_at_zero():
	var body := Physiology.new()
	body.advance(DAY * 3, true)
	assert_eq(body.stamina, 0.0)


func test_other_needs_fall_working_or_not():
	for working in [true, false]:
		var body := Physiology.new()
		body.advance(30.0, working)
		assert_lt(body.hunger, 100.0, "working=%s" % working)
		assert_lt(body.thirst, 100.0, "working=%s" % working)
		assert_lt(body.relief, 100.0, "working=%s" % working)


# --- any_low(): what Mood follows (R4) ---

func test_a_full_body_is_not_low():
	assert_false(Physiology.new().any_low())


func test_any_need_under_30_makes_the_body_low():
	for need in ["hunger", "thirst", "body_temp", "relief", "stamina"]:
		var body := Physiology.new()
		body.set(need, 29.9)
		assert_true(body.any_low(), need)


func test_exactly_30_is_not_low():
	# R4 says "低於 30": below, not at.
	var body := Physiology.new()
	body.thirst = 30.0
	assert_false(body.any_low())
