extends Node2D

onready var rest_label : Label = $Info/RestAndPrice/R/Rest
onready var price_label : Label = $Info/RestAndPrice/P/Price
onready var launch_button : Button = $Launch
onready var grid = $Grid
onready var description_label : Label = $Info/Description

func set_current_rest():
	rest_label.text = "%d" % State.rest

func set_price_and_description(price, d):
	price_label.text = "%d" % price
	description_label.text = d

func hovered(price, d): set_price_and_description(price, d)

func unhovered():
	set_price_and_description(0, "Hover over an item to see a description")

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
	set_current_rest()

func _ready():
	set_current_rest()
	var _ignore = launch_button.connect("pressed", self, "launch_pressed")

	for button in buttons():
		_ignore = button.connect("purchased", self, "purchased")
		_ignore = button.connect("hovered", self, "hovered")
		_ignore = button.connect("unhovered", self, "unhovered")
