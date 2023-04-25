extends Node

enum ITEM { BLOCK = 1, PARACHUTE = 2, OIL = 3, STRENGTH = 4, SLINGSHOT = 5, GRIFFIN = 6}

const MAX_BLOCK_HEIGHT = 14
const MAX_OIL_LEVEL = 3
const MAX_STRENGTH_LEVEL = 6

# Learn to fly has each level approximately double, but with substantial jitter
# so that this isn't super obvious.  This is probably the best fit for 'strength'
# for us; we want block height to be a little more attainable.

static func next_block_cost():
	match State.block_height:
		0: return 60
		1: return 90
		2: return 125
		3: return 270
		4: return 400
		5: return 500
		6: return 675
		7: return 750
		8: return 800
		9: return 850
		10: return 900
		11: return 1050
		12: return 1100
		13: return 1200
		14: return 0
		_:
			print("unexpected current block height")
			return 0

static func next_strength_cost():
	# We should update these numbers to diverge from block cost
	match State.strength_level:
		0: return 85
		1: return 200
		2: return 450
		3: return 600
		4: return 900
		5: return 1800
		6: return 0
		_:
			print("unexpected current strength")
			return 0

static func next_oil_cost():
	match State.oil_level:
		0: return 40
		1: return 250
		2: return 500
		3: return 0
		_:
			print("unexpected current oil level")
			return 0

static func next_oil_description():
	match State.oil_level:
		0: return "Don't lose any speed on your first bounce"
		1: return "Don't lose any speed on your first 2 bounces"
		2, 3: return "Don't lose any speed on your first 3 bounces"
		_:
			print("unexpected current oil level")
			return "Oiliness: 0"

static func _description(kind) -> String:
	match kind:
		ITEM.BLOCK:
			return "Launching the boulder from a higher height means it goes farther, right?"
		ITEM.PARACHUTE:
			return "Deploy with '1'. Slows your descent but reduces your speed."
		ITEM.OIL:
			return next_oil_description()
		ITEM.STRENGTH:
			return "Get a little more swole and hit the boulder even farther"
		ITEM.SLINGSHOT:
			return "Click on the boulder to use. Allows you adjust the trajectory of the boulder slightly while it's in flight.  Comes with 4 shots."
		ITEM.GRIFFIN:
			return "Deploy with '2'. Hire a griffin to carry your boulder up the hill for a bit."
		_:
			return "unknown"

static func description(kind):
	var base = _description(kind)
	if not_at_max_level(kind):
		return base
	else:
		return "You've maxed out this upgrade!\n\n%s" % base

static func max_level (kind) -> int:
	match kind:
		ITEM.BLOCK:	return MAX_BLOCK_HEIGHT
		ITEM.PARACHUTE: return 1
		ITEM.OIL: return MAX_OIL_LEVEL
		ITEM.STRENGTH: return MAX_STRENGTH_LEVEL
		ITEM.SLINGSHOT: return 1
		ITEM.GRIFFIN: return 1
		_:
			return 0

static func current_level (kind) -> int:
	match kind:
		ITEM.BLOCK:	return State.block_height
		ITEM.PARACHUTE: return 1 if  State.has_parachute else 0
		ITEM.OIL: return State.oil_level
		ITEM.STRENGTH: return State.strength_level
		ITEM.SLINGSHOT: return 1 if State.has_slingshot else 0
		ITEM.GRIFFIN: return 1 if State.has_griffin else 0
		_:
			return 0

static func not_at_max_level(kind) -> bool:
	return current_level(kind) < max_level(kind)

static func next_level(kind) -> int:
	var max_level_ = max_level(kind)
	return int(min(current_level(kind) + 1, max_level_))

static func parachute_cost():
	return 250

static func slingshot_cost():
	return 600

static func griffin_cost():
	return 2500

static func cost(kind) -> int:
	match kind:
		ITEM.BLOCK:
			return next_block_cost()
		ITEM.PARACHUTE:
			return parachute_cost()
		ITEM.OIL:
			return next_oil_cost()
		ITEM.STRENGTH:
			return next_strength_cost()
		ITEM.SLINGSHOT:
			return slingshot_cost()
		ITEM.GRIFFIN:
			return griffin_cost()
		_:	
			return 0

# Maybe this could indicate when you're maxed
static func name(kind) -> String:
	match kind:
		ITEM.BLOCK:
			if not_at_max_level(kind):
				return "Height: %d" % next_level(kind)
			else:
				return "Height"
		ITEM.PARACHUTE:
			return "Parachute"
		ITEM.OIL:
			if not_at_max_level(kind):
				return "Oiliness: %d" % next_level(kind)
			else:
				return "Oiliness"
		ITEM.STRENGTH:
			if not_at_max_level(kind):
				return "Strength: %d" % next_level(kind)
			else:
				return "Strength"
		ITEM.SLINGSHOT:
			return "Slingshot"
		ITEM.GRIFFIN:
			return "Griffin"
		_:
			return "unknown"

static func _update_state_after_purchase(kind) -> void:
	match kind:
		ITEM.BLOCK:
			State.block_height += 1
		ITEM.PARACHUTE:
			State.has_parachute = true
			State.display_fact_if_we_havent_yet(State.FACT.PARACHUTE)
		ITEM.OIL:
			State.oil_level += 1
		ITEM.STRENGTH:
			State.strength_level += 1
		ITEM.SLINGSHOT:
			State.has_slingshot = true
			State.display_fact_if_we_havent_yet(State.FACT.SLINGSHOT)
		ITEM.GRIFFIN:
			State.has_griffin = true
			State.display_fact_if_we_havent_yet(State.FACT.GRIFFIN)
		_:
			print("unexpected item kind")

static func can_purchase(kind):
	var cost_ = cost(kind)
	if cost_ == 0 or not State.can_purchase(cost_):
		return false
	return not_at_max_level(kind)

static func purchase(kind):
	var cost_ = cost(kind)
	if not can_purchase(kind): return false
	var made_purchase = State.try_make_purchase(cost_)
	if not made_purchase:
		print("unexpectedly failed to make purchase")
		return false
	_update_state_after_purchase(kind)
	return true

