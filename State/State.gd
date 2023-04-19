extends Node

var calmness = 0

func add_calmness(amount : int):
	calmness += amount

func try_make_purchase(calmness_ : int):
	if calmness >= calmness_ :
		calmness -= calmness_
		return true
	else:
		return false