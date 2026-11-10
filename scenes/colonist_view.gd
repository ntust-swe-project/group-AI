extends Node2D

## A colonist on the map: a dot with a name under it (wireframe only).

const RADIUS := 11.0
const BODY_COLOR := Color(0.95, 0.75, 0.3)

var colonist: Colonist:
	set(value):
		colonist = value
		if is_node_ready():
			$NameLabel.text = colonist.name


func _ready() -> void:
	add_to_group("colonist_views")
	if colonist:
		$NameLabel.text = colonist.name


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, BODY_COLOR)
