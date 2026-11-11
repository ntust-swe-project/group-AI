extends GutTest

# A1, A3 of docs/specs/features/003-colonist-needs.md


func test_new_mind_is_calm_and_content():
	# Stress is worse when high, Mood is better when high (Q1).
	var mind := Psychology.new()
	assert_eq(mind.stress, 0.0)
	assert_eq(mind.mood, 100.0)


func test_colonist_has_a_body_and_a_mind_apart():
	# SYSTEM.md SC2: the two are read separately and never merged.
	# Held as Variant: `is` on a statically typed value is flagged at parse time.
	var colonist := Colonist.new(1, "Ann")
	var body: Variant = colonist.physiology
	var mind: Variant = colonist.psychology
	assert_true(body is Physiology)
	assert_true(mind is Psychology)


func test_each_colonist_has_their_own_needs():
	var ann := Colonist.new(1, "Ann")
	var bo := Colonist.new(2, "Bo")
	ann.physiology.thirst = 10.0
	ann.psychology.stress = 90.0
	assert_eq(bo.physiology.thirst, 100.0)
	assert_eq(bo.psychology.stress, 0.0)


# --- A3: how the mind changes (R4) ---

const DAY := DayClock.SECONDS_PER_DAY


func test_stress_rises_while_working():
	var mind := Psychology.new()
	mind.advance(30.0, true, false)
	assert_gt(mind.stress, 0.0)


func test_stress_falls_while_not_working():
	var mind := Psychology.new()
	mind.stress = 50.0
	mind.advance(30.0, false, false)
	assert_lt(mind.stress, 50.0)


func test_mood_falls_while_the_body_is_low():
	var mind := Psychology.new()
	mind.advance(30.0, false, true)
	assert_lt(mind.mood, 100.0)


func test_mood_recovers_when_the_body_is_fine():
	var mind := Psychology.new()
	mind.mood = 50.0
	mind.advance(30.0, false, false)
	assert_gt(mind.mood, 50.0)


func test_each_takes_one_day_end_to_end():
	# Half a day, not a whole one: at a full day the clamp hides a rate that is too fast.
	var mind := Psychology.new()
	mind.advance(DAY / 2.0, true, true)
	assert_almost_eq(mind.stress, 50.0, 0.001)
	assert_almost_eq(mind.mood, 50.0, 0.001)
	mind.advance(DAY / 2.0, false, false)
	assert_almost_eq(mind.stress, 0.0, 0.001)
	assert_almost_eq(mind.mood, 100.0, 0.001)


func test_both_stay_between_0_and_100():
	var mind := Psychology.new()
	mind.advance(DAY * 3, true, true)
	assert_eq(mind.stress, 100.0)
	assert_eq(mind.mood, 0.0)
	mind.advance(DAY * 3, false, false)
	assert_eq(mind.stress, 0.0)
	assert_eq(mind.mood, 100.0)


func test_stress_ignores_the_body_and_mood_ignores_work():
	var ordered := Psychology.new()
	ordered.mood = 50.0
	ordered.advance(30.0, true, false)
	assert_gt(ordered.mood, 50.0, "work alone must not lower Mood")
	var hungry := Psychology.new()
	hungry.stress = 50.0
	hungry.advance(30.0, false, true)
	assert_lt(hungry.stress, 50.0, "a low body alone must not raise Stress")


func test_no_game_time_no_change():
	var mind := Psychology.new()
	mind.advance(0.0, true, true)
	assert_eq(mind.stress, 0.0)
	assert_eq(mind.mood, 100.0)
