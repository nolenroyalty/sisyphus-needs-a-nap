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
export var PARACHUTE_X_SPEED_REDUCTION = 0.85
export var PARACHUTE_Y_SPEED_REDUCTION = 0.25
export var PARACHUTE_GRAVITY_REDUCTION = 0.4
export var PARACHUTE_MAX_GRAVITY = 50
export var OILINESS_PENALTY_REDUCTION_FACTOR = 0.15
export var STRENGTH_INCREASE_FACTOR = 1.3
const MAX_EXPECTED_SPEED_FOR_ROTATION = 250
const DISTANCE_AT_WHICH_WE_FLAG_A_LANDMARK = 1000
const MAX_TOTAL_DOWNHILL_BOUNCES = 10
const MAX_CONSECUTIVE_DOWNHILL_BOUNCES = 2

onready var boulder = $Boulder
onready var scoreScreen = $ScoreScreen
onready var player = $Launch/Player
onready var audioStreamPlayer : AudioStreamPlayer2D = $Boulder/BouncePlayer
onready var bottom_bar : FlightBottomBar = $FlightBottomBar

enum SUPERBOUNCE_STATE {NONE, BOUNCING}
enum SOUNDS { BOUNCE, SUPERBOUNCE, PARACHUTE }
enum LAUNCH_STATE { AWAITING_LAUNCH, LAUNCHED, FROZEN }

var velocity = Vector2()
var frozen = true
var total_downhill_bounces = 0
var consecutive_downhill_bounces = 0
var superbounce_frames_remaining = 0
var superbounce_state = SUPERBOUNCE_STATE.NONE
var flightscore : FlightScore
var parachute_deployed = false
var in_cave = false
var landmarks = []
var launch_state = LAUNCH_STATE.AWAITING_LAUNCH


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

func entered_cave():
	print("entered cave") 
	in_cave = true
	
func exited_cave():
	print("exited cave")
	in_cave = false
	
func _ready():
	flightscore = FlightScore.new(boulder)
	var _ignore = scoreScreen.connect("continue_pressed", self, "continue_pressed")
	_ignore = bottom_bar.connect("parachute_deployed_via_click", self, "try_to_deploy_parachute_from_bottom_bar")
	# Make it easy to move the boulder around for testing purposes and then snap it
	# back to where it needs to be when we aren't testing 
	boulder.position = Vector2(-1230, 448)
	set_up_for_current_state()
 
	for terrain in $Terrain.get_children():
		if terrain.is_in_group("cave"):
			terrain.connect("boulder_entered", self, "entered_cave")
			terrain.connect("boulder_exited", self, "exited_cave")
		
		if terrain.is_in_group("landmark"):
			landmarks.append(terrain)

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
	else: 
		var max_gravity = MAX_GRAVITY if not parachute_deployed else PARACHUTE_MAX_GRAVITY
		velocity.y = min(proposed_velocity, max_gravity)

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
	if velocity.y < 0:
		# This can result in us bouncing more quickly in the cave when we are falling
		# so we skip it when y is negative.
		var bonus = Y_BOUNCE_BONUS * (1.2 if superbounced else 1.0)
		velocity.y *= (1 + bonus)
	

func is_rolling_downhill():
	if abs(velocity.x) < 10 or abs(velocity.y) < 10:
		return true
		
	if in_cave:
		return velocity.y < 0
	else:
		return velocity.x < 0
	
func should_freeze_after_this_bounce():
	if is_rolling_downhill():
		print("rolling downhill! in cave: %s" % in_cave)
		total_downhill_bounces += 1
		consecutive_downhill_bounces += 1
	else:
		consecutive_downhill_bounces = 0
	
	if consecutive_downhill_bounces > MAX_CONSECUTIVE_DOWNHILL_BOUNCES or total_downhill_bounces > MAX_TOTAL_DOWNHILL_BOUNCES:
		total_downhill_bounces = 0
		consecutive_downhill_bounces = 0
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
	var d = 0.0
	var is_positive = velocity.x >= 0
	var speed = abs(velocity.x)
	d = MIN_ROTATION + (MAX_ROTATION - MIN_ROTATION) * (min(speed, MAX_EXPECTED_SPEED_FOR_ROTATION) / MAX_EXPECTED_SPEED_FOR_ROTATION)
	if not is_positive: d = -d
	boulder.rotate_sprite(d)

func continue_pressed():
	scoreScreen.visible = false
	SceneChange.set_scene(SceneChange.SCENE_SHOP)

func can_deploy_parachute():
	return State.has_parachute and !parachute_deployed and launch_state == LAUNCH_STATE.LAUNCHED

func deploy_parachute():
	parachute_deployed = true
	boulder.deploy_parachute()
	velocity.x *= PARACHUTE_X_SPEED_REDUCTION
	if velocity.y > 0: 
		velocity.y *= PARACHUTE_Y_SPEED_REDUCTION
	bottom_bar.deploy_parachute()
	play_sound(SOUNDS.PARACHUTE)

func try_to_deploy_parachute_from_bottom_bar():
	if can_deploy_parachute():
		deploy_parachute()
	else:
		if launch_state == LAUNCH_STATE.LAUNCHED:
			print("Probable bug - tried to deploy parachute from bottom bar but it isn't availble!")

func landmark_to_display():
	var boulder_position = boulder.global_position

	var closest_landmark = null
	var closest_distance = null
	var angle_from_boulder = null

	for landmark in landmarks:
		var distance = boulder_position.distance_to(landmark.landmark_position_for_distance())

		if distance < DISTANCE_AT_WHICH_WE_FLAG_A_LANDMARK:
			if landmark.landmark_name() == "Cave" and in_cave:
				continue
			if closest_landmark == null or distance < closest_distance:
				closest_landmark = landmark
				closest_distance = distance
				var direction = boulder_position.direction_to(landmark.landmark_position_for_angle())
				angle_from_boulder = rad2deg(direction.angle())
	
	if closest_landmark != null:
		return [closest_landmark, closest_distance, angle_from_boulder]
	return null

func maybe_display_landmark():
	var maybe_landmark = landmark_to_display()
	if maybe_landmark != null:
		var landmark : Node2D = maybe_landmark[0]
		var distance : float = maybe_landmark[1]
		var angle = maybe_landmark[2]
		bottom_bar.display_landmark(landmark, distance, angle)
	else:
		bottom_bar.hide_landmark()

func _physics_process(delta):
	if Input.is_action_just_pressed("launch_boulder") and launch_state == LAUNCH_STATE.AWAITING_LAUNCH:
		launch_state = LAUNCH_STATE.LAUNCHED
		velocity = calculate_starting_velocity()

	if launch_state != LAUNCH_STATE.LAUNCHED:
		return

	if Input.is_action_just_pressed("superbounce"): handle_superbounce_pressed()
	if Input.is_action_just_pressed("deploy_parachute") and can_deploy_parachute():
		deploy_parachute()

	tick_superbounce_state()
	flightscore.tick(boulder)
	maybe_display_landmark()
	rotate_boulder()

	var collision = boulder.move_and_collide(velocity * delta)
	if collision:
		var superbounced = is_superbouncing()
		play_bounce_sound(superbounced)
		handle_bounce(collision, superbounced)
		reset_superbounce_state()
		
		if should_freeze_after_this_bounce():
			launch_state = LAUNCH_STATE.FROZEN
			scoreScreen.tween_scores(flightscore.max_height(),
			 flightscore.max_distance(),
			 flightscore.duration())
			scoreScreen.visible = true
			flightscore.reset_scores(boulder)
			boulder.stop_animating()
	else:
		apply_gravity(delta)
