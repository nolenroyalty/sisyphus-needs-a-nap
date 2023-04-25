extends Node

signal achievement_was_displayed(achievement)

enum FACT { INTRO, PARACHUTE, SLINGSHOT, GRIFFIN }
enum FACT_STATE { NOT_YET_DISPLAYED, SHOULD_DISPLAY, ALREADY_DISPLAYED }

enum ACHIEVEMENTS {
	A_LITTLE_REST,
	INTO_CAVE,
	CAVE_BOTTOM,
	PASSED_CAVE,
	INTO_LAVA,
	PASSED_LAVA,
	PASSED_BIG_SLOPE,
    NAP_ACHIEVED 
}

enum ACHIEVEMENT_STATE { NOT_YET_ACHIEVED, JUST_ACHIEVED, ALREADY_ACHIEVED }

const WINNING_DURATION_IN_SECONDS = 60

var rest = 3000
var block_height : int = 0
var oil_level = 0
var has_parachute = false
var has_slingshot = false
var has_griffin = false
var strength_level = 0
var launch_day = 1
var testing_level = 3

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
		has_griffin = true
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
	emit_signal("achievement_was_displayed", achievement)
	rest += achievement_reward(achievement)

func achievements_to_display():
	var achievements_to_display = []
	for achievement in ACHIEVEMENTS.values():
		if achievement_state[achievement] == ACHIEVEMENT_STATE.JUST_ACHIEVED:
			achievements_to_display.append(achievement)
	return achievements_to_display

func achievement_text(achievement):
	match achievement:
		ACHIEVEMENTS.A_LITTLE_REST:
			return "A Little Rest"
		ACHIEVEMENTS.INTO_CAVE:
			return "Explorer"
		ACHIEVEMENTS.CAVE_BOTTOM:
			return "Echo Echo"
		ACHIEVEMENTS.PASSED_CAVE:
			return "Long Distance"
		ACHIEVEMENTS.INTO_LAVA:
			return "Ouch"
		ACHIEVEMENTS.PASSED_LAVA:
			return "Longer Distance"
		ACHIEVEMENTS.PASSED_BIG_SLOPE:
			return "That Was Tall"
		ACHIEVEMENTS.NAP_ACHIEVED:
			return "Nap Achieved"
		_:
			print("ERROR: unknown achievement: " + str(achievement))

func achievement_description(achievement):
	match achievement:
		ACHIEVEMENTS.A_LITTLE_REST:
			return "Achieve a launch duration of at least 15 seconds"
		ACHIEVEMENTS.INTO_CAVE:
			return "Enter the cave"
		ACHIEVEMENTS.CAVE_BOTTOM:
			return "Reach the bottom of the cave"
		ACHIEVEMENTS.PASSED_CAVE:
			return "Get past the cave"
		ACHIEVEMENTS.INTO_LAVA:
			return "Launch yourself into the lava. Ouch!"
		ACHIEVEMENTS.PASSED_LAVA:
			return "Make it past the lava pit"
		ACHIEVEMENTS.PASSED_BIG_SLOPE:
			return "Make it past the big slope"
		ACHIEVEMENTS.NAP_ACHIEVED:
			return "Achieve a launch duration of at least %s seconds" % WINNING_DURATION_IN_SECONDS
		_:
			print("ERROR: unknown achievement: " + str(achievement))

# If we were more principled I think this would live in config.  But oh well.  We're not.
func achievement_reward(achievement):
	match achievement:
		ACHIEVEMENTS.A_LITTLE_REST:
			return 250
		ACHIEVEMENTS.INTO_CAVE:
			return 250
		ACHIEVEMENTS.CAVE_BOTTOM:
			return 300
		ACHIEVEMENTS.PASSED_CAVE:
			return 400
		ACHIEVEMENTS.INTO_LAVA:
			return 100
		ACHIEVEMENTS.PASSED_LAVA:
			return 500
		ACHIEVEMENTS.PASSED_BIG_SLOPE:
			return 1000
		ACHIEVEMENTS.NAP_ACHIEVED:
			return 42069
		_:
			print("ERROR: unknown achievement: " + str(achievement))

func _ready():
	set_test_values()
	for fact in FACT.values():
		fact_state[fact] = FACT_STATE.NOT_YET_DISPLAYED
	
	for achievement in ACHIEVEMENTS.values():
		achievement_state[achievement] = ACHIEVEMENT_STATE.NOT_YET_ACHIEVED
	
	# achievement_state[ACHIEVEMENTS.A_LITTLE_REST] = ACHIEVEMENT_STATE.JUST_ACHIEVED

	
