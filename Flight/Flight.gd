extends Node2D


export var GRAVITY = 120
export var MAX_GRAVITY = 300
export var BOUNCE_PENALTY = 0.2

export var BACKWARDS_ROLL_SPEED = 1.0
export var DEFAULT_STARTING_VELOCITY = Vector2(250, -100)
export var SUPERBOUNCE_FRAMES = 10
export var MIN_ROTATION = 1.0
export var MAX_ROTATION = 10.0
export var PARACHUTE_X_SPEED_REDUCTION = 0.85
export var PARACHUTE_Y_SPEED_REDUCTION = 0.25
export var PARACHUTE_GRAVITY_REDUCTION = 0.4
export var PARACHUTE_MAX_GRAVITY = 50
export var STRENGTH_INCREASE_FACTOR = 1.3
export var SLINGSHOT_BOOST = 100
const MAX_EXPECTED_SPEED_FOR_ROTATION = 250
const DISTANCE_AT_WHICH_WE_FLAG_A_LANDMARK = 1000
const MAX_TOTAL_DOWNHILL_BOUNCES = 50
const MAX_CONSECUTIVE_DOWNHILL_BOUNCES = 2
const SLINGSHOT_AMMO = 4
const FRAMES_TO_SPEND_IN_LAVA = 60 * 2

onready var boulder = $Boulder
onready var scoreScreen = $ScoreScreen
onready var text_display = $TextDisplay
onready var player = $Launch/Player
onready var audioStreamPlayer : AudioStreamPlayer2D = $Boulder/BouncePlayer
onready var bottom_bar : FlightBottomBar = $FlightBottomBar

enum SUPERBOUNCE_STATE {NONE, BOUNCING}
enum SOUNDS { LAUNCH, BOUNCE, SUPERBOUNCE, PARACHUTE, SLINGSHOT }
enum LAUNCH_STATE { DISPLAYING_FACTS, AWAITING_LAUNCH, LAUNCHED, IN_LAVA, FROZEN }

var velocity = Vector2()
var frames_in_lava = 0
var frozen = true
var total_downhill_bounces = 0
var consecutive_downhill_bounces = 0
var superbounce_frames_remaining = 0
var oil_remaining = 0
var slingshot_shots_remaining = 0
var superbounce_state = SUPERBOUNCE_STATE.NONE
var flightscore : FlightScore
var parachute_deployed = false
var in_cave = false
var landmarks = []
var launch_state = LAUNCH_STATE.DISPLAYING_FACTS


func calculate_gravity():
	if parachute_deployed and velocity.y > 0:
		return GRAVITY * PARACHUTE_GRAVITY_REDUCTION
	else:
		return GRAVITY

func calculate_starting_velocity():
	var starting_velocity = DEFAULT_STARTING_VELOCITY
	var multiplier = 1
	match State.strength_level:
		0: multiplier = 1.0
		1: multiplier = 1.5
		2: multiplier = 1.9
		3: multiplier = 2.3
		_:
			print("Unknown strength level %d" % State.strength_level)
	
	starting_velocity *= multiplier
	return starting_velocity

func set_positions_for_current_block_height():
	var b = State.block_height
	var platform_offset = 0
	while b > 0:
		platform_offset += 21
		if b % 3 == 0: platform_offset += 1
		b -= 1
	boulder.position.y -= platform_offset
	player.position.y -= platform_offset

func entered_cave():
	print("entered cave") 
	in_cave = true
	
func exited_cave():
	print("exited cave")
	in_cave = false

func handle_entered_lava():
	print("handling entered lava")
	launch_state = LAUNCH_STATE.IN_LAVA
	frames_in_lava = 0
	velocity = Vector2.ZERO

func freeze_and_display_scores(aborted):
	scoreScreen.set_title(aborted)
	launch_state = LAUNCH_STATE.FROZEN
	scoreScreen.tween_scores(flightscore.max_height(),
	 flightscore.max_distance(),
	 flightscore.duration())
	scoreScreen.visible = true
	flightscore.reset_scores(boulder)
	boulder.stop_animating()
	State.launch_day += 1

func handle_abort():
	if launch_state != LAUNCH_STATE.LAUNCHED: return
	freeze_and_display_scores(true)

func handle_fact_display_gone():
	launch_state = LAUNCH_STATE.AWAITING_LAUNCH

func _ready():
	State.display_fact_if_we_havent_yet(State.FACT.INTRO)
	flightscore = FlightScore.new(boulder)
	var _ignore = scoreScreen.connect("continue_pressed", self, "continue_pressed")
	_ignore = bottom_bar.connect("parachute_deployed_via_click", self, "try_to_deploy_parachute_from_bottom_bar")
	_ignore = bottom_bar.connect("abort_clicked", self, "handle_abort")
	_ignore = boulder.connect("boulder_clicked", self, "handle_boulder_clicked")
	_ignore = text_display.connect("no_facts_are_displayed", self, "handle_fact_display_gone")
	# Make it easy to move the boulder around for testing purposes and then snap it
	# back to where it needs to be when we aren't testing 
	# boulder.position = Vector2(-1230, 448)
	set_positions_for_current_block_height()
	
	oil_remaining = State.oil_level
	if State.has_slingshot:
		slingshot_shots_remaining = SLINGSHOT_AMMO
 
	for terrain in $Terrain.get_children():
		if terrain.is_in_group("cave"):
			terrain.connect("boulder_entered", self, "entered_cave")
			terrain.connect("boulder_exited", self, "exited_cave")
		
		if terrain.is_in_group("lava"):
			terrain.connect("entered_lava", self, "handle_entered_lava")
		
		if terrain.is_in_group("landmark"):
			landmarks.append(terrain)
	
	text_display.maybe_display_facts()

func play_sound(sound):
	# Maybe the bounce stuff here should live in the boulder scene idk.
	# Probably doesn't matter.
	var stream = null
	match sound:
		SOUNDS.LAUNCH: stream = load("res://sounds/launch1.wav")
		SOUNDS.BOUNCE: stream = load("res://sounds/bounce1.wav")
		SOUNDS.SUPERBOUNCE: stream = load("res://sounds/super1.wav")
		SOUNDS.PARACHUTE: stream = load("res://sounds/parachute1.wav")
		SOUNDS.SLINGSHOT: stream = load("res://sounds/slingshot1.wav")
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
	velocity = velocity.bounce(collision.normal)
	var bounce_penalty = BOUNCE_PENALTY

	if superbounced:
		bounce_penalty *= 0.5
	
	if oil_remaining > 0:
		bounce_penalty = 0
		oil_remaining -= 1
		boulder.update_oil_visibility(oil_remaining)
	
	velocity *= (1 - bounce_penalty)
	# Reduce y a little bit no matter what, and by some extra, so that the ball doesn't feel
	# too bouncey
	velocity.y *= (1 - bounce_penalty)
	
func handle_boulder_clicked(vector_from_click_to_boulder_center):
	if launch_state != LAUNCH_STATE.LAUNCHED:
		return
	
	if State.has_slingshot and slingshot_shots_remaining > 0:
		slingshot_shots_remaining -= 1
		velocity += vector_from_click_to_boulder_center.normalized() * SLINGSHOT_BOOST
		bottom_bar.set_slingshot_ammo(slingshot_shots_remaining)
		play_sound(SOUNDS.SLINGSHOT)

func is_rolling_downhill():
	var vx = abs(velocity.x)
	var vy = abs(velocity.y)
	if vx < 20 and vy < 20: return true
	if vx + vy < 50: return true
	
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

func process_lava(delta):
	frames_in_lava += 1
	if frames_in_lava >= FRAMES_TO_SPEND_IN_LAVA:
		freeze_and_display_scores(false)
	else:
		var x = 35.0
		if velocity.y < -x: velocity.y = 5
		elif velocity.y < 0: velocity.y -= 5
		elif velocity.y > 2*x: velocity.y = -5
		else: velocity.y += 5
		boulder.move_and_collide(velocity * delta)

func launch_boulder():
	launch_state = LAUNCH_STATE.LAUNCHED
	velocity = calculate_starting_velocity()
	play_sound(SOUNDS.LAUNCH)

func process_launched(delta):
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
			freeze_and_display_scores(false)
	else:
		apply_gravity(delta)

func _physics_process(delta):
	match launch_state:
		LAUNCH_STATE.AWAITING_LAUNCH:
			if Input.is_action_just_pressed("launch_boulder"):
				launch_boulder()
		LAUNCH_STATE.IN_LAVA: process_lava(delta)
		LAUNCH_STATE.LAUNCHED: process_launched(delta)
		_: pass