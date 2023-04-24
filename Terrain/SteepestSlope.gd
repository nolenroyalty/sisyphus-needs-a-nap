extends StaticBody2D

signal passed_big_slope

onready var passed_slope = $PassedSlope
onready var anchor = $LandmarkAnchor

func landmark_name():
	return "Biggg Slope"

func landmark_position_for_distance():
	return anchor.global_position

func landmark_position_for_angle():
	return anchor.global_position

func emit_passed_slope(_body):
	emit_signal("passed_big_slope")
	print("you passed the big slope that is really great buddy")
	State.achieve_if_we_havent_yet(State.ACHIEVEMENTS.PASSED_BIG_SLOPE)

func _ready():
	passed_slope.connect("body_entered", self, "emit_passed_slope")