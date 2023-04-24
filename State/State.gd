extends Node

enum FACT { INTRO, PARACHUTE, SLINGSHOT }
enum FACT_STATE { NOT_YET_DISPLAYED, SHOULD_DISPLAY, ALREADY_DISPLAYED }

enum ACHIEVEMENTS {
	WELL_RESTED,
	INTO_CAVE,
	CAVE_BOTTOM,
	PASSED_CAVE,
	INTO_LAVA,
	PASSED_LAVA,
	OVER_SLOPE,
    NAP_ACHIEVED }

enum ACHIEVEMENT_STATE { NOT_YET_ACHIEVED, JUST_ACHIEVED, ALREADY_ACHIEVED }

var rest = 0
var block_height : int = 0
var oil_level = 0
var has_parachute = false
var has_slingshot = false
var strength_level = 0
var launch_day = 1
var testing_level = 1

var fact_state = {}
var achievement_state = {}

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

func display_fact_if_we_havent_yet(fact):
	if fact_state[fact] == FACT_STATE.NOT_YET_DISPLAYED:
		print("displaying fact: " + str(fact))
		fact_state[fact] = FACT_STATE.SHOULD_DISPLAY

func fact_was_displayed(fact):
	fact_state[fact] = FACT_STATE.ALREADY_DISPLAYED

# Maybe it's not great that we copy-pasted the fact code for achievements but whatever.
func achieve_if_we_havent_yet(achievement):
	if achievement_state[achievement] == ACHIEVEMENT_STATE.NOT_YET_ACHIEVED:
		print("displaying achievement: " + str(achievement))
		achievement_state[achievement] = ACHIEVEMENT_STATE.JUST_ACHIEVED

func achievement_was_displayed(achievement):
	achievement_state[achievement] = ACHIEVEMENT_STATE.ALREADY_ACHIEVED

func _ready():
	# set_test_values()
	for fact in FACT.values():
		fact_state[fact] = FACT_STATE.NOT_YET_DISPLAYED
	
	for achievement in ACHIEVEMENTS.values():
		achievement_state[achievement] = ACHIEVEMENT_STATE.NOT_YET_ACHIEVED