extends CanvasLayer

const ACHIEVEMENT_HEIGHT = 16

onready var achievement_list = $AchievementList
onready var achievement_text = $AchievementText
onready var whole_mouse_area = $WholeMouseArea
onready var whole_mouse_collider = $WholeMouseArea/CollisionShape2D
var achievementSingle = preload("res://UI/AchievementSingle.tscn")
var current_text = null

func node_for_achievement(achievement):
	for c in achievement_list.get_children():
		if c.is_in_group("achievement_single"):
			if c.achievement == achievement:
				return c

func hide_current_text():
	achievement_text.hide()

func show_achievement(achievement):
	var node = node_for_achievement(achievement)
	if node != null:
		achievement_text.set_text(achievement, node.achievement_description())
		achievement_text.show()

# This is frustrating, but I can't find a nice way to ensure that any
# "hide current text" signal is sequenced before the "mouse over" signal,
# so we have a race where the "hide current text" for the _previous_ achievement
# can cause us to hide the text for the _current_ achievement.  Instead of solving
# this we just build a separate larger area for the whole achievement list and
# only hide the text if the mouse leaves that.

# The rect will need to be expanded if we add more achievements, but I don't anticipate
# touching this game much more so I don't think that'll be necessary.
func _ready():
	achievement_text.hide()
	whole_mouse_area.connect("mouse_exited", self, "hide_current_text")

	for achievement in State.ACHIEVEMENTS.values():
		var node = achievementSingle.instance()
		node.achievement = achievement
		node.connect("achievement_moused_over", self, "show_achievement")
		achievement_list.add_child(node)
		
