class_name Psychology
extends RefCounted

## A colonist's mind (feature 003, R1, R4): two needs from 0 to 100. Stress is
## worse when high, Mood is better when high (Q1); a new colonist is calm and
## content. Kept apart from Physiology: the data layer must not merge the two
## (SYSTEM.md SC2), so this class takes plain flags, not the body itself.
## Pure logic; time is game time.

const MIN := 0.0
const MAX := 100.0

## Days for each to go end to end, either way (R4).
const STRESS_DAYS := 1.0
const MOOD_DAYS := 1.0

var stress := MIN
var mood := MAX


## Lets `seconds` of game time pass. Stress rises while the colonist is on a
## player's order and falls otherwise (I3); Mood falls while any body need is
## low and recovers otherwise (I2).
func advance(seconds: float, on_order: bool, body_low: bool) -> void:
	var stress_step := _per_second(STRESS_DAYS) * seconds
	stress = clampf(stress + (stress_step if on_order else -stress_step), MIN, MAX)
	var mood_step := _per_second(MOOD_DAYS) * seconds
	mood = clampf(mood + (-mood_step if body_low else mood_step), MIN, MAX)


static func _per_second(days: float) -> float:
	return (MAX - MIN) / (days * DayClock.SECONDS_PER_DAY)
