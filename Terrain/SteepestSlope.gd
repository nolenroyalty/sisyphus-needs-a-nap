extends StaticBody2D

signal passed_big_slope

onready var past_slope = $PastSlope
onready var anchor = $LandmarkAnchor

func landmark_name():
	return "Biggg Slope"

func landmark_position_for_distance():
	return anchor.global_position

func landmark_position_for_angle():
	return anchor.global_position

func passed_slope():
	emit_signal("passed_big_slope")

func _ready():
	past_slope.connect("body_entered", self, "passed_slope")