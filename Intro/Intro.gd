extends Node2D

signal all_dialogue_finished()

var dialogue_box = preload("res://UI/DialogueBox.tscn")
onready var sisyphus_placeholder = $SisyphusPlaceholder
onready var friend_placeholder = $FriendPlaceholder
onready var skip = $Skip

enum WHO { SISYPHUS, FRIEND }
var s = WHO.SISYPHUS
var f = WHO.FRIEND

var dialogue = [
	["hey sisyphus", f],
	["yeah", s],
	["hows the boulder pushing going", f],
	["well", s],
	["i mean", s],
	["its pretty monotonous", s],
	["tiring", s],
	["i could use a nap", s],
	["have you considered thwacking the boulder", f],
	["thwacking it", s],
	["yeah", f],
	["thwacking", s],
	["the boulder", f],
	["thwacking the boulder", f],
	["and then taking a nap while it falls back down", f],
	["i mean", s],
	["cant hurt", s]
]

func position(who):
	match who:
		WHO.SISYPHUS: return sisyphus_placeholder.rect_position
		WHO.FRIEND: return friend_placeholder.rect_position

func size(who):
	match who:
		WHO.SISYPHUS: return sisyphus_placeholder.rect_size
		WHO.FRIEND: return friend_placeholder.rect_size

func play_dialogue():
	var prior = { WHO.SISYPHUS: null, WHO.FRIEND: null}

	for i in range(len(dialogue)):
		var text = dialogue[i][0]
		var who = dialogue[i][1]
		var box = dialogue_box.instance()
		if prior[who] != null:
			prior[who].queue_free()
			prior[who] = null

		box.rect_position = position(who)
		box.rect_size = size(who)
		add_child(box)
		box.animate_text(text)
		print("%s: %s" % [who, text])
		yield(box, "dialogue_finished")
		prior[who] = box
	emit_signal("all_dialogue_finished")
	SceneChange.set_scene(SceneChange.SCENE_FLIGHT)

func skip_pressed():
	print("dialogue skipped")
	emit_signal("all_dialogue_finished")

func _ready():
	sisyphus_placeholder.hide()
	friend_placeholder.hide()
	var _ignore = skip.connect("pressed", self, "skip_pressed")
	play_dialogue()
