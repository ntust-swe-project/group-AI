extends GutTest

# T6 — day counter and speed controls (A8). Looks are checked by hand.

const MainScene := preload("res://scenes/main.tscn")

var main: Node
var hud: Node


func before_each():
	main = add_child_autofree(MainScene.instantiate())
	hud = main.get_node("Hud")


func _text(path: String) -> String:
	return hud.get_node(path).text


func test_shows_day_one_of_thirty_at_start():
	assert_eq(_text("%DayLabel"), "第 1 天 / 30")


func test_day_label_follows_the_clock():
	main.clock.advance(DayClock.SECONDS_PER_DAY * 4)
	gut.simulate(main, 1, 0.0)
	assert_eq(_text("%DayLabel"), "第 5 天 / 30")


func test_day_label_says_when_the_run_is_over():
	main.clock.advance(DayClock.SECONDS_PER_DAY * 30)
	gut.simulate(main, 1, 0.0)
	assert_eq(_text("%DayLabel"), "第 30 天 / 30（結束）")


func test_shows_normal_speed_at_start():
	assert_eq(_text("%SpeedLabel"), "1.0×")


func test_faster_button_speeds_up():
	hud.get_node("%FasterButton").pressed.emit()
	assert_eq(main.clock.speed, 1.5)
	assert_eq(_text("%SpeedLabel"), "1.5×")


func test_slower_button_slows_down():
	hud.get_node("%SlowerButton").pressed.emit()
	assert_eq(main.clock.speed, 0.5)
	assert_eq(_text("%SpeedLabel"), "0.5×")


func test_pause_button_toggles_pause():
	var button: Button = hud.get_node("%PauseButton")
	assert_eq(button.text, "暫停")
	button.pressed.emit()
	assert_true(main.clock.paused)
	assert_eq(button.text, "繼續")
	button.pressed.emit()
	assert_false(main.clock.paused)
	assert_eq(button.text, "暫停")
