extends Node

static func linear_then_sqrt(value, divisor, threshold) -> int:
	value = min(value, threshold) + sqrt(value)
	value /= divisor
	return int(value)

static func linear(value, divisor):
	return int(value / divisor)

static func heightscore(height) -> int:
	return linear_then_sqrt(height, 3, 500)

static func distancescore(distance) -> int:
	return linear_then_sqrt(distance, 25, 10000)

static func durationscore(duration) -> int:
	return duration * 3

static func compute_rest(h, d, t) -> int:
	var rest = heightscore(h) + distancescore(d) + durationscore(t)
	print("REST: %d (h: %d, d: %d, t: %d)" % [rest, h, d, t])
	return rest
	
 
