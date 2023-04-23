extends Node

var rest = 0
var block_height : int = 0
var oil_level = 0
var has_parachute = false
var has_slingshot = false
var strength_level = 0
var launch_day = 1
var testing_level = 0

func add_rest(amount : int):
	rest += amount

func can_purchase(rest_ : int):
	return rest >= rest_
		
func try_make_purchase(rest_ : int):
	if can_purchase(rest_) :
		rest -= rest_
		return true
	return false

func set_test_values():
	if testing_level:
		has_slingshot = true
		has_parachute = true
		strength_level = testing_level
		block_height = testing_level
		oil_level = testing_level

func _ready():
	set_test_values()
	pass