extends Control

onready var button = $Button
onready var animation_player = $AnimationPlayer
signal fade_complete()

func fade_away():
	animation_player.play("fadeaway")
	yield(animation_player, "animation_finished")
	emit_signal("fade_complete")

func init(achievement):
	$AchievementCompleted.text = "'%s' Completed!" % State.achievement_text(achievement)
	$Accomplishment.text = State.achievement_description(achievement)
	$Reward.text = "Reward: %s rest" % State.achievement_reward(achievement)

func _ready():
	button.connect("pressed", self, "fade_away")
