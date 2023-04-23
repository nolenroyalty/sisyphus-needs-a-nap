extends Control

onready var button = $Button
onready var animation_player = $AnimationPlayer
signal fade_complete()

func fade_away():
	animation_player.play("fadeaway")
	yield(animation_player, "animation_finished")
	emit_signal("fade_complete")

func _ready():
	button.connect("pressed", self, "fade_away")