extends Node

var calmness = 0
var block_height : int = 0
var oil_level = 0
var has_parachute = false
var strength_level = 0

func add_calmness(amount : int):
	calmness += amount

func can_purchase(calmness_ : int):
	return calmness >= calmness_
		
func try_make_purchase(calmness_ : int):
	if can_purchase(calmness_) :
		calmness -= calmness_
		return true
	return false