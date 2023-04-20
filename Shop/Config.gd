extends Node

enum ITEM { BLOCK = 1, PARACHUTE = 2, OIL = 3, STRENGTH = 4}

const MAX_BLOCK_HEIGHT = 10
const MAX_OIL_LEVEL = 3
const MAX_STRENGTH_LEVEL = 10

static func next_block_cost():
	# Learn to fly has each level approximately double, but with substantial jitter
	# so that this isn't super obvious
	match State.block_height:
		0: return 50
		1: return 75
		2: return 160
		3: return 350
		4: return 750
		5: return 1500
		6: return 2000
		7: return 3500
		8: return 5000
		9: return 6500
		_:
			print("unexpected current block height")
			return 0

static func next_strength_cost():
	# We should update these numbers to diverge from block cost
	match State.strength_level:
		0: return 50
		1: return 75
		2: return 160
		3: return 350
		4: return 750
		5: return 1500
		6: return 2000
		7: return 3500
		8: return 5000
		9: return 6500
		_:
			print("unexpected current strength")
			return 0

static func next_oil_cost():
	# Learn to fly has each level approximately double, but with substantial jitter
	# so that this isn't super obvious
	match State.oil_level:
		0: return 30
		1: return 300
		2: return 2500
		_:
			print("unexpected current oil level")
			return 0

static func max_level (kind) -> int:
	match kind:
		ITEM.BLOCK:	return MAX_BLOCK_HEIGHT
		ITEM.PARACHUTE: return 1
		ITEM.OIL: return MAX_OIL_LEVEL
		ITEM.STRENGTH: return MAX_STRENGTH_LEVEL
		_:
			return 0

static func current_level (kind) -> int:
	match kind:
		ITEM.BLOCK:	return State.block_height
		ITEM.PARACHUTE: return 1 if  State.has_parachute else 0
		ITEM.OIL: return State.oil_level
		ITEM.STRENGTH: return State.strength_level
		_:
			return 0

static func not_at_max_level(kind) -> bool:
	return current_level(kind) < max_level(kind)

static func next_level(kind) -> int:
	var max_level_ = max_level(kind)
	return int(min(current_level(kind) + 1, max_level_))

static func parachute_cost():
	return 250

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
