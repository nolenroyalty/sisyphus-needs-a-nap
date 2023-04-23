extends CanvasLayer

class_name FlightBottomBar

signal parachute_deployed_via_click
signal abort_clicked

onready var landmark_label : Label = $LandmarkLabel
onready var landmark_arrow : Sprite = $LandmarkArrow
onready var parachute_gadget = $Gadgets/ParachuteIcon
onready var slingshot_gadget = $Gadgets/SlingshotIcon
onready var abort_button = $AbortButton

func display_landmark(landmark, distance, angle):
	landmark_label.show()
	landmark_arrow.show()
	var name = landmark.landmark_name()
	distance = int(distance)
	var label_text = "%s (%s)" % [name, distance]
	landmark_label.text = label_text
	#warning-ignore:integer_division
	angle = float((int(angle) / 5) * 5)
	landmark_arrow.rotation_degrees = angle

func hide_landmark():
	landmark_label.hide()
	landmark_arrow.hide()

func deploy_parachute():
	parachute_gadget.disabled()

func propagate_parachute_deploy():
	emit_signal("parachute_deployed_via_click")

func abort():
	emit_signal("abort_clicked")

func set_slingshot_ammo(ammo):
	slingshot_gadget.set_ammo(ammo)

func _ready():
	if not State.has_parachute:
		parachute_gadget.hide()
	if not State.has_slingshot:
		slingshot_gadget.hide()
	
	hide_landmark()

	var _ignore = parachute_gadget.connect("parachute_deployed_via_click", self, "propagate_parachute_deploy")
	_ignore = abort_button.connect("pressed", self, "abort")
