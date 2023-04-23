extends Node

enum ITEM { BLOCK = 1, PARACHUTE = 2, OIL = 3, STRENGTH = 4, SLINGSHOT = 5}

const MAX_BLOCK_HEIGHT = 9
const MAX_OIL_LEVEL = 3
const MAX_STRENGTH_LEVEL = 3

static func next_block_cost():
	# Learn to fly has each level approximately double, but with substantial jitter
	# so that this isn't super obvious
	match State.block_height:
		0: return 60
		1: return 90
		2: return 150
		3: return 300
		4: return 400
		5: return 500
		6: return 675
		9: return 850
		_:
			print("unexpected current block height")
			return 0

static func next_strength_cost():
	# We should update these numbers to diverge from block cost
	match State.strength_level:
		0: return 100
		1: return 450
		2: return 1050
		_:
			print("unexpected current strength")
			return 0

static func next_oil_cost():
	match State.oil_level:
		0: return 40
		1: return 250
		2: return 500
		_:
			print("unexpected current oil level")
			return 0

static func next_oil_description():
	match State.oil_level:
		0: return "Don't lose any speed on your first bounce"
		1: return "Don't lose any speed on your first 2 bounces"
		2: return "Don't lose any speed on your first 3 bounces"
		_:
			print("unexpected current oil level")
			return "Oiliness: 0"

static func description(kind) -> String:
	match kind:
		ITEM.BLOCK:
			return "Launching the boulder from a higher height means it goes farther, right?"
		ITEM.PARACHUTE:
			return "Deploy with '1'.  Slows your descent but reduces your speed."
		ITEM.OIL:
			return next_oil_description()
		ITEM.STRENGTH:
			return "Get a little more swole and hit the boulder even farther"
		ITEM.SLINGSHOT:
			return "Click on the boulder to use. Allows you adjust the trajectory of the boulder slightly while it's in flight.  Comes with 4 shots."
		_:
			return "unknown"

static func max_level (kind) -> int:
	match kind:
		ITEM.BLOCK:	return MAX_BLOCK_HEIGHT
		ITEM.PARACHUTE: return 1
		ITEM.OIL: return MAX_OIL_LEVEL
		ITEM.STRENGTH: return MAX_STRENGTH_LEVEL
		ITEM.SLINGSHOT: return 1
		_:
			return 0

static func current_level (kind) -> int:
	match kind:
		ITEM.BLOCK:	return State.block_height
		ITEM.PARACHUTE: return 1 if  State.has_parachute else 0
		ITEM.OIL: return State.oil_level
		ITEM.STRENGTH: return State.strength_level
		ITEM.SLINGSHOT: return 1 if State.has_slingshot else 0
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
	return 500

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
		_:	
			return 0

# Maybe this could indicate when you're maxed
static func name(kind) -> String:
	match kind:
		ITEM.BLOCK:
			return "Height: %d" % next_level(kind)
		ITEM.PARACHUTE:
			return "Parachute"
		ITEM.OIL:
			return "Oiliness: %d" % next_level(kind)
		ITEM.STRENGTH:
			return "Strength: %d" % next_level(kind)
		ITEM.SLINGSHOT:
			return "Slingshot"
		_:
			return "unknown"

static func _update_state_after_purchase(kind) -> void:
	match kind:
		ITEM.BLOCK:
			State.block_height += 1
		ITEM.PARACHUTE:
			State.has_parachute = true
		ITEM.OIL:
			State.oil_level += 1
		ITEM.STRENGTH:
			State.strength_level += 1
		ITEM.SLINGSHOT:
			State.has_slingshot = true
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
