extends KinematicBody2D

class_name Boulder

onready var ray : RayCast2D = $FloorRay

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

# Without this we'll also rotate our raycast, which we don't want!
func rotate_sprite(degrees):
	$Sprite.rotation_degrees += degrees