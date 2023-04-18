extends Node2D

onready var begin_flight_area = $BeginFlightArea
onready var boulder = $Boulder
var velocity : Vector2

func _ready():
	begin_flight_area.connect("body_entered", self, "move_to_flight_scene")

func move_to_flight_scene(_body):
	# get_tree().change_scene("res://scenes/Flight.tscn")
	print("happened")

func _physics_process(_delta):
	if Input.is_action_just_pressed("launch_boulder"):
		velocity = boulder.move_and_slide(Vector2(1000, -1000), Vector2.UP)
	else:
		boulder.move_and_slide(velocity)
