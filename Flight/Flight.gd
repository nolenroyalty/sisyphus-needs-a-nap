extends Node2D


export var GRAVITY = 100
export var MAX_GRAVITY = 100
export var X_BOUNCE_PENALTY = 0.1
export var Y_BOUNCE_BONUS = 0.03

export var BACKWARDS_ROLL_SPEED = 1.0
export var DEFAULT_STARTING_VELOCITY = Vector2(250, -100)
export var SUPERBOUNCE_FRAMES = 10
export var MIN_ROTATION = 1.0
export var MAX_ROTATION = 10.0
export var PARACHUTE_X_SPEED_REDUCTION = 0.75
export var PARACHUTE_Y_SPEED_REDUCTION = 0.25
export var PARACHUTE_GRAVITY_REDUCTION = 0.4
export var OILINESS_PENALTY_REDUCTION_FACTOR = 0.15
export var STRENGTH_INCREASE_FACTOR = 1.3
const MAX_EXPECTED_SPEED_FOR_ROTATION = 250

onready var boulder = $Boulder
onready var scoreScreen = $ScoreScreen
onready var player = $Launch/Player
onready var audioStreamPlayer : AudioStreamPlayer2D = $Boulder/BouncePlayer

var velocity = Vector2()
var frozen = true
var frozen_count = 0
enum SUPERBOUNCE_STATE {NONE, BOUNCING}
var superbounce_frames_remaining = 0
var superbounce_state = SUPERBOUNCE_STATE.NONE
var flightscore : FlightScore
var parachute_deployed = false

enum SOUNDS { BOUNCE, SUPERBOUNCE, PARACHUTE }

func calculate_gravity():
	if parachute_deployed and velocity.y > 0:
		return GRAVITY * PARACHUTE_GRAVITY_REDUCTION
	else:
		return GRAVITY

func calculate_bounce_penalty(superbounced):
	if velocity.x > 0:
		var base_penalty = X_BOUNCE_PENALTY
		base_penalty *= (0.5 if superbounced else 1.0)
		base_penalty *= (1 - OILINESS_PENALTY_REDUCTION_FACTOR * State.oil_level)
		return base_penalty
	else:
		# Bounce more quickly downhill
		velocity.x *= (1 + X_BOUNCE_PENALTY)
	
func calculate_starting_velocity():
	var starting_velocity = DEFAULT_STARTING_VELOCITY
	var s = State.strength_level
	while s:
		starting_velocity *= STRENGTH_INCREASE_FACTOR
		s -= 1
	return starting_velocity

func set_up_for_current_state():
	var platform_offset = 64 * State.block_height
	boulder.position.y -= platform_offset
	player.position.y -= platform_offset

func _ready():
	flightscore = FlightScore.new(boulder)
	scoreScreen.connect("continue_pressed", self, "continue_pressed")
	set_up_for_current_state()

func play_sound(sound):
	# Maybe the bounce stuff here should live in the boulder scene idk.
	# Probably doesn't matter.
	var stream = null
	match sound:
		SOUNDS.BOUNCE: stream = load("res://sounds/bounce1.wav")
		SOUNDS.SUPERBOUNCE: stream = load("res://sounds/super1.wav")
		SOUNDS.PARACHUTE: stream = load("res://sounds/parachute1.wav")
		_: print("Unknown sound")
	if stream:
		audioStreamPlayer.stream = stream
		audioStreamPlayer.play()

func play_bounce_sound(super : bool):
	if super: play_sound(SOUNDS.SUPERBOUNCE)
	else: play_sound(SOUNDS.BOUNCE)
	
func apply_gravity(delta : float):
	var gravity = calculate_gravity()
	var proposed_velocity = velocity.y + (gravity * delta)
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
	if parachute_deployed:
		pass
	else:
		var is_positive = velocity.x >= 0
		var speed = abs(velocity.x)
		var d = MIN_ROTATION + (MAX_ROTATION - MIN_ROTATION) * (min(speed, MAX_EXPECTED_SPEED_FOR_ROTATION) / MAX_EXPECTED_SPEED_FOR_ROTATION)
		if not is_positive: d = -d
		boulder.rotate_sprite(d)

func launch_or_freeze_boulder():
	if frozen:
		frozen = false
		velocity = calculate_starting_velocity()
	else:
		frozen = true
		velocity = Vector2.ZERO

func continue_pressed():
	scoreScreen.visible = false
	SceneChange.set_scene(SceneChange.SCENE_SHOP)

func can_deploy_parachute():
	return State.has_parachute and !parachute_deployed and (velocity.y > 0 or velocity.x < 0)

func deploy_parachute():
	parachute_deployed = true
	velocity.x *= PARACHUTE_X_SPEED_REDUCTION
	if velocity.y > 0: 
		velocity.y *= PARACHUTE_Y_SPEED_REDUCTION
	play_sound(SOUNDS.PARACHUTE)

func _physics_process(delta):
	if Input.is_action_just_pressed("launch_boulder"):
		launch_or_freeze_boulder()

	if frozen: return
	if Input.is_action_just_pressed("superbounce"): handle_superbounce_pressed()
	if Input.is_action_just_pressed("deploy_parachute") and can_deploy_parachute():
		deploy_parachute()

	tick_superbounce_state()
	flightscore.tick(boulder)

	if parachute_deployed:
		pass
	else:
		rotate_boulder()

	var collision = boulder.move_and_collide(velocity * delta)
	if collision:
		var superbounced = is_superbouncing()
		play_bounce_sound(superbounced)
		handle_bounce(collision, superbounced)
		reset_superbounce_state()
		frozen = check_if_rolling_downhill_after_collision()
		
		if frozen: 
			scoreScreen.tween_scores(flightscore.max_height(),
			 flightscore.max_distance(),
			 flightscore.duration())
			scoreScreen.visible = true
			flightscore.reset_scores(boulder)
	else:
		apply_gravity(delta)
