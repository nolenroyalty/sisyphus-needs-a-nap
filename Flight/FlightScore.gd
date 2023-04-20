extends Node2D

class_name FlightScore

var starting_x = 0
var starting_y = 0
var distance = 0
var height = 0
var duration_in_frames = 0

func reset_scores(boulder : Boulder):
	distance = boulder.position.x
	height = 0
	duration_in_frames = 0
	starting_x = distance
	starting_y = height

func _init(boulder : Boulder):
	reset_scores(boulder)

func tick(boulder : Boulder):
	distance = max(boulder.position.x, distance)
	height = max(height, boulder.determine_height_above_ground())
	duration_in_frames += 1

func max_distance():
	return (distance - starting_x)

func max_height():
	return height

func duration():
	return (duration_in_frames / 60.0)

func print_for_debugging():
	print("max distance: ", max_distance())
	print("max height: ", max_height())
	print("duration: ", duration())