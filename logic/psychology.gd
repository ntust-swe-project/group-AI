class_name Psychology
extends RefCounted

## A colonist's mind (feature 003, R1): two needs from 0 to 100. Stress is
## worse when high, Mood is better when high (Q1); a new colonist is calm and
## content. Kept apart from Physiology: the data layer must not merge the two
## (SYSTEM.md SC2). How they change with time comes in task T2 (R4). Pure logic.

const MIN := 0.0
const MAX := 100.0

var stress := MIN
var mood := MAX
