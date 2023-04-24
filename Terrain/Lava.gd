extends StaticBody2D

signal entered_lava
signal passed_lava

onready var LavaArea = $LavaArea
onready var PastLavaArea = $PastLavaArea
onready var anchor = $LandmarkAnchor

func entered_lava(_b):
	print("Entered Lava") 
	emit_signal("entered_lava")

func passed_lava(_b):
	print("Passed Lava")
	emit_signal("passed_lava")

func landmark_name():
	return "Lava Pit"  

func landmark_position_for_distance():
	return anchor.global_position

func landmark_position_for_angle():
	return anchor.global_position

# Called when the node enters the scene tree for the first time.
func _ready():
	LavaArea.connect("body_entered", self, "entered_lava")
	PastLavaArea.connect("body_entered", self, "passed_lava")
