extends CanvasLayer

## Day counter and time controls (feature 001, R1, R8), and the info panel for
## the selected colonist: name, needs and tasks (features 001-003).

signal add_colonist_requested
signal cancel_task_requested(task_id: int)
signal facility_priority_requested(facility_id: int, priority: int)
signal facility_cancel_requested(facility_id: int)
signal facility_demolish_requested(facility_id: int)
signal facility_pause_requested(facility_id: int, paused: bool)

const TASK_FONT_SIZE := 14

## The needs as the panel lists them, named as in SYSTEM.md §2 (feature 003, R5).
## Body and mind stay two lists, shown in two sections (SC2).
const BODY_NEEDS := [[&"hunger", "吃"], [&"thirst", "喝"], [&"body_temp", "體溫"], [&"relief", "排泄"], [&"stamina", "體力"]]
const MIND_NEEDS := [[&"stress", "壓力"], [&"mood", "心情"]]
## How supply work is listed in the queue instead of a cell (I7), named as in R7.
const SUPPLY_NAMES := {&"hunger": "食物補給站", &"thirst": "水補給站", &"relief": "廁所", &"stamina": "休息區"}
## What a production facility makes, by Stockpile.Kind (feature 005, R6).
const PRODUCT_NAMES := {Stockpile.Kind.FOOD: "食物", Stockpile.Kind.WATER: "水", Stockpile.Kind.MATERIALS: "材料"}

var clock: DayClock
var construction: Construction  # for the facility section and build job names (feature 004)
var stockpile: Stockpile  # for the resource bar (feature 005, R2)
var production: Production  # for the production section of the facility panel (feature 005, R6)

var _shown_colonist: Colonist  # the colonist in the info panel, if any
var _shown_tasks: TaskQueue  # their tasks
var _shown_signature := []  # what the task rows show now; rebuilt only when it changes
var _shown_facility := -1  # id of the blueprint or facility in the info panel, or -1
var _shown_built := false  # whether it was built when the section was last laid out


func _ready() -> void:
	%PauseButton.pressed.connect(_on_pause_pressed)
	%SlowerButton.pressed.connect(_on_slower_pressed)
	%FasterButton.pressed.connect(_on_faster_pressed)
	%NextDayButton.pressed.connect(_on_next_day_pressed)
	%AddColonistButton.pressed.connect(add_colonist_requested.emit)
	for level in range(Assignment.MIN_PRIORITY, Assignment.MAX_PRIORITY + 1):
		%FacilityPriority.add_item(str(level), level)
	%FacilityPriority.item_selected.connect(_on_facility_priority_selected)
	%FacilityCancel.pressed.connect(func(): facility_cancel_requested.emit(_shown_facility))
	%FacilityDemolish.pressed.connect(func(): facility_demolish_requested.emit(_shown_facility))
	%FacilityPause.pressed.connect(_on_pause_production_pressed)


func _process(_delta: float) -> void:
	refresh()
	if %InfoPanel.visible and _shown_colonist:
		_update_needs()
	if %InfoPanel.visible and _shown_tasks:
		_update_task_rows()
	if %InfoPanel.visible and _shown_facility != -1:
		_update_facility()


func refresh() -> void:
	if stockpile and construction:
		%ResourceLabel.text = "食物 %d　水 %d　材料 %d　發展 %d" % [
			stockpile.amount(Stockpile.Kind.FOOD), stockpile.amount(Stockpile.Kind.WATER),
			stockpile.amount(Stockpile.Kind.MATERIALS), construction.development_level()]
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
	_shown_facility = -1
	%InfoTitle.text = "殖民者"
	%InfoName.text = colonist.name
	%InfoTasks.visible = true
	%FacilityBox.visible = false
	_show_needs_sections(true)
	_shown_colonist = colonist
	_update_needs()
	_shown_tasks = tasks
	_shown_signature = [null]  # force a rebuild
	_update_task_rows()
	%InfoPanel.visible = true
	%InfoPanel.reset_size()


func hide_info() -> void:
	_shown_colonist = null
	_shown_tasks = null
	_shown_facility = -1
	%InfoPanel.visible = false


## Info panel for a blueprint or facility (feature 004, R4, R8): a blueprint
## shows its progress, a priority picker and 取消藍圖; a facility shows 拆除.
func show_facility(facility_id: int) -> void:
	var facility := construction.find(facility_id) if construction else null
	if facility == null:
		hide_info()
		return
	_shown_colonist = null
	_shown_tasks = null
	_shown_facility = facility_id
	%InfoTasks.visible = false
	%FacilityBox.visible = true
	_show_needs_sections(false)
	%InfoName.text = FacilityCatalog.display_name(facility.kind)
	_lay_out_facility(facility)
	%InfoPanel.visible = true
	%InfoPanel.reset_size()  # shrink back after a long task list


func _update_facility() -> void:
	var facility := construction.find(_shown_facility)
	if facility == null:
		hide_info()  # cancelled or demolished
		return
	if facility.built != _shown_built:
		_lay_out_facility(facility)
	elif not facility.built:
		%FacilityState.text = _progress_text(facility)
	elif _produces(facility):
		%FacilityState.text = _production_text(facility)
		%FacilityPause.text = _pause_text(facility)


func _lay_out_facility(facility: Facility) -> void:
	_shown_built = facility.built
	%InfoTitle.text = "設施" if facility.built else "藍圖"
	var producing := _produces(facility)
	if not facility.built:
		%FacilityState.text = _progress_text(facility)
	elif producing:
		%FacilityState.text = _production_text(facility)
	else:
		%FacilityState.text = "已完工"
	%PriorityRow.visible = not facility.built or producing
	%FacilityCancel.visible = not facility.built
	%FacilityDemolish.visible = facility.built
	%FacilityPause.visible = producing
	if producing:
		%FacilityPriority.select(%FacilityPriority.get_item_index(facility.production_priority))
		%FacilityPause.text = _pause_text(facility)
	elif not facility.built:
		%FacilityPriority.select(%FacilityPriority.get_item_index(facility.priority))
	%InfoPanel.reset_size()


## A finished facility that makes something (feature 005, R6).
func _produces(facility: Facility) -> bool:
	return facility.built and production != null and FacilityCatalog.product_of(facility.kind) != -1


func _production_text(facility: Facility) -> String:
	var text := "生產 %s · 進度 %d%%" % [
		PRODUCT_NAMES[FacilityCatalog.product_of(facility.kind)],
		floori(production.progress_of(facility.id) * 100.0)]
	if facility.paused:
		text += "（已暫停）"
	return text


func _pause_text(facility: Facility) -> String:
	return "恢復生產" if facility.paused else "暫停生產"


func _on_pause_production_pressed() -> void:
	var facility := construction.find(_shown_facility) if construction else null
	if facility:
		facility_pause_requested.emit(_shown_facility, not facility.paused)


func _progress_text(facility: Facility) -> String:
	return "建造中 %d%%" % floori(construction.progress_of(facility.id) * 100.0)


func _on_facility_priority_selected(index: int) -> void:
	facility_priority_requested.emit(_shown_facility, %FacilityPriority.get_item_id(index))


## The task rows as plain text, one line each (for tests and debugging).
func info_tasks_text() -> String:
	var lines: Array[String] = []
	for label in %InfoTasks.find_children("*", "Label", true, false):
		lines.append(label.text)
	return "\n".join(lines)


## The colonist's needs and incapacitated mark (feature 003) belong to the
## colonist view only; a blueprint or facility (feature 004) hides them.
func _show_needs_sections(shown: bool) -> void:
	for section in [%InfoBodyTitle, %InfoBody, %InfoMindTitle, %InfoMind]:
		section.visible = shown
	if not shown:
		%InfoStatus.visible = false


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
		if tasks.current:
			ids.append(tasks.current.priority)  # a build job's priority can change (feature 004, R4)
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
	if task.producing:
		# Production jobs are managed on the facility too (feature 005, R6).
		var maker := construction.find(task.facility_id) if construction else null
		var maker_name := FacilityCatalog.display_name(maker.kind) if maker else "設施"
		label.text = "  生產 %s · 優先度 %d" % [maker_name, task.priority]
		return
	if task.is_build():
		# Build jobs are managed on the blueprint, not here (feature 004, R8, I4).
		var facility := construction.find(task.facility_id) if construction else null
		var facility_name := FacilityCatalog.display_name(facility.kind) if facility else "設施"
		label.text = "  建造 %s · 優先度 %d" % [facility_name, task.priority]
		return
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
