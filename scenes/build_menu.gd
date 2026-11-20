extends Control

## Build menu in the bottom-right corner (feature 004, R1): 建造 opens the
## categories above it; a category lists its facilities to the left. Choosing
## one folds the menu and asks main to start placing it.

signal kind_chosen(kind: FacilityCatalog.Kind)
signal opened  # 建造 was pressed and the categories are now showing

const BUTTON_SIZE := Vector2(120, 36)

## Set by main: costs are charged and unaffordable facilities greyed out
## (feature 005, R8). Without it every button stays enabled.
var construction: Construction

var _kind_buttons := {}  # FacilityCatalog.Kind -> Button, for the list now showing


func _ready() -> void:
	%BuildButton.pressed.connect(toggle)
	for category in FacilityCatalog.CATEGORIES:
		var button := _make_button(category)
		button.pressed.connect(open_category.bind(category))
		%CategoryList.add_child(button)


## 建造: open the categories, or fold everything if they are open.
func toggle() -> void:
	if %CategoryList.visible:
		close()
	else:
		%CategoryList.visible = true
		opened.emit()


func _process(_delta: float) -> void:
	if %KindList.visible:
		_update_affordable()


func close() -> void:
	%CategoryList.visible = false
	%KindList.visible = false


func open_category(category: String) -> void:
	for child in %KindList.get_children():
		%KindList.remove_child(child)
		child.queue_free()
	_kind_buttons.clear()
	for kind in FacilityCatalog.kinds_in(category):
		var button := _make_button("%s（%d）" % [FacilityCatalog.display_name(kind), FacilityCatalog.cost_of(kind)])
		button.pressed.connect(_on_kind_pressed.bind(kind))
		%KindList.add_child(button)
		_kind_buttons[kind] = button
	%KindList.visible = true
	_update_affordable()


## R8: a facility the materials do not cover cannot be chosen. Every frame,
## because materials change while the list is open.
func _update_affordable() -> void:
	for kind in _kind_buttons:
		_kind_buttons[kind].disabled = construction != null and not construction.can_afford(kind)


func _on_kind_pressed(kind: FacilityCatalog.Kind) -> void:
	close()
	kind_chosen.emit(kind)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	button.focus_mode = Control.FOCUS_NONE
	return button
