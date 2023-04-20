extends CanvasLayer

class_name ScoreScreen

signal continue_pressed
signal tween_components_completed

onready var height_label : TweenedLabel = $Control/VBoxContainer/HBoxContainer/VBoxContainer2/HeightLabel
onready var distance_label : TweenedLabel = $Control/VBoxContainer/HBoxContainer/VBoxContainer2/DistanceLabel
onready var duration_label : TweenedLabel = $Control/VBoxContainer/HBoxContainer/VBoxContainer2/DurationLabel
onready var continue_button : Button = $Control/VBoxContainer/ContinueButton
onready var background : ColorRect = $Control/Background
onready var vbox : VBoxContainer = $Control/VBoxContainer
onready var rest_text : Label = $Control/VBoxContainer/RestContainer/Text/Text
onready var rest_value : Label = $Control/VBoxContainer/RestContainer/Value/Value
onready var rest_tween : Tween = $RestTween

var was_tweening = false

func tween_components(h, d, t):
	height_label.tween_score(h)
	distance_label.tween_score(d)
	duration_label.tween_score(t)

func is_tweening():
	return height_label.is_tweening() or distance_label.is_tweening() or duration_label.is_tweening()

func set_rest_visibility(percent : float):
	var amount = percent
	rest_text.modulate.a = amount
	rest_value.modulate.a = amount

func tween_in_rest():
	var _ignore = rest_tween.interpolate_method(self,
	 "set_rest_visibility",
	  0.0, 
	  1.0, 
	  1.5, 
	  Tween.TRANS_LINEAR, 
	  Tween.EASE_IN)

	_ignore = rest_tween.start()

func tween_scores(height_, distance_, duration_):
	set_rest_visibility(0)
	tween_components(height_, distance_, duration_)
	var rest = ScoreComputation.compute_rest(height_, distance_, duration_)
	rest_value.text = str(rest)
	State.add_rest(rest)
	yield(self, "tween_components_completed")
	tween_in_rest()

func continue_pressed():
	emit_signal("continue_pressed")

func configure_background():
	background.rect_position.x = -10
	background.rect_position.y = -2
	background.rect_size.x = max(background.rect_size.x, vbox.rect_size.x + 20)
	background.rect_size.y = vbox.rect_size.y - 5

func _ready():
	var _ignore = continue_button.connect("pressed", self, "continue_pressed")
	configure_background()

func _process(_delta):
	if is_tweening():
		configure_background()
		was_tweening = true
	elif was_tweening:
		emit_signal("tween_components_completed")
		was_tweening = false
