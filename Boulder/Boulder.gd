extends KinematicBody2D

class_name Boulder

onready var ray : RayCast2D = $FloorRay
onready var parachute_animation : AnimatedSprite = $ParachuteAnimation
onready var deployed_parachute_collider : CollisionPolygon2D = $DeployedParachuteCollider
var parachute_deployed = false

enum ROTATION_DIRECTION { LEFT, RIGHT }
var parachute_angle = ROTATION_DIRECTION.LEFT
var time_left_until_tick = 0

# Totally made up
const MAXIMUM_HEIGHT_ABOVE_GROUND = 8092
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
	if parachute_deployed:
		maybe_tick_parachute_rotation_angle()
		# set_rotation_for_parachute_angle()
	else:
		$Sprite.rotation_degrees += degrees

func _ready():
	# position = Vector2(50, 50)
	# deploy_parachute()
	deployed_parachute_collider.disabled = true
	if State.has_parachute:
		$Sprite.frame = 1

# func _physics_process(_delta):
# 	rotate_sprite(1.0)
