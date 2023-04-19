extends CanvasLayer

signal continue_pressed

onready var height_label : TweenedLabel = $VBoxContainer/HBoxContainer/VBoxContainer2/HeightLabel
onready var distance_label : TweenedLabel = $VBoxContainer/HBoxContainer/VBoxContainer2/DistanceLabel
onready var time_label : TweenedLabel = $VBoxContainer/HBoxContainer/VBoxContainer2/TimeLabel
onready var continue_button : Button = $VBoxContainer/ContinueButton

func tween_scores(h, d, t):
	height_label.tween_score(h)
	distance_label.tween_score(d)
	time_label.tween_score(t)
	
func continue_pressed():
	print("continuing")
	emit_signal("continue_pressed")

func _ready():
	continue_button.connect("pressed", self, "continue_pressed")
