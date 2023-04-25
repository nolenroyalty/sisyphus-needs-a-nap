extends Control
var current_achievement = null

func set_text(achievement, text):
	current_achievement = achievement
	$Label.text = text