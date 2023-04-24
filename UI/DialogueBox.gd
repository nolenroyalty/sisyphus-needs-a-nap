extends Control

signal dialogue_finished

enum STATE { DISPLAYING, WAITING, DONE }

onready var audio = $AudioStreamPlayer
onready var label = $Label
var sound = load("res:///sounds/dialogue2.wav")
var characters_per_second = 25
var play_sound_every_n_characters = 3
var end_of_dialogue_default_pause = 1.0
var state = STATE.DISPLAYING
var rng = RandomNumberGenerator.new()

func should_play_sound(offset, add):
	return offset % play_sound_every_n_characters == 0 \
	 or (offset + add) %play_sound_every_n_characters == 0

func show_characters(c):
	c = int(c)
	label.visible_characters = c
	var add = rng.randi() % 2
	if should_play_sound(c, add):
		var pitch_scale = 1.0 + rng.randfn(0.2, 0.1)
		audio.stream = sound
		audio.volume_db = -20.0
		audio.pitch_scale = pitch_scale
		audio.play()

func finished():
	emit_signal("dialogue_finished")

func advance_state():
	match state:
		STATE.DISPLAYING:
			state = STATE.WAITING
		STATE.WAITING:
			state = STATE.DONE
			finished()

func animate_text(text):
	label.text = text
	label.visible_characters = 0
	state = STATE.DISPLAYING
	for i in range(len(text)):
		if state != STATE.DISPLAYING:
			show_characters(len(text) + 1)
			break
		show_characters(i+1)
		yield(get_tree().create_timer(1.0 / characters_per_second), "timeout")
	state = STATE.WAITING
	
	yield(get_tree().create_timer(end_of_dialogue_default_pause), "timeout")
	finished()

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
		advance_state()

func _ready():
	rng.randomize()
