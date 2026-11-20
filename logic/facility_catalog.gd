class_name FacilityCatalog
extends RefCounted

## What can be built (feature 004, R1; 005 R4, R7): name, build-menu category,
## size, build time, material cost and what it produces. Sizes are width x height in cells; there is no rotating (Q1).

enum Kind { HYGIENE_STALL, SLEEP_POD, HYDROPONICS_BAY, WATER_RECYCLER, FABRICATOR }

## Build-menu categories, top to bottom.
const CATEGORIES: Array[String] = ["生活", "生產"]

const _DATA := {
	Kind.HYGIENE_STALL: {"name": "衛生艙", "category": "生活", "size": Vector2i(1, 1), "build_days": 0.2, "cost": 5},
	Kind.SLEEP_POD: {"name": "睡眠艙", "category": "生活", "size": Vector2i(1, 2), "build_days": 0.2, "cost": 10},
	# Q2, Q4: each production facility is 2x2, 10 materials, 0.2 game days.
	Kind.HYDROPONICS_BAY: {"name": "水耕艙", "category": "生產", "size": Vector2i(2, 2), "build_days": 0.2,
			"cost": 10, "product": Stockpile.Kind.FOOD},
	Kind.WATER_RECYCLER: {"name": "水回收機", "category": "生產", "size": Vector2i(2, 2), "build_days": 0.2,
			"cost": 10, "product": Stockpile.Kind.WATER},
	Kind.FABRICATOR: {"name": "製造站", "category": "生產", "size": Vector2i(2, 2), "build_days": 0.2,
			"cost": 10, "product": Stockpile.Kind.MATERIALS},
}


static func display_name(kind: Kind) -> String:
	return _DATA[kind]["name"]


static func size_of(kind: Kind) -> Vector2i:
	return _DATA[kind]["size"]


## Game seconds one builder needs (Q2: 0.2 game days for both kinds).
static func build_seconds(kind: Kind) -> float:
	return _DATA[kind]["build_days"] * DayClock.SECONDS_PER_DAY


## R7: materials it costs to place.
static func cost_of(kind: Kind) -> int:
	return _DATA[kind]["cost"]


## R4: the `Stockpile.Kind` it produces, or -1 if it produces nothing.
static func product_of(kind: Kind) -> int:
	return _DATA[kind].get("product", -1)


## The kinds listed under `category`, in menu order.
static func kinds_in(category: String) -> Array[Kind]:
	var kinds: Array[Kind] = []
	for kind in Kind.values():
		if _DATA[kind]["category"] == category:
			kinds.append(kind)
	return kinds
