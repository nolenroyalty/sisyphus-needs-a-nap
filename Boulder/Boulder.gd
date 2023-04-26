extends KinematicBody2D

class_name Boulder
signal boulder_clicked(relative_vector)

onready var ray : RayCast2D = $FloorRay
onready var parachute_animation : AnimatedSprite = $ParachuteAnimation
onready var deployed_parachute_collider : CollisionPolygon2D = $DeployedParachuteCollider
onready var no_parachute_griffin : Sprite = $Griffins/NoParachuteDeployed
onready var parachute_griffin : Sprite = $Griffins/ParachuteDeployed

var parachute_deployed = false
var griffin_visible = false

enum ROTATION_DIRECTION { LEFT, RIGHT }
var parachute_angle = ROTATION_DIRECTION.LEFT
var time_left_until_tick = 0
var mouse_in_area = false

# Totally made up
const MAXIMUM_HEIGHT_ABOVE_GROUND = 32768
const STARTING_GUESS_FOR_HEIGHT_ABOVE_GROUND = 128

func determine_height_above_ground():
	ray.cast_to.y = STARTING_GUESS_FOR_HEIGHT_ABOVE_GROUND
	ray.cast_to.x = 0
	ray.enabled = true
	while ray.cast_to.y < MAXIMUM_HEIGHT_ABOVE_GROUND:
		ray.force_raycast_update()
		if ray.is_colliding():
			var origin = ray.global_transform.origin
			var collision_point = ray.get_collision_point()
			return origin.distance_to(collision_point)
		else:
			ray.cast_to.y *= 2
	return MAXIMUM_HEIGHT_ABOVE_GROUND

func deploy_parachute():
	parachute_deployed = true
	deployed_parachute_collider.disabled = false
	parachute_animation.play("flap-parachute")
	$Sprite.frame = 0

func tick_parachute_rotation_angle():
	if abs(rotation_degrees) > 3.0:
		match parachute_angle:
			ROTATION_DIRECTION.LEFT:
				parachute_angle = ROTATION_DIRECTION.RIGHT
			ROTATION_DIRECTION.RIGHT:
				parachute_angle = ROTATION_DIRECTION.LEFT
	
	match parachute_angle: 
		ROTATION_DIRECTION.LEFT:
			rotation_degrees -= 1.0
		ROTATION_DIRECTION.RIGHT:
			rotation_degrees += 1.0

func maybe_tick_parachute_rotation_angle():
	time_left_until_tick -= 1
	if time_left_until_tick <= 0:
		time_left_until_tick = 10
		tick_parachute_rotation_angle()

func stop_animating():
	parachute_animation.playing = false

# Without this we'll also rotate our raycast, which we don't want!
func rotate_sprite(degrees):
	if griffin_visible: return
	if parachute_deployed:
		maybe_tick_parachute_rotation_angle()
		# set_rotation_for_parachute_angle()
	else:
		$Sprite.rotation_degrees += degrees

func update_oil_visibility(oil_remaining):
	if oil_remaining > 0:
		$Sprite/Oil.visible = true
		$Sprite/Oil.frame = 3 - oil_remaining
	else:
		$Sprite/Oil.visible = false

func mouse_entered(): mouse_in_area = true
func mouse_exited(): mouse_in_area = false

func show_griffin():
	if State.has_parachute and not parachute_deployed:
		# Ensure that the griffin isn't grabbing over the parachute?
		$Sprite.rotation_degrees = 180
	
	if parachute_deployed:
		parachute_griffin.visible = true
	else:
		no_parachute_griffin.visible = true
	
	griffin_visible = true

func hide_griffin():
	no_parachute_griffin.visible = false
	parachute_griffin.visible = false
	griffin_visible = false

func _ready():
	deployed_parachute_collider.disabled = true
	if State.has_parachute:
		$Sprite.frame = 1

	update_oil_visibility(State.oil_level)
	var _ignore = $MouseClickArea.connect("mouse_entered", self, "mouse_entered")
	_ignore = $MouseClickArea.connect("mouse_exited", self, "mouse_exited")

func _unhandled_input(event):
	if mouse_in_area and event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			# print($MouseClickArea.position - event.position)
			# print($MouseClickArea.position, event.position, position)
			# print(event.position.distance_to($MouseClickArea.position))
			emit_signal("boulder_clicked", $MouseClickArea.global_position - get_global_mouse_position())

