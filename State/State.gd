extends Node

var calmness = 0
var block_height = 0
const MAX_BLOCK_HEIGHT = 10

func add_calmness(amount : int):
	calmness += amount

func can_purchase(calmness_ : int):
	return calmness >= calmness_
		
func try_make_purchase(calmness_ : int):
	if can_purchase(calmness_) :
		calmness -= calmness_
		return true
	return false