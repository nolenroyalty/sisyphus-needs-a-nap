extends Node2D

onready var boulder = $Boulder
export var GRAVITY = 100
export var MAX_GRAVITY = 100
export var X_BOUNCE_PENALTY = 0.1
export var Y_BOUNCE_BONUS = 0.03

export var BACKWARDS_ROLL_SPEED = 1.0
export var STARTING_VELOCITY = Vector2(250, -100)
export var SUPERBOUNCE_FRAMES = 10
export var MIN_ROTATION = 1.0
export var MAX_ROTATION = 10.0
const MAX_EXPECTED_SPEED_FOR_ROTATION = 250

onready var audioStreamPlayer : AudioStreamPlayer2D = $Boulder/BouncePlayer

var velocity = Vector2()
var frozen = true
var frozen_count = 0
enum SUPERBOUNCE_STATE {NONE, BOUNCING}
var superbounce_frames_remaining = 0
var superbounce_state = SUPERBOUNCE_STATE.NONE

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func play_bounce_sound(super : bool):
	if super: audioStreamPlayer.stream = load("res://sounds/super1.wav")
	else: audioStreamPlayer.stream = load("res://sounds/bounce1.wav")
	audioStreamPlayer.play()
	
func apply_gravity(delta : float):
	var proposed_velocity = velocity.y + GRAVITY * delta
	if proposed_velocity < 0: velocity.y = proposed_velocity
	else: velocity.y = min(proposed_velocity, MAX_GRAVITY)

func handle_bounce(collision : KinematicCollision2D, superbounced):
	# Maybe this should do a different thing for the x and y axis?
	velocity = velocity.bounce(collision.normal)
	if velocity.x > 0:
		var penalty = X_BOUNCE_PENALTY * (0.5 if superbounced else 1.0)
		velocity.x *= (1 - penalty)
	else:
		# Bounce more quickly downhill
		velocity.x *= (1 + X_BOUNCE_PENALTY)
	
	# Give the ball a little bit of vertical bounciness
	var bonus = Y_BOUNCE_BONUS * (1.2 if superbounced else 1.0)
	velocity.y *= (1 + bonus)

func is_rolling_downhill():
	return velocity.x < -BACKWARDS_ROLL_SPEED and velocity.y > BACKWARDS_ROLL_SPEED

func check_if_rolling_downhill_after_collision():
	if velocity.x < 0:
		print("rolling downhill!")
		frozen_count += 1
	
	if frozen_count > 2:
		frozen_count = 0
		return true
	else:
		return false

func reset_superbounce_state():
	superbounce_state = SUPERBOUNCE_STATE.NONE
	superbounce_frames_remaining = 0

func tick_superbounce_state():
	match superbounce_state:
		SUPERBOUNCE_STATE.NONE:
			pass
		SUPERBOUNCE_STATE.BOUNCING:
			superbounce_frames_remaining -= 1
			if superbounce_frames_remaining <= 0:
				superbounce_state = SUPERBOUNCE_STATE.NONE

func is_superbouncing():
	return superbounce_state == SUPERBOUNCE_STATE.BOUNCING

func handle_superbounce_pressed():
	if is_superbouncing():
		pass
	else:
		superbounce_state = SUPERBOUNCE_STATE.BOUNCING
		superbounce_frames_remaining = SUPERBOUNCE_FRAMES

func rotate_boulder():
	var is_positive = velocity.x >= 0
	var speed = abs(velocity.x)
	var degrees = MIN_ROTATION + (MAX_ROTATION - MIN_ROTATION) * (min(speed, MAX_EXPECTED_SPEED_FOR_ROTATION) / MAX_EXPECTED_SPEED_FOR_ROTATION)
	print(degrees)
	if is_positive: boulder.rotation_degrees += degrees
	else: boulder.rotation_degrees -= degrees

func launch_or_freeze_boulder():
	if frozen:
		frozen = false
		velocity = STARTING_VELOCITY
	else:
		frozen = true
		velocity = Vector2.ZERO

func _physics_process(delta): 
	if Input.is_action_just_pressed("launch_boulder"):
		launch_or_freeze_boulder()

	if frozen: return
	if Input.is_action_just_pressed("superbounce"): handle_superbounce_pressed()

	tick_superbounce_state()
	rotate_boulder()

	var collision = boulder.move_and_collide(velocity * delta)
	if collision:
		var superbounced = is_superbouncing()
		play_bounce_sound(superbounced)
		handle_bounce(collision, superbounced)
		reset_superbounce_state()
		frozen = check_if_rolling_downhill_after_collision()
	else:
		apply_gravity(delta)
