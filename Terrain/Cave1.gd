extends Node2D

signal boulder_entered
signal boulder_exited

onready var cave_area = $DetectionArea

func boulder_entered(_body):
	emit_signal("boulder_entered")

func boulder_exited(_body):
	emit_signal("boulder_exited")

func landmark_name():
	return "Cave"

func landmark_position_for_distance():
	return $LandmarkAnchorForDistance.global_position

func landmark_position_for_angle():
	return $LandmarkAnchorForAngle.global_position 

func _ready():
	cave_area.connect("body_entered", self, "boulder_entered")
	cave_area.connect("body_exited", self, "boulder_exited")