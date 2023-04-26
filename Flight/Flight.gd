extends Node2D

# I would fail someone in an interview if they chose names like this, but I'm
# the boss now.
var achievementDisplay = preload("res://UI/AchievementDisplay.tscn")
var achievementShower = preload("res://UI/AchievementShower.tscn")
var rng = RandomNumberGenerator.new()

export var GRAVITY = 120
export var MAX_GRAVITY = 300
export var BOUNCE_PENALTY = 0.2

export var BACKWARDS_ROLL_SPEED = 1.0
export var DEFAULT_STARTING_VELOCITY = Vector2(250, -110)
export var SUPERBOUNCE_FRAMES = 10
export var MIN_ROTATION = 1.0
export var MAX_ROTATION = 10.0
export var PARACHUTE_X_SPEED_REDUCTION = 0.85
export var PARACHUTE_Y_SPEED_REDUCTION = 0.25
export var PARACHUTE_GRAVITY_REDUCTION = 0.40
export(float) var PARACHUTE_MAX_GRAVITY = PARACHUTE_GRAVITY_REDUCTION * MAX_GRAVITY
export var STRENGTH_INCREASE_FACTOR = 1.3
export var SLINGSHOT_BOOST = 100
export var GRIFFIN_BOOST = Vector2(10, -150)
const MAX_EXPECTED_SPEED_FOR_ROTATION = 250
const DISTANCE_AT_WHICH_WE_FLAG_A_LANDMARK = 1600
const MAX_TOTAL_DOWNHILL_BOUNCES = 50
const MAX_CONSECUTIVE_DOWNHILL_BOUNCES = 8
const MAX_CONSECUTIVE_SLOW_BOUNCES = 3
const MAX_CONSECUTIVE_CAVE_BOUNCES = 5
const SLINGSHOT_AMMO = 4
const FRAMES_TO_SPEND_IN_LAVA = 60 * 2
const GRIFFIN_DEPLOY_TIME = 1.5

const SOUND_LAUNCH = preload("res://Sounds/launch1.wav")
const SOUND_BOUNCE = preload("res://Sounds/bounce1.wav")
const SOUND_SUPERBOUNCE = preload("res://Sounds/super1.wav")
const SOUND_PARACHUTE = preload("res://Sounds/parachute1.wav")
const SOUND_SLINGSHOT = preload("res://Sounds/slingshot1.wav")
const SOUND_LAVA = preload("res://Sounds/lava1.wav")
const SOUND_GRIFFIN = preload("res://Sounds/griffin1.wav")

onready var boulder = $Boulder
onready var scoreScreen = $ScoreScreen
onready var text_display = $TextDisplay
onready var player = $Launch/Player
onready var audioStreamPlayer : AudioStreamPlayer2D = $Boulder/BouncePlayer
onready var bottom_bar : FlightBottomBar = $FlightBottomBar

enum SUPERBOUNCE_STATE {NONE, BOUNCING}
enum SOUNDS { LAUNCH, BOUNCE, SUPERBOUNCE, PARACHUTE, SLINGSHOT, LAVA, GRIFFIN }
enum LAUNCH_STATE { DISPLAYING_FACTS, AWAITING_LAUNCH, LAUNCHED, GRIFFIN_DEPLOYED, IN_LAVA, FROZEN }

var velocity = Vector2()
var frames_in_lava = 0
var frozen = true
var total_downhill_bounces = 0
var consecutive_downhill_bounces = 0
var consecutive_slow_bounces
var consecutive_cave_bounces = 0
var superbounce_frames_remaining = 0
var oil_remaining = 0
var slingshot_shots_remaining = 0
var superbounce_state = SUPERBOUNCE_STATE.NONE
var flightscore : FlightScore
var parachute_deployed = false
var griffin_deployed = false
var in_cave = false
var landmarks = []
var launch_state = LAUNCH_STATE.DISPLAYING_FACTS
var achievement_display = null

func calculate_gravity():
	if parachute_deployed and velocity.y > 0:
		return GRAVITY * PARACHUTE_GRAVITY_REDUCTION
	else:
		return GRAVITY

func calculate_starting_velocity():
	var starting_velocity = DEFAULT_STARTING_VELOCITY
	var multiplier = 1
	
	match State.strength_level:
		0:  
			multiplier = 1.0
		1: 
			multiplier = 1.35
		2: multiplier = 1.7
		3: multiplier = 1.85
		4: multiplier = 2.0
		5: multiplier = 2.2
		6: multiplier = 2.6
		_:
			print("Unknown strength level %d" % State.strength_level)
	
	var variance = rng.randf_range(-.12, 0.12)
	starting_velocity *= multiplier
	print("velocity: %s variance: %s -> %s" % [starting_velocity, variance, starting_velocity * variance])
	starting_velocity += starting_velocity * variance
	return starting_velocity

func set_positions_for_current_block_height():
	var platform_offset = State.block_height * 24
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
	play_sound(SOUNDS.LAVA)

func freeze_and_display_scores(aborted):
	launch_state = LAUNCH_STATE.FROZEN
	boulder.stop_animating()
	var achievement_shower = achievementShower.instance()
	add_child(achievement_shower)
	# Avoid a race where maybe_display_achievements returns immediately,
	# before we yield to its signal
	achievement_shower.call_deferred("maybe_display_achievements")
	yield(achievement_shower, "no_achievements_are_displayed")
	achievement_shower.queue_free()
	scoreScreen.set_title(aborted)
	scoreScreen.tween_scores(flightscore.max_height(),
	 flightscore.max_distance(),
	 flightscore.duration())
	scoreScreen.visible = true
	flightscore.reset_scores(boulder)
	
	State.launch_day += 1

func handle_abort():
	if launch_state != LAUNCH_STATE.LAUNCHED: return
	freeze_and_display_scores(true)

func handle_fact_display_gone():
	launch_state = LAUNCH_STATE.AWAITING_LAUNCH
	# If we just hide and show the achievement display the text for it doesn't
	# show up but its collision boxes do? Worth debugging to understand godot
	# but just instancing every time seems to fix it.
	achievement_display = achievementDisplay.instance()
	add_child(achievement_display)
 
func _ready():
	rng.randomize()
	State.display_fact_if_we_havent_yet(State.FACT.INTRO)
	flightscore = FlightScore.new(boulder)
	var _ignore = scoreScreen.connect("continue_pressed", self, "continue_pressed")
	_ignore = bottom_bar.connect("parachute_deployed_via_click", self, "try_to_deploy_parachute_from_bottom_bar")
	_ignore = bottom_bar.connect("griffin_deployed_via_click", self, "try_to_deploy_griffin_from_bottom_bar")
	_ignore = bottom_bar.connect("abort_clicked", self, "handle_abort")
	_ignore = boulder.connect("boulder_clicked", self, "handle_boulder_clicked")
	_ignore = text_display.connect("no_facts_are_displayed", self, "handle_fact_display_gone")

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
	var volume_db = -7.5
	match sound:
		SOUNDS.LAUNCH: 
			stream = SOUND_LAUNCH
			volume_db = -20.0
		SOUNDS.BOUNCE: stream = SOUND_BOUNCE
		SOUNDS.SUPERBOUNCE: stream = SOUND_SUPERBOUNCE
		SOUNDS.PARACHUTE: stream = SOUND_PARACHUTE
		SOUNDS.SLINGSHOT: stream = SOUND_SLINGSHOT
		SOUNDS.LAVA: stream = SOUND_LAVA
		SOUNDS.GRIFFIN: stream = SOUND_GRIFFIN
		_: print("Unknown sound")
		
	if stream:
		audioStreamPlayer.stream = stream
		audioStreamPlayer.volume_db = volume_db
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

func is_downhill_bounce():
	return velocity.x < 0

func is_slow_bounce():
	var vx = abs(velocity.x)
	var vy = abs(velocity.y)
	return (vx < 20 and vy < 20) or (vx + vy) < 50

func is_cave_bounce():
	return in_cave
	
func should_freeze_after_this_bounce():
	if is_downhill_bounce():
		consecutive_downhill_bounces += 1
		total_downhill_bounces += 1
	else:
		consecutive_downhill_bounces = 0
	
	if is_cave_bounce() and is_slow_bounce():
		consecutive_cave_bounces += 1
	else:
		consecutive_cave_bounces = 0
	
	if is_slow_bounce():
		consecutive_slow_bounces += 1
	else:
		consecutive_slow_bounces = 0
	

	return consecutive_cave_bounces >= MAX_CONSECUTIVE_CAVE_BOUNCES \
		or consecutive_downhill_bounces >= MAX_CONSECUTIVE_DOWNHILL_BOUNCES \
		or consecutive_slow_bounces >= MAX_CONSECUTIVE_SLOW_BOUNCES \
		or total_downhill_bounces >= MAX_TOTAL_DOWNHILL_BOUNCES

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

func can_deploy_griffin():
	return State.has_griffin and !griffin_deployed and launch_state == LAUNCH_STATE.LAUNCHED

func deploy_griffin():
	if velocity.y > 0:
		velocity.y = 0
		
	griffin_deployed = true
	launch_state = LAUNCH_STATE.GRIFFIN_DEPLOYED
	bottom_bar.deploy_griffin()
	boulder.show_griffin()
	play_sound(SOUNDS.GRIFFIN)
	yield(get_tree().create_timer(GRIFFIN_DEPLOY_TIME), "timeout")
	boulder.hide_griffin()
	launch_state = LAUNCH_STATE.LAUNCHED


func try_to_deploy_parachute_from_bottom_bar():
	if can_deploy_parachute():
		deploy_parachute()
	else:
		if launch_state == LAUNCH_STATE.LAUNCHED:
			print("Probable bug - tried to deploy parachute from bottom bar but it isn't availble!")

func try_to_deploy_griffin_from_bottom_bar():
	if can_deploy_griffin():
		deploy_griffin()
	else:
		if launch_state == LAUNCH_STATE.LAUNCHED:
			print("Probable bug - tried to deploy griffin from bottom bar but it isn't availble!")

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
	achievement_display.queue_free()
	launch_state = LAUNCH_STATE.LAUNCHED
	velocity = calculate_starting_velocity()
	play_sound(SOUNDS.LAUNCH)

func maybe_tick_hud():
	bottom_bar.maybe_update_stats(
		flightscore.current_distance(boulder),
		boulder.determine_height_above_ground(),
		flightscore.duration(),
		in_cave)

func process_launched(delta):
	if Input.is_action_just_pressed("superbounce"): handle_superbounce_pressed()
	if Input.is_action_just_pressed("deploy_parachute") and can_deploy_parachute():
		deploy_parachute()
	if Input.is_action_just_pressed("deploy_griffin") and can_deploy_griffin():
		deploy_griffin()

	tick_superbounce_state()
	flightscore.tick(boulder)
	maybe_display_landmark()
	rotate_boulder()
	maybe_tick_hud()
  
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

func process_griffin(delta):
	velocity += GRIFFIN_BOOST * delta
	boulder.move_and_collide(velocity * delta)
	flightscore.tick(boulder)
	maybe_tick_hud()
	maybe_display_landmark()
 
func _physics_process(delta):
	match launch_state:
		LAUNCH_STATE.AWAITING_LAUNCH:
			if Input.is_action_just_pressed("launch_boulder"):
				launch_boulder()
		LAUNCH_STATE.IN_LAVA: process_lava(delta)
		LAUNCH_STATE.LAUNCHED: process_launched(delta)
		LAUNCH_STATE.GRIFFIN_DEPLOYED: process_griffin(delta)
		_: pass
