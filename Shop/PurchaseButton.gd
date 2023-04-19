extends Button

signal purchased
const Config = preload("res://Shop/Config.gd")
export(String, "Block") var KIND

var kind = null
var current_cost = 0

func set_current_name():
	text = Config.name(kind)

func set_current_cost():
	current_cost = Config.cost(kind)

func configure():
	pressed = false
	disabled = not Config.can_purchase(kind)
	print(disabled)
	set_current_name()
	set_current_cost()

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
		_: assert(false, "Invalid kind: %s" % KIND)

func _ready():
	determine_kind()
	configure()
	var _ignore = self.connect("pressed", self, "purchase")

