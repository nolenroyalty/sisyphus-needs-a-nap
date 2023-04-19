extends Node2D

onready var calmness_label : Label = $Control/CenterContainer/CalmAndPrice/Calmness
onready var launch_button : Button = $Control/Launch

func set_initial_calmness():
	calmness_label.text = "Calmness: %d" % State.calmness

func launch_pressed():
	SceneChange.set_scene(SceneChange.SCENE_FLIGHT)

func _ready():
	set_initial_calmness()
	var _ignore = launch_button.connect("pressed", self, "launch_pressed")
