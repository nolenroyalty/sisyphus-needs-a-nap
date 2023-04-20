extends Node

static func linear_then_sqrt(value, divisor, threshold) -> int:
	value = min(value, threshold) + sqrt(value)
	value /= divisor
	return int(value)

static func linear(value, divisor):
	return int(value / divisor)

static func heightscore(height) -> int:
	return linear_then_sqrt(height, 10, 10000)

static func distancescore(distance) -> int:
	return linear_then_sqrt(distance, 25, 10000)

static func timescore(time) -> int:
	return linear(time, 30)

static func compute_calmness(h, d, t) -> int:
	var calmness = heightscore(h) + distancescore(d) + timescore(t)
	print("CALMNESS: %d (h: %d, d: %d, t: %d)" % [calmness, h, d, t])
	return calmness
	
