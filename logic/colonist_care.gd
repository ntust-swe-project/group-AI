class_name ColonistCare
extends RefCounted

## Looks after every colonist's needs each frame (feature 003): lets the needs
## change with what the colonist is doing, moves them, refills a need when its
## supply work is done, asks for supplies when a need gets low, and decides who
## is incapacitated and who dies. Pure logic; time is game time.

## Supply work is as urgent as a middling order: a player's 4-5 cuts in, a
## 1-2 waits (Q4).
const SUPPLY_PRIORITY := 3

var _board: AssignmentBoard
var _points: SupplyPoints
var _colony: Colony
var _colonists := {}  # colonist id -> Colonist
var _walkers := {}  # colonist id -> Wanderer


func _init(board: AssignmentBoard, points: SupplyPoints, colony: Colony) -> void:
	_board = board
	_points = points
	_colony = colony


## The colonist must already be registered with the board under the same id.
func register(colonist: Colonist, walker: Wanderer) -> void:
	_colonists[colonist.id] = colonist
	_walkers[colonist.id] = walker


## In this order, so a need that is refilled ends the call at exactly full and
## a need that drops under the line is asked for in the same call (A4):
## needs change for what the colonist was doing, then a colonist who has broken
## down is incapacitated (and dies if hunger and thirst are both out), then the
## rest move and work, finished supply work refills, and low needs ask for
## supplies. Returns the ids of the colonists who died in this call; they are
## already out of the colony.
func advance(seconds: float) -> Array[int]:
	var died: Array[int] = []
	for id in _colonists.keys():
		var colonist: Colonist = _colonists[id]
		var walker: Wanderer = _walkers[id]
		var task := walker.tasks.current
		var on_order := task != null and task.need == &""
		var working := task != null and not _is_sleeping(walker)
		colonist.physiology.advance(seconds, working)
		colonist.psychology.advance(seconds, on_order, colonist.physiology.any_low())
		if not colonist.incapacitated and _has_broken_down(colonist):
			_incapacitate(id, colonist, walker)
		if colonist.incapacitated:
			# Does not move or ask for anything; the needs go on falling (R9).
			if colonist.physiology.hunger <= Physiology.EMPTY and colonist.physiology.thirst <= Physiology.EMPTY:
				died.append(id)
			continue
		for done in walker.advance(seconds):
			if done.need != &"":
				colonist.physiology.set(done.need, Physiology.FULL)
		_ask_for_supplies(id, colonist, walker)
	for id in died:
		_colonists.erase(id)
		_walkers.erase(id)
		_colony.remove_colonist(id)
	return died


## Any body need empty, Stress full, or Mood empty (R8, Q7).
func _has_broken_down(colonist: Colonist) -> bool:
	var body := colonist.physiology
	var mind := colonist.psychology
	for value in [body.hunger, body.thirst, body.body_temp, body.relief, body.stamina]:
		if value <= Physiology.EMPTY:
			return true
	return mind.stress >= Psychology.MAX or mind.mood <= Psychology.MIN


## Cancels every task, then takes the colonist off the board so no order can
## reach them and the menu no longer lists them (R8, Q8). Never undone (Q9).
func _incapacitate(id: int, colonist: Colonist, walker: Wanderer) -> void:
	colonist.incapacitated = true
	var tasks := walker.tasks.queued()
	if walker.tasks.current:
		tasks.push_front(walker.tasks.current)
	for task in tasks:
		walker.cancel(task.id)
	_board.unregister(id)


## Asleep means at the sleep pod with the sleep task, not on the way to it:
## walking there is work (R3).
func _is_sleeping(walker: Wanderer) -> bool:
	var task := walker.tasks.current
	return task != null and task.need == &"stamina" \
			and walker.cell == task.cell and walker.remaining_steps() == 0.0


## One supply task per low need at a time (R6). If the point cannot be reached
## the board refuses, and the next call tries again.
func _ask_for_supplies(id: int, colonist: Colonist, walker: Wanderer) -> void:
	for need in SupplyPoints.NEEDS:
		if colonist.physiology.get(need) < Physiology.LOW and not _has_supply_task(walker, need):
			_board.create(id, _points.cell_for(need), SUPPLY_PRIORITY, need, _points.work_seconds(need))


func _has_supply_task(walker: Wanderer, need: StringName) -> bool:
	if walker.tasks.current and walker.tasks.current.need == need:
		return true
	return walker.tasks.queued().any(func(task): return task.need == need)
