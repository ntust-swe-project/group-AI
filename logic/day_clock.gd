class_name DayClock
extends RefCounted

## Game time in days. Pure logic: the scene calls advance() every frame.
## See docs/specs/features/001-base-skeleton.md (R1, R2, R8).

const SECONDS_PER_DAY := 300.0  # real seconds per day at 1x (Q1)
const FINAL_DAY := 30
const MIN_SPEED := 0.5
const MAX_SPEED := 4.0
const SPEED_STEP := 0.5

var day := 1
var paused := false
## Always a multiple of SPEED_STEP within [MIN_SPEED, MAX_SPEED].
var speed := 1.0:
	set(value):
		speed = clampf(snappedf(value, SPEED_STEP), MIN_SPEED, MAX_SPEED)

var _seconds_into_day := 0.0
var _finished := false


func advance(real_seconds: float) -> void:
	if paused or _finished:
		return
	_seconds_into_day += real_seconds * speed
	while _seconds_into_day >= SECONDS_PER_DAY:
		_seconds_into_day -= SECONDS_PER_DAY
		if day == FINAL_DAY:
			_finished = true
			_seconds_into_day = 0.0
			return
		day += 1


## Debug (feature 001, R10): jump to the start of the next day, even while
## paused. Skipping the final day ends the run.
func skip_day() -> void:
	if _finished:
		return
	_seconds_into_day = 0.0
	if day == FINAL_DAY:
		_finished = true
	else:
		day += 1


## True once the final day has fully passed (R2: survive day 30, not just reach it).
func is_finished() -> bool:
	return _finished


func speed_up() -> void:
	speed += SPEED_STEP


func slow_down() -> void:
	speed -= SPEED_STEP
