class_name FacilityCatalog
extends RefCounted

## What can be built (feature 004, R1): name, build-menu category and size.
## Sizes are width x height in cells; there is no rotating (Q1).

enum Kind { HYGIENE_STALL, SLEEP_POD }

## Build-menu categories, top to bottom.
const CATEGORIES: Array[String] = ["生活"]

const _DATA := {
	Kind.HYGIENE_STALL: {"name": "衛生艙", "category": "生活", "size": Vector2i(1, 1)},
	Kind.SLEEP_POD: {"name": "睡眠艙", "category": "生活", "size": Vector2i(1, 2)},
}


static func display_name(kind: Kind) -> String:
	return _DATA[kind]["name"]


static func size_of(kind: Kind) -> Vector2i:
	return _DATA[kind]["size"]


## The kinds listed under `category`, in menu order.
static func kinds_in(category: String) -> Array[Kind]:
	var kinds: Array[Kind] = []
	for kind in Kind.values():
		if _DATA[kind]["category"] == category:
			kinds.append(kind)
	return kinds
