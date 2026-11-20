extends GutTest

# A1 of docs/specs/features/005-resources.md: the shared stock (R1, Q1).

var stock: Stockpile


func before_each():
	stock = Stockpile.new()


func test_a_new_game_starts_with_the_q1_stock():
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 6)
	assert_eq(stock.amount(Stockpile.Kind.WATER), 8)
	assert_eq(stock.amount(Stockpile.Kind.MATERIALS), 30)


func test_add_raises_one_resource_only():
	stock.add(Stockpile.Kind.FOOD, 4)
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 10)
	assert_eq(stock.amount(Stockpile.Kind.WATER), 8)


func test_take_lowers_the_amount():
	assert_true(stock.take(Stockpile.Kind.MATERIALS, 10))
	assert_eq(stock.amount(Stockpile.Kind.MATERIALS), 20)


func test_take_exactly_everything_reaches_zero():
	assert_true(stock.take(Stockpile.Kind.WATER, 8))
	assert_eq(stock.amount(Stockpile.Kind.WATER), 0)


func test_taking_more_than_held_fails_and_changes_nothing():
	assert_false(stock.take(Stockpile.Kind.FOOD, 7))
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 6, "never goes negative")


func test_there_is_no_upper_limit():
	stock.add(Stockpile.Kind.MATERIALS, 100000)
	assert_eq(stock.amount(Stockpile.Kind.MATERIALS), 100030)


func test_adding_a_negative_amount_is_reported_and_changes_nothing():
	stock.add(Stockpile.Kind.FOOD, -5)
	assert_push_error("must not be negative")
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 6)


func test_taking_a_negative_amount_is_reported_and_refused():
	assert_false(stock.take(Stockpile.Kind.FOOD, -5))
	assert_push_error("must not be negative")
	assert_eq(stock.amount(Stockpile.Kind.FOOD), 6)
