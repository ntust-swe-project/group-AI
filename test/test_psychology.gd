extends GutTest

# A1 of docs/specs/features/003-colonist-needs.md


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
