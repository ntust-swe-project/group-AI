extends Node2D

## A colonist on the map: a dot with a name under it (wireframe only). The dot
## turns grey once the colonist is incapacitated (feature 003, R10).

const RADIUS := 11.0
const BODY_COLOR := Color(0.95, 0.75, 0.3)
const INCAPACITATED_COLOR := Color(0.5, 0.5, 0.5)

var colonist: Colonist:
	set(value):
		colonist = value
		if is_node_ready():
			$NameLabel.text = colonist.name

var _drawn_incapacitated := false  # what the dot was last drawn as


func _ready() -> void:
	add_to_group("colonist_views")
	if colonist:
		$NameLabel.text = colonist.name


func _process(_delta: float) -> void:
	if colonist and colonist.incapacitated != _drawn_incapacitated:
		_drawn_incapacitated = colonist.incapacitated
		queue_redraw()


func body_color() -> Color:
	return INCAPACITATED_COLOR if colonist and colonist.incapacitated else BODY_COLOR


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, body_color())
