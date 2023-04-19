extends Node2D

onready var calmness_label : Label = $Control/CalmAndPrice/Calmness
onready var price_label : Label = $Control/CalmAndPrice/Price
onready var launch_button : Button = $Control/Launch
onready var buttons = $Control/Buttons

func set_current_calmness():
	calmness_label.text = "Calmness: %d" % State.calmness

func set_current_price(price):
	price_label.text = "Price: %d" % price

func launch_pressed():
	SceneChange.set_scene(SceneChange.SCENE_FLIGHT)

func _ready():
	set_current_calmness()
	var _ignore = launch_button.connect("pressed", self, "launch_pressed")

	for button in buttons.get_children():
		_ignore = button.connect("purchased", self, "set_current_calmness")
		_ignore = button.connect("hovered", self, "set_current_price")
		_ignore = button.connect("unhovered", self, "set_current_price")
