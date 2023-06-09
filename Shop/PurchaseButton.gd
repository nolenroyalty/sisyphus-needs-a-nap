extends Button

class_name PurchaseButton

signal purchased
signal hovered(cost, description)
signal unhovered
const Config = preload("res://Shop/Config.gd")
export(String, "Block", "Parachute", "Oil", "Strength", "Slingshot", "Griffin") var KIND

var kind = null
var current_cost = 0
var current_description = ""

func get_class():
	return "PurchaseButton"

func set_current_name():
	text = Config.name(kind)

func set_current_cost():
	current_cost = Config.cost(kind)

func configure():
	pressed = false
	disabled = not Config.can_purchase(kind)
	set_current_name()
	set_current_cost()
	current_description = Config.description(kind)

func purchase():
	var purchased = Config.purchase(kind)
	if purchased:
		# Play a sound?
		configure()
		emit_signal("purchased")
	return purchased

func determine_kind():
	match KIND:
		"Block": kind = Config.ITEM.BLOCK
		"Parachute": kind = Config.ITEM.PARACHUTE
		"Oil": kind = Config.ITEM.OIL
		"Strength": kind = Config.ITEM.STRENGTH
		"Slingshot": kind = Config.ITEM.SLINGSHOT
		"Griffin": kind = Config.ITEM.GRIFFIN
		_: assert(false, "Invalid kind: %s" % KIND)

func hover():
	emit_signal("hovered", current_cost, current_description)

func unhover():
	emit_signal("unhovered")

func _ready():
	determine_kind()
	configure()
	var _ignore = self.connect("pressed", self, "purchase")
	_ignore = self.connect("mouse_entered", self, "hover")
	_ignore = self.connect("mouse_exited", self, "unhover")

