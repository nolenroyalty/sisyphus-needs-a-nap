extends Control

onready var button = $Button
onready var animation_player = $AnimationPlayer
signal fade_complete()

func fade_away():
	animation_player.play("fadeaway")
	yield(animation_player, "animation_finished")
	emit_signal("fade_complete")

func init(achievement):
	$AchievementCompleted.text = "'%s' Achieved!" % State.achievement_text(achievement)
	$Accomplishment.text = State.achievement_description(achievement)
	if achievement == State.ACHIEVEMENTS.NAP_NIRVANA:
		$Accomplishment.text = "You took a nap! This is the end of the game, but you can keep playing if you want."
	$Reward.text = "Reward: %s rest" % State.achievement_reward(achievement)

func _ready():
	button.connect("pressed", self, "fade_away")
