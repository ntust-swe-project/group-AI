class_name Physiology
extends RefCounted

## A colonist's body (feature 003, R1, R2): five needs from 0 to 100, higher is
## better, all full at the start. Kept apart from Psychology: the data layer
## must not merge the two (SYSTEM.md SC2). Pure logic; time is game time.

const EMPTY := 0.0
const FULL := 100.0

## Days for a need to fall from full to empty (Q2), staggered on purpose so the
## colonists do not all go for supplies at once. BodyTemp does not fall: it
## waits for zones and event flags (SC7). Stamina follows what the colonist is
## doing, not the clock alone (R3, task T2).
const HUNGER_DAYS := 1.5
const THIRST_DAYS := 1.0
const RELIEF_DAYS := 1.0

var hunger := FULL
var thirst := FULL
var body_temp := FULL
var relief := FULL
var stamina := FULL


## Lets `seconds` of game time pass. The scene passes 0 while paused and more
## at higher speed, so this class never needs to know about either (A2).
func advance(seconds: float) -> void:
	hunger = maxf(EMPTY, hunger - per_second(HUNGER_DAYS) * seconds)
	thirst = maxf(EMPTY, thirst - per_second(THIRST_DAYS) * seconds)
	relief = maxf(EMPTY, relief - per_second(RELIEF_DAYS) * seconds)


## How much a need falls per game second if it takes `days` to empty. The day
## length comes from DayClock, so changing it there changes this too.
static func per_second(days: float) -> float:
	return FULL / (days * DayClock.SECONDS_PER_DAY)
