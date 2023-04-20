extends Node2D

onready var calmness_label : Label = $Control/CalmAndPrice/C/Calmness
onready var price_label : Label = $Control/CalmAndPrice/P/Price
onready var launch_button : Button = $Control/Launch
onready var grid = $Control/Grid

func set_current_calmness():
	calmness_label.text = "%d" % State.calmness

func set_current_price(price):
	price_label.text = "%d" % price

func launch_pressed():
	SceneChange.set_scene(SceneChange.SCENE_FLIGHT)

func buttons():
	var buttons = []
	for maybe_button in grid.get_children():
		if maybe_button.get_class() == "PurchaseButton":
			buttons.append(maybe_button)
	return buttons

func purchased():
	for button in buttons():
		button.configure()
	set_current_calmness()

func _ready():
	set_current_calmness()
	var _ignore = launch_button.connect("pressed", self, "launch_pressed")

	for button in buttons():
		_ignore = button.connect("purchased", self, "purchased")
		_ignore = button.connect("hovered", self, "set_current_price")
		_ignore = button.connect("unhovered", self, "set_current_price")
