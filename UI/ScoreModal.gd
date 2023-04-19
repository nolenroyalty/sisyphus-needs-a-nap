extends CanvasLayer

class_name ScoreScreen

signal continue_pressed

onready var height_label : TweenedLabel = $Control/VBoxContainer/HBoxContainer/VBoxContainer2/HeightLabel
onready var distance_label : TweenedLabel = $Control/VBoxContainer/HBoxContainer/VBoxContainer2/DistanceLabel
onready var time_label : TweenedLabel = $Control/VBoxContainer/HBoxContainer/VBoxContainer2/TimeLabel
onready var continue_button : Button = $Control/VBoxContainer/ContinueButton
onready var background : ColorRect = $Control/Background
onready var vbox : VBoxContainer = $Control/VBoxContainer

func tween_scores(h, d, t):
	height_label.tween_score(h)
	distance_label.tween_score(d)
	time_label.tween_score(t)
	
func continue_pressed():
	print("continuing")
	emit_signal("continue_pressed")

func configure_background():
	background.rect_position.x = -10
	background.rect_position.y = -2
	background.rect_size.x = max(background.rect_size.x, vbox.rect_size.x + 20)
	background.rect_size.y = vbox.rect_size.y - 5

func _ready():
	continue_button.connect("pressed", self, "continue_pressed")
	configure_background()

func _process(delta):
	if height_label.is_tweening() or distance_label.is_tweening() or time_label.is_tweening():
		configure_background()
