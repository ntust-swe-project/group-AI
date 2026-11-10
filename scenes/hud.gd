extends CanvasLayer

## Day counter and time controls (feature 001, R1, R8).

signal add_colonist_requested
signal cancel_task_requested(task_id: int)

const TASK_FONT_SIZE := 14

var clock: DayClock

var _shown_tasks: TaskQueue  # the colonist in the info panel, if any
var _shown_signature := []  # what the task rows show now; rebuilt only when it changes


func _ready() -> void:
	%PauseButton.pressed.connect(_on_pause_pressed)
	%SlowerButton.pressed.connect(_on_slower_pressed)
	%FasterButton.pressed.connect(_on_faster_pressed)
	%NextDayButton.pressed.connect(_on_next_day_pressed)
	%AddColonistButton.pressed.connect(add_colonist_requested.emit)


func _process(_delta: float) -> void:
	refresh()
	if %InfoPanel.visible and _shown_tasks:
		_update_task_rows()


func refresh() -> void:
	if clock == null:
		return
	var day_text := "第 %d 天 / %d" % [clock.day, DayClock.FINAL_DAY]
	if clock.is_finished():
		day_text += "（結束）"
	%DayLabel.text = day_text
	%SpeedLabel.text = "%.1f×" % clock.speed
	%PauseButton.text = "繼續" if clock.paused else "暫停"


## Info panel: the name (feature 001, R9) and the tasks, each with a cancel
## button (feature 002, R8, I8).
func show_colonist(colonist: Colonist, tasks: TaskQueue = null) -> void:
	%InfoName.text = colonist.name
	_shown_tasks = tasks
	_shown_signature = [null]  # force a rebuild
	_update_task_rows()
	%InfoPanel.visible = true


func hide_info() -> void:
	_shown_tasks = null
	%InfoPanel.visible = false


## The task rows as plain text, one line each (for tests and debugging).
func info_tasks_text() -> String:
	var lines: Array[String] = []
	for label in %InfoTasks.find_children("*", "Label", true, false):
		lines.append(label.text)
	return "\n".join(lines)


func _update_task_rows() -> void:
	var signature := _signature(_shown_tasks)
	if signature == _shown_signature:
		return  # rebuilding every frame would swap the buttons out from under the mouse
	_shown_signature = signature
	for child in %InfoTasks.get_children():
		%InfoTasks.remove_child(child)
		child.queue_free()
	if _shown_tasks == null:
		return
	if _shown_tasks.current:
		_add_label("正在做：")
		_add_task_row(_shown_tasks.current)
	else:
		_add_label("正在做：閒晃")
	var waiting := _shown_tasks.queued()
	if waiting.is_empty():
		_add_label("排隊：無")
		return
	_add_label("排隊：")
	for task in waiting:
		_add_task_row(task)


func _signature(tasks: TaskQueue) -> Array:
	var ids := []
	if tasks:
		ids.append(tasks.current.id if tasks.current else -1)
		for task in tasks.queued():
			ids.append(task.id)
	return ids


func _add_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", TASK_FONT_SIZE)
	%InfoTasks.add_child(label)
	return label


func _add_task_row(task: Assignment) -> void:
	var row := HBoxContainer.new()
	%InfoTasks.add_child(row)
	var label := Label.new()
	label.text = "  (%d, %d) · 優先度 %d" % [task.cell.x, task.cell.y, task.priority]
	label.add_theme_font_size_override("font_size", TASK_FONT_SIZE)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var cancel := Button.new()
	cancel.text = "取消"
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.pressed.connect(cancel_task_requested.emit.bind(task.id))
	row.add_child(cancel)


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
