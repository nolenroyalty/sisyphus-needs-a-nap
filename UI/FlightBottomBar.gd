extends CanvasLayer

class_name FlightBottomBar

onready var landmark_label : Label = $LandmarkLabel
onready var landmark_arrow : Sprite = $LandmarkArrow

func display_landmark(landmark, distance, angle):
	landmark_label.show()
	landmark_arrow.show()
	var name = landmark.landmark_name()
	distance = int(distance)
	var label_text = "%s (%s)" % [name, distance]
	landmark_label.text = label_text
	#warning-ignore:integer_division
	angle = float((int(angle) / 5) * 5)
	landmark_arrow.rotation_degrees = angle

func hide_landmark():
	landmark_label.hide()
	landmark_arrow.hide()

func _ready():
	hide_landmark()
