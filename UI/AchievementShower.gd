extends CanvasLayer

signal no_achievements_are_displayed()
var shownAchievement = preload("res://UI/ShownAchievement.tscn")

func maybe_display_achievements():
	for achievement in State.achievement_state:
		var state = State.achievement_state[achievement]
		if state == State.ACHIEVEMENT_STATE.JUST_ACHIEVED:
			var node = shownAchievement.instance()
			node.init(achievement)
			node.rect_position = Vector2(84, 43)
			add_child(node)
			print("yielding until achievement fades")
			yield(node, "fade_complete")
			yield(get_tree().create_timer(0.1), "timeout")
			node.queue_free()
			State.achievement_was_displayed(achievement)
	
	print("no remaining achievements")
	emit_signal("no_achievements_are_displayed")

func _ready():
	# We just use the guide to make sure we're setting our
	# instanced nodes to the right position.
	$Guide.hide()

