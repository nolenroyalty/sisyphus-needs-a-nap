extends Node2D

class_name FlightScore

var starting_x = 0
var starting_y = 0
var distance = 0
var height = 0
var time_in_frames = 0

func reset_scores(boulder : Node2D):
	distance = boulder.position.x
	height = boulder.position.y
	time_in_frames = 0
	starting_x = distance
	starting_y = height

func _init(boulder : Node2D):
	reset_scores(boulder)

func tick(boulder):
	distance = max(boulder.position.x, distance)
	height = min(boulder.position.y, height)
	time_in_frames += 1

func max_distance():
	return distance - starting_x

func max_height():
	# It would be nice if this could account for the slope and just be "height off the ground"
	# instead of the sealevel-style height that it's currently doing.
	return starting_y - height

func frames_in_the_air():
	return time_in_frames

func print_for_debugging():
	print("max distance: ", max_distance())
	print("max height: ", max_height())
	print("frames in the air: ", frames_in_the_air())
