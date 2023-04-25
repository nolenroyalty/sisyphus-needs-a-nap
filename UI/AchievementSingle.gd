extends Control

signal achievement_moused_over(achievement)
signal achievement_moused_out(achievement)

onready var animation_player = $AnimationPlayer
onready var label = $Label
onready var completed = $Completed
onready var checkmark = $Checkmark
onready var mouse_area = $MouseArea
var achievement = null


func complete(a):
	if a == achievement:
		animation_player.play("Completed")

func achievement_description():
	var reward = State.achievement_reward(achievement)
	var description = State.achievement_description(achievement)
	return "[Rest: %s]\n%s" % [ reward, description]

func mouse_entered():
	emit_signal("achievement_moused_over", achievement)

func mouse_exited():
	emit_signal("achievement_moused_out", achievement)

func _ready():
	var _ignore = State.connect("achievement_was_displayed", self, "complete")
	_ignore = mouse_area.connect("mouse_entered", self, "mouse_entered")
	_ignore = mouse_area.connect("mouse_exited", self, "mouse_exited")
	label.text = State.achievement_text(achievement)
	match State.achievement_state[achievement]:
		State.ACHIEVEMENT_STATE.NOT_YET_ACHIEVED, State.ACHIEVEMENT_STATE.JUST_ACHIEVED:
			completed.modulate.a = 0
			checkmark.modulate.a = 0
		State.ACHIEVEMENT_STATE.ALREADY_ACHIEVED:
			completed.modulate.a = 1
			checkmark.modulate.a = 1
