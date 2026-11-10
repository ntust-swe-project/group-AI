extends CanvasLayer

## Day counter and time controls (feature 001, R1, R8).

signal add_colonist_requested

var clock: DayClock

var _shown_tasks: TaskQueue  # the colonist in the info panel, if any


func _ready() -> void:
	%PauseButton.pressed.connect(_on_pause_pressed)
	%SlowerButton.pressed.connect(_on_slower_pressed)
	%FasterButton.pressed.connect(_on_faster_pressed)
	%NextDayButton.pressed.connect(_on_next_day_pressed)
	%AddColonistButton.pressed.connect(add_colonist_requested.emit)


func _process(_delta: float) -> void:
	refresh()
	if %InfoPanel.visible and _shown_tasks:
		%InfoTasks.text = _describe(_shown_tasks)


func refresh() -> void:
	if clock == null:
		return
	var day_text := "第 %d 天 / %d" % [clock.day, DayClock.FINAL_DAY]
	if clock.is_finished():
		day_text += "（結束）"
	%DayLabel.text = day_text
	%SpeedLabel.text = "%.1f×" % clock.speed
	%PauseButton.text = "繼續" if clock.paused else "暫停"


## Info panel: the name (feature 001, R9) and what they are doing (feature 002, R8).
func show_colonist(colonist: Colonist, tasks: TaskQueue = null) -> void:
	%InfoName.text = colonist.name
	_shown_tasks = tasks
	%InfoTasks.text = _describe(tasks) if tasks else ""
	%InfoPanel.visible = true


func hide_info() -> void:
	_shown_tasks = null
	%InfoPanel.visible = false


func _describe(tasks: TaskQueue) -> String:
	var lines: Array[String] = []
	lines.append("正在做：" + (_task_text(tasks.current) if tasks.current else "閒晃"))
	var waiting := tasks.queued()
	if waiting.is_empty():
		lines.append("排隊：無")
	else:
		lines.append("排隊：")
		for task in waiting:
			lines.append("  " + _task_text(task))
	return "\n".join(lines)


func _task_text(task: Assignment) -> String:
	return "(%d, %d) · 優先度 %d" % [task.cell.x, task.cell.y, task.priority]


func _on_pause_pressed() -> void:
	clock.paused = not clock.paused
	refresh()


func _on_slower_pressed() -> void:
	clock.slow_down()
	refresh()


func _on_faster_pressed() -> void:
	clock.speed_up()
	refresh()


func _on_next_day_pressed() -> void:
	clock.skip_day()
	refresh()
