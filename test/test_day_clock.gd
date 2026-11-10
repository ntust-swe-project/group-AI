extends GutTest

# A1–A3 of docs/specs/features/001-base-skeleton.md

const DAY := DayClock.SECONDS_PER_DAY

var clock: DayClock


func before_each():
	clock = DayClock.new()


# A1
func test_new_clock_starts_on_day_one():
	assert_eq(clock.day, 1)


func test_less_than_a_full_day_stays_on_day_one():
	clock.advance(DAY * 0.99)
	assert_eq(clock.day, 1)


func test_a_full_day_of_time_moves_to_day_two():
	clock.advance(DAY)
	assert_eq(clock.day, 2)


func test_partial_advances_add_up_to_a_day():
	clock.advance(DAY * 0.5)
	clock.advance(DAY * 0.5)
	assert_eq(clock.day, 2)


# A2
func test_not_finished_before_day_thirty():
	clock.advance(DAY * 28)
	assert_eq(clock.day, 29)
	assert_false(clock.is_finished())


func test_arriving_at_day_thirty_is_not_finished_yet():
	clock.advance(DAY * 29)
	assert_eq(clock.day, 30)
	assert_false(clock.is_finished())


func test_finished_once_day_thirty_has_fully_passed():
	clock.advance(DAY * 29)
	clock.advance(DAY * 0.5)
	assert_false(clock.is_finished())
	clock.advance(DAY * 0.5)
	assert_eq(clock.day, 30)
	assert_true(clock.is_finished())


func test_advancing_after_finished_stays_on_day_thirty():
	clock.advance(DAY * 30)
	clock.advance(DAY * 5)
	assert_eq(clock.day, 30)
	assert_true(clock.is_finished())


func test_one_huge_advance_stops_at_day_thirty():
	clock.advance(DAY * 100)
	assert_eq(clock.day, 30)
	assert_true(clock.is_finished())


# A3 — pause
func test_paused_clock_does_not_advance():
	clock.paused = true
	clock.advance(DAY * 3)
	assert_eq(clock.day, 1)


func test_unpausing_resumes_from_where_it_stopped():
	clock.advance(DAY * 0.5)
	clock.paused = true
	clock.advance(DAY * 3)
	clock.paused = false
	clock.advance(DAY * 0.5)
	assert_eq(clock.day, 2)


# A3 — speed
func test_starts_at_normal_speed():
	assert_eq(clock.speed, 1.0)


func test_double_speed_covers_a_day_in_half_the_time():
	clock.speed_up()
	clock.speed_up()
	assert_eq(clock.speed, 2.0)
	clock.advance(DAY * 0.5)
	assert_eq(clock.day, 2)


func test_half_speed_needs_twice_the_time():
	clock.slow_down()
	assert_eq(clock.speed, 0.5)
	clock.advance(DAY * 1.5)
	assert_eq(clock.day, 1)
	clock.advance(DAY * 0.5)
	assert_eq(clock.day, 2)


func test_speed_steps_by_half():
	clock.speed_up()
	assert_eq(clock.speed, 1.5)
	clock.slow_down()
	assert_eq(clock.speed, 1.0)


func test_speed_stops_at_four():
	for i in 20:
		clock.speed_up()
	assert_eq(clock.speed, 4.0)


func test_speed_stops_at_half():
	for i in 20:
		clock.slow_down()
	assert_eq(clock.speed, 0.5)


func test_setting_speed_above_four_stops_at_four():
	clock.speed = 10.0
	assert_eq(clock.speed, 4.0)


func test_setting_speed_below_half_stops_at_half():
	clock.speed = 0.0
	assert_eq(clock.speed, 0.5)


func test_setting_speed_off_step_snaps_to_nearest_half():
	clock.speed = 3.7
	assert_eq(clock.speed, 3.5)


# T8 — debug "next day" (A10)
func test_skip_day_moves_to_the_next_day():
	clock.skip_day()
	assert_eq(clock.day, 2)


func test_skip_day_starts_the_new_day_from_its_beginning():
	clock.advance(DAY * 0.75)
	clock.skip_day()
	clock.advance(DAY * 0.5)
	assert_eq(clock.day, 2)


func test_skip_day_works_while_paused():
	clock.paused = true
	clock.skip_day()
	assert_eq(clock.day, 2)


func test_skipping_day_thirty_finishes_the_run():
	clock.advance(DAY * 29)
	clock.skip_day()
	assert_eq(clock.day, 30)
	assert_true(clock.is_finished())


func test_skip_day_does_nothing_after_the_run_is_over():
	clock.advance(DAY * 30)
	clock.skip_day()
	assert_eq(clock.day, 30)
	assert_true(clock.is_finished())
