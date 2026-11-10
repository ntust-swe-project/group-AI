extends Node2D

## Owns the logic objects and drives them each frame (feature 001).
## Logic lives in logic/; this script only connects it to what is on screen.

const ColonistView := preload("res://scenes/colonist_view.tscn")

var clock := DayClock.new()
var grid := StationGrid.make_hall()
var colony := Colony.new()
var wanderers := {}  # colonist id -> Wanderer
var board := AssignmentBoard.new(grid)

var _views := {}  # colonist id -> colonist view node
var _menu_entries := []  # what the open assignment menu lists
var _rng := RandomNumberGenerator.new()

@onready var station_map: Node2D = $StationMap
@onready var hud: CanvasLayer = $Hud
@onready var assign_menu: Control = $Hud/%AssignMenu
@onready var context_menu: Control = $Hud/%ContextMenu


func _ready() -> void:
	station_map.grid = grid
	hud.clock = clock
	hud.add_colonist_requested.connect(_on_add_colonist_requested)
	context_menu.assign_chosen.connect(_on_assign_chosen)
	assign_menu.assign_requested.connect(_on_assign_requested)
	assign_menu.cancel_requested.connect(_on_cancel_requested)
	hud.refresh()
	station_map.position = ((get_viewport_rect().size - station_map.pixel_size()) / 2.0).round()
	for colonist in colony.colonists:
		_show_colonist(colonist)


func _process(delta: float) -> void:
	# Colonists move in game time: frozen while paused or after day 30, faster at higher speed.
	var game_seconds := 0.0 if clock.paused or clock.is_finished() else delta * clock.speed
	clock.advance(delta)
	for id in wanderers:
		wanderers[id].advance(game_seconds)
		_views[id].position = station_map.cell_to_pixel(wanderers[id].position())
	if assign_menu.visible:
		_refresh_assign_menu()


func _on_add_colonist_requested() -> void:
	_close_menus()  # the assignment menu's colonist list would be out of date
	_show_colonist(colony.add_colonist())


func _unhandled_input(event: InputEvent) -> void:
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
	if colonist:
		hud.show_colonist(colonist, wanderers[colonist.id].tasks)
		station_map.highlight(wanderers[colonist.id].tasks)
	else:
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
	var view := ColonistView.instantiate()
	view.colonist = colonist
	view.position = station_map.cell_to_pixel(walker.position())
	station_map.add_child(view)
	_views[colonist.id] = view


## A random floor cell no colonist stands on, or any floor cell if all are taken.
func _free_floor_cell() -> Vector2i:
	var taken := {}
	for walker in wanderers.values():
		taken[walker.cell] = true
	var cells := grid.floor_cells().filter(func(c): return not taken.has(c))
	if cells.is_empty():
		cells = grid.floor_cells()
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


func _on_assign_chosen() -> void:
	_open_assign_menu(context_menu.cell, context_menu.opened_at)


func _open_assign_menu(cell: Vector2i, screen_position: Vector2) -> void:
	if not board.can_assign_at(cell):
		assign_menu.close()
		return
	var reachable := board.who_can_reach(cell)
	var people: Array[Colonist] = colony.colonists.filter(func(c): return reachable.has(c.id))
	_menu_entries = _existing_at(cell)
	assign_menu.open(cell, screen_position, people, _menu_entries)


func _on_assign_requested(colonist_id: int, priority: int) -> void:
	board.create(colonist_id, assign_menu.cell, priority)
	assign_menu.close()


func _on_cancel_requested(assignment_id: int) -> void:
	board.cancel(assignment_id)
	_refresh_assign_menu()


## Keep the open menu's list current: assignments finish while it is open.
func _refresh_assign_menu() -> void:
	var entries := _existing_at(assign_menu.cell)
	if entries != _menu_entries:
		_menu_entries = entries
		assign_menu.show_existing(entries)


func _existing_at(cell: Vector2i) -> Array:
	var entries := []
	for task in board.at(cell):
		var owner_id := board.owner_of(task.id)
		entries.append({"id": task.id, "name": _colonist(owner_id).name, "priority": task.priority})
	return entries


func _colonist(colonist_id: int) -> Colonist:
	for colonist in colony.colonists:
		if colonist.id == colonist_id:
			return colonist
	return null


func _cell_at(map_point: Vector2) -> Vector2i:
	return Vector2i((map_point / station_map.CELL_SIZE).floor())
