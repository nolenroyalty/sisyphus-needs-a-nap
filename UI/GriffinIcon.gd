extends Control
# Copied-pasted from parachute, whatever

signal griffin_deployed_via_click

onready var shortcut_label : Label = $ShortcutLabel
onready var sprite : Sprite = $Sprite
onready var hidden_button : Button = $HiddenButton

var enabled = true

# Called when the node enters the scene tree for the first time.
func _ready():
	var _ignore = hidden_button.connect("pressed", self, "pressed")

func pressed():
	if !enabled:
		return
	print("deploying griffin from mouse click")
	emit_signal("griffin_deployed_via_click")

func disabled():
	hidden_button.disabled = true
	enabled = false
	sprite.modulate.a = 0.4
	shortcut_label.modulate.a = 0.1
