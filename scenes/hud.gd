extends CanvasLayer

## Day counter and time controls (feature 001, R1, R8), and the info panel for
## the selected colonist: name, needs and tasks (features 001-003).

signal add_colonist_requested
signal cancel_task_requested(task_id: int)

const TASK_FONT_SIZE := 14

## The needs as the panel lists them, named as in SYSTEM.md §2 (feature 003, R5).
## Body and mind stay two lists, shown in two sections (SC2).
const BODY_NEEDS := [[&"hunger", "吃"], [&"thirst", "喝"], [&"body_temp", "體溫"], [&"relief", "排泄"], [&"stamina", "體力"]]
const MIND_NEEDS := [[&"stress", "壓力"], [&"mood", "心情"]]
## How supply work is listed in the queue instead of a cell (I7), named as in R7.
const SUPPLY_NAMES := {&"hunger": "食物補給站", &"thirst": "水補給站", &"relief": "廁所", &"stamina": "睡眠艙"}

var clock: DayClock

var _shown_colonist: Colonist  # the colonist in the info panel, if any
var _shown_tasks: TaskQueue  # their tasks
var _shown_signature := []  # what the task rows show now; rebuilt only when it changes


func _ready() -> void:
	%PauseButton.pressed.connect(_on_pause_pressed)
	%SlowerButton.pressed.connect(_on_slower_pressed)
	%FasterButton.pressed.connect(_on_faster_pressed)
	%NextDayButton.pressed.connect(_on_next_day_pressed)
	%AddColonistButton.pressed.connect(add_colonist_requested.emit)


func _process(_delta: float) -> void:
	refresh()
	if %InfoPanel.visible and _shown_colonist:
		_update_needs()
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


## Info panel: the name (feature 001, R9), the needs in two sections and an
## incapacitated mark (feature 003, R5, R10), and the tasks, each with a cancel
## button (feature 002, R8, I8).
func show_colonist(colonist: Colonist, tasks: TaskQueue = null) -> void:
	%InfoName.text = colonist.name
	_shown_colonist = colonist
	_update_needs()
	_shown_tasks = tasks
	_shown_signature = [null]  # force a rebuild
	_update_task_rows()
	%InfoPanel.visible = true


func hide_info() -> void:
	_shown_colonist = null
	_shown_tasks = null
	%InfoPanel.visible = false


## The task rows as plain text, one line each (for tests and debugging).
func info_tasks_text() -> String:
	var lines: Array[String] = []
	for label in %InfoTasks.find_children("*", "Label", true, false):
		lines.append(label.text)
	return "\n".join(lines)


func _update_needs() -> void:
	%InfoBody.text = _needs_text(_shown_colonist.physiology, BODY_NEEDS)
	%InfoMind.text = _needs_text(_shown_colonist.psychology, MIND_NEEDS)
	%InfoStatus.visible = _shown_colonist.incapacitated


func _needs_text(source: Object, needs: Array) -> String:
	var lines: Array[String] = []
	for need in needs:
		lines.append("%s %d" % [need[1], _shown_value(source.get(need[0]))])
	return "\n".join(lines)


## Rounded, except that a line the game acts on is shown only once really
## crossed: 0 and 100 are where a colonist breaks down (R8), and under 30 a need
## counts as low (R4, R6), so 29.6 shows 29, not 30.
func _shown_value(value: float) -> int:
	var shown := roundi(value)
	if shown == 0 and value > 0.0:
		return 1
	if shown == 100 and value < 100.0:
		return 99
	if shown == int(Physiology.LOW) and value < Physiology.LOW:
		return shown - 1
	return shown


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
	if _shown_colonist and _shown_colonist.incapacitated:
		# Every task was cancelled and they cannot move: not wandering (R8, R10).
		_add_label("正在做：無（失能）")
		_add_label("排隊：無")
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
	var ids := [_shown_colonist != null and _shown_colonist.incapacitated]
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
	var what := ("前往%s" % SUPPLY_NAMES[task.need]) if task.need != &"" else ("(%d, %d)" % [task.cell.x, task.cell.y])
	label.text = "  %s · 優先度 %d" % [what, task.priority]
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
