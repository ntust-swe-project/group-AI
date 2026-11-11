extends Node2D

## Owns the logic objects and drives them each frame (feature 001).
## Logic lives in logic/; this script only connects it to what is on screen.

const ColonistView := preload("res://scenes/colonist_view.tscn")

var clock := DayClock.new()
var grid := StationGrid.make_hall()
var colony := Colony.new()
var wanderers := {}  # colonist id -> Wanderer
var board := AssignmentBoard.new(grid)
var points := SupplyPoints.new()
var care := ColonistCare.new(board, points, colony)
var construction := Construction.new(grid, board)

var _views := {}  # colonist id -> colonist view node
var _selected_id := -1  # the colonist in the info panel, or -1
var _rng := RandomNumberGenerator.new()
var _placing := -1  # the FacilityCatalog.Kind being placed, or -1 (feature 004, R2)

@onready var station_map: Node2D = $StationMap
@onready var hud: CanvasLayer = $Hud
@onready var assign_menu: Control = $Hud/%AssignMenu
@onready var context_menu: Control = $Hud/%ContextMenu
@onready var build_menu: Control = $Hud/%BuildMenu


func _ready() -> void:
	station_map.grid = grid
	station_map.supply_points = points
	hud.clock = clock
	hud.add_colonist_requested.connect(_on_add_colonist_requested)
	context_menu.assign_chosen.connect(_on_assign_chosen)
	assign_menu.assign_requested.connect(_on_assign_requested)
	hud.cancel_task_requested.connect(_on_cancel_task_requested)
	build_menu.kind_chosen.connect(_start_placing)
	build_menu.opened.connect(func():
		context_menu.close()
		assign_menu.close())
	station_map.construction = construction
	hud.construction = construction
	hud.facility_priority_requested.connect(construction.set_priority)
	hud.facility_cancel_requested.connect(_on_facility_cancel_requested)
	hud.facility_demolish_requested.connect(_on_facility_demolish_requested)
	hud.refresh()
	station_map.position = ((get_viewport_rect().size - station_map.pixel_size()) / 2.0).round()
	for colonist in colony.colonists:
		_show_colonist(colonist)


func _process(delta: float) -> void:
	# Colonists move in game time: frozen while paused or after day 30, faster at higher speed.
	var game_seconds := 0.0 if clock.paused or clock.is_finished() else delta * clock.speed
	clock.advance(delta)
	# Needs, walking, supplies, breakdowns and deaths all happen here (feature 003).
	# ColonistCare already moved every colonist; nothing else may move them again.
	for id in care.advance(game_seconds):
		_forget_colonist(id)
	# Building counts game time too, so nothing is built while paused (004 A4).
	construction.advance(game_seconds)
	construction.assign_builders()
	for id in wanderers:
		_views[id].position = station_map.cell_to_pixel(wanderers[id].position())


func _on_add_colonist_requested() -> void:
	_close_menus()  # the assignment menu's colonist list would be out of date
	_show_colonist(colony.add_colonist())


func _unhandled_input(event: InputEvent) -> void:
	if _placing != -1 and _handle_placing_input(event):
		get_viewport().set_input_as_handled()
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	var map_point := station_map.to_local(click.position)
	if click.button_index == MOUSE_BUTTON_RIGHT:
		_open_context_menu(_cell_at(map_point), click.position)
		get_viewport().set_input_as_handled()
		return
	if click.button_index != MOUSE_BUTTON_LEFT:
		return
	_close_menus()
	var colonist := colonist_at(map_point)
	var facility := construction.at(_cell_at(map_point))
	if colonist:
		_selected_id = colonist.id
		hud.show_colonist(colonist, wanderers[colonist.id].tasks)
		station_map.highlight(wanderers[colonist.id].tasks)
	elif facility:
		_selected_id = -1
		hud.show_facility(facility.id)
		station_map.highlight(null)
	else:
		_selected_id = -1
		hud.hide_info()
		station_map.highlight(null)
	get_viewport().set_input_as_handled()


## The colonist whose dot is nearest to a point in map coordinates, if any is
## within about half a cell of it.
func colonist_at(map_point: Vector2) -> Colonist:
	var best: Colonist = null
	var best_distance: float = station_map.CELL_SIZE * 0.6
	for id in _views:
		var distance: float = _views[id].position.distance_to(map_point)
		if distance <= best_distance:
			best = _views[id].colonist
			best_distance = distance
	return best


func _show_colonist(colonist: Colonist) -> void:
	var walker := Wanderer.new(grid, _free_floor_cell(), _rng)
	wanderers[colonist.id] = walker
	board.register(colonist.id, walker)
	care.register(colonist, walker)
	var view := ColonistView.instantiate()
	view.colonist = colonist
	view.position = station_map.cell_to_pixel(walker.position())
	station_map.add_child(view)
	_views[colonist.id] = view


## A colonist died (feature 003, R9): take their dot off the map, close the
## menus (their colonist list would be out of date) and the info panel if it
## was showing them. The colony and the board already let go.
func _forget_colonist(id: int) -> void:
	_close_menus()
	wanderers.erase(id)
	var view: Node = _views[id]
	_views.erase(id)
	station_map.remove_child(view)  # out of the tree now, not at the end of the frame
	view.queue_free()
	if id == _selected_id:
		_selected_id = -1
		hud.hide_info()
		station_map.highlight(null)


## A random walkable cell no colonist stands on, or any walkable cell if all
## are taken. Never inside a facility (feature 004, R7).
func _free_floor_cell() -> Vector2i:
	var taken := {}
	for walker in wanderers.values():
		taken[walker.cell] = true
	var cells := grid.walkable_cells().filter(func(c): return not taken.has(c))
	if cells.is_empty():
		cells = grid.walkable_cells()
	return cells[_rng.randi_range(0, cells.size() - 1)]


# --- feature 002: assignments ---

## Right-click: the context menu opens where at least one of its actions
## applies. Its only action, 指派工作, needs floor someone can reach (R6).
func _open_context_menu(cell: Vector2i, screen_position: Vector2) -> void:
	_close_menus()
	if board.can_assign_at(cell):
		context_menu.open(cell, screen_position)


func _close_menus() -> void:
	context_menu.close()
	assign_menu.close()
	build_menu.close()


func _on_assign_chosen() -> void:
	_open_assign_menu(context_menu.cell, context_menu.opened_at)


func _open_assign_menu(cell: Vector2i, screen_position: Vector2) -> void:
	if not board.can_assign_at(cell):
		assign_menu.close()
		return
	var reachable := board.who_can_reach(cell)
	var people: Array[Colonist] = colony.colonists.filter(func(c): return reachable.has(c.id))
	assign_menu.open(cell, screen_position, people)


func _on_assign_requested(colonist_id: int, priority: int) -> void:
	board.create(colonist_id, assign_menu.cell, priority)
	assign_menu.close()


func _on_cancel_task_requested(assignment_id: int) -> void:
	board.cancel(assignment_id)


# --- feature 004: placing blueprints ---

func _on_facility_cancel_requested(facility_id: int) -> void:
	construction.cancel(facility_id)
	hud.hide_info()


func _on_facility_demolish_requested(facility_id: int) -> void:
	construction.demolish(facility_id)
	hud.hide_info()


## The kind being placed, or -1 when not placing.
func placing_kind() -> int:
	return _placing


func _start_placing(kind: FacilityCatalog.Kind) -> void:
	_close_menus()
	hud.hide_info()
	station_map.highlight(null)
	_placing = kind
	_update_ghost(_cell_at(station_map.get_local_mouse_position()))


func _stop_placing() -> void:
	_placing = -1
	station_map.clear_ghost()


## R2: the ghost follows the mouse, left click places (and keeps placing),
## right click or Esc stops. Returns true when the event was used.
func _handle_placing_input(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key:
		if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
			_stop_placing()
			return true
		return false
	if event is InputEventMouseMotion:
		_update_ghost(_cell_at(station_map.to_local(event.position)))
		return false
	var click := event as InputEventMouseButton
	if click == null or not click.pressed:
		return false
	if click.button_index == MOUSE_BUTTON_RIGHT:
		_stop_placing()
		return true
	if click.button_index == MOUSE_BUTTON_LEFT:
		var cell := _cell_at(station_map.to_local(click.position))
		construction.place(_placing as FacilityCatalog.Kind, cell)
		_update_ghost(cell)
		return true
	return false


func _update_ghost(cell: Vector2i) -> void:
	var kind := _placing as FacilityCatalog.Kind
	station_map.set_ghost(kind, cell, construction.can_place(kind, cell))


func _cell_at(map_point: Vector2) -> Vector2i:
	return Vector2i((map_point / station_map.CELL_SIZE).floor())
