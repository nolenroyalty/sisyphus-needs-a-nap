extends CanvasLayer

# This is really a general purpose hud, but here we are

class_name FlightBottomBar

signal parachute_deployed_via_click
signal griffin_deployed_via_click
signal abort_clicked

onready var landmark_label : Label = $LandmarkLabel
onready var landmark_arrow : Sprite = $LandmarkArrow
onready var parachute_gadget = $Gadgets/ParachuteIcon
onready var slingshot_gadget = $Gadgets/SlingshotIcon
onready var griffin_gadget = $Gadgets/GriffinIcon
onready var abort_button = $AbortButton

var frame_count = 0

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

func deploy_griffin():
	griffin_gadget.disabled()

func propagate_parachute_deploy():
	emit_signal("parachute_deployed_via_click")

func propagate_griffin_deploy():
	emit_signal("griffin_deployed_via_click")

func abort():
	emit_signal("abort_clicked")

func set_slingshot_ammo(ammo):
	slingshot_gadget.set_ammo(ammo)

func maybe_update_stats(distance, height, duration):
	frame_count += 1
	if frame_count % 5 == 0:
		# Subtract the boulder's height for display purposes.
		# Like with scoring, we divide the boulder's distance by 10 for display purposes
		$Stats/Values.text = "%s\n%s\n%.1f" % [int(distance / 10.0), int(height) - 15, duration]

func _ready():
	if not State.has_parachute:
		parachute_gadget.hide()
	if not State.has_slingshot:
		slingshot_gadget.hide()
	if not State.has_griffin:
		griffin_gadget.hide()
	
	hide_landmark()

	var _ignore = parachute_gadget.connect("parachute_deployed_via_click", self, "propagate_parachute_deploy")
	_ignore = griffin_gadget.connect("griffin_deployed_via_click", self, "propagate_griffin_deploy")
	_ignore = abort_button.connect("pressed", self, "abort")
