extends Node2D

signal boulder_entered
signal boulder_exited
signal boulder_made_it_to_the_bottom
signal boulder_passed

onready var cave_area = $DetectionArea
onready var cave_bottom = $CaveBottom
onready var passed_cave = $PassedCave

func boulder_entered(_body):
	State.achieve_if_we_havent_yet(State.ACHIEVEMENTS.INTO_CAVE)
	emit_signal("boulder_entered")

func boulder_exited(_body):
	emit_signal("boulder_exited")

func boulder_made_it_to_the_bottom(_body):
	emit_signal("boulder_made_it_to_the_bottom")
	State.achieve_if_we_havent_yet(State.ACHIEVEMENTS.CAVE_BOTTOM)

func boulder_passed(_body):
	emit_signal("boulder_passed")
	State.achieve_if_we_havent_yet(State.ACHIEVEMENTS.PASSED_CAVE)

func landmark_name():
	return "Cave"

func landmark_position_for_distance():
	return $LandmarkAnchorForDistance.global_position

func landmark_position_for_angle():
	return $LandmarkAnchorForAngle.global_position 

func _ready():
	cave_area.connect("body_entered", self, "boulder_entered")
	cave_area.connect("body_exited", self, "boulder_exited")
	cave_bottom.connect("body_entered", self, "boulder_made_it_to_the_bottom")
	passed_cave.connect("body_entered", self, "boulder_passed")