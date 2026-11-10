extends CanvasLayer

## Day counter and time controls (feature 001, R1, R8).

var clock: DayClock


func _ready() -> void:
	%PauseButton.pressed.connect(_on_pause_pressed)
	%SlowerButton.pressed.connect(_on_slower_pressed)
	%FasterButton.pressed.connect(_on_faster_pressed)


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	if clock == null:
		return
	var day_text := "第 %d 天 / %d" % [clock.day, DayClock.FINAL_DAY]
	if clock.is_finished():
		day_text += "（結束）"
	%DayLabel.text = day_text
	%SpeedLabel.text = "%.1f×" % clock.speed
	%PauseButton.text = "繼續" if clock.paused else "暫停"


## Info panel (feature 001, R9): only the name for now; needs come later.
func show_colonist(colonist: Colonist) -> void:
	%InfoName.text = colonist.name
	%InfoPanel.visible = true


func hide_info() -> void:
	%InfoPanel.visible = false


func _on_pause_pressed() -> void:
	clock.paused = not clock.paused
	refresh()


func _on_slower_pressed() -> void:
	clock.slow_down()
	refresh()


func _on_faster_pressed() -> void:
	clock.speed_up()
	refresh()
