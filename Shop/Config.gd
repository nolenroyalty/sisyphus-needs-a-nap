extends Node

enum ITEM { BLOCK = 1}


static func next_block_height():
	if State.block_height + 1 >= State.MAX_BLOCK_HEIGHT:
		return null
	return State.block_height + 1

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

static func cost(kind) -> int:
	match kind:
		ITEM.BLOCK:
			return next_block_cost()
		_:
			return 0

static func name(kind) -> String:
	match kind:
		ITEM.BLOCK:
			return "Height: %d" % next_block_height()
		_:
			return "unknown"

static func can_purchase(kind):
	var cost_ = cost(kind)
	if cost_ == 0 or not State.can_purchase(cost_):
		return false
	match kind:
		ITEM.BLOCK:
			return State.block_height + 1 < State.MAX_BLOCK_HEIGHT
		_:
			return false

static func purchase(kind):
	var cost_ = cost(kind)
	if not can_purchase(kind): return false
	var made_purchase = State.try_make_purchase(cost_)
	if not made_purchase:
		return false

	match kind:
		ITEM.BLOCK:
			State.block_height += 1
		_:
			print("unexpected item kind")
			return false
	
	return true