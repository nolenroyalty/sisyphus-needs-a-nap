extends Label

class_name TweenedLabel
signal tween_completed

onready var tween_ = $Tween
var score = 0.0 setget set_score

func set_score(score_ : float):
	text = "%0.2f" % score_
	score = score_

func _ready():
	set_score(0.0)

func tween_score(score_):
	tween_.interpolate_method(self, "set_score", 0, score_, 1.0, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween_.start()
	yield(tween_, "tween_all_completed")
	emit_signal("tween_completed")

func is_tweening():
	return tween_.is_active()