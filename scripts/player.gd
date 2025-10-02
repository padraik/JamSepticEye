extends CharacterBody2D

@export var speed = 300.0
@onready var conversion_area = $ConversionArea
@onready var animated_sprite = $AnimatedSprite2D

var is_stabbing = false
var stab_timer: Timer

func _ready():
	# Connect to animation finished signal
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Create timer for stab animation
	stab_timer = Timer.new()
	stab_timer.wait_time = 0.5  # Half second for faster stab animation
	stab_timer.one_shot = true
	stab_timer.timeout.connect(_on_stab_timer_timeout)
	add_child(stab_timer)

func _physics_process(_delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	
	update_animation(direction)
	update_facing_direction(direction)

	if Input.is_action_just_pressed("ui_accept"):  # Enter key
		print("Enter pressed, playing stab animation")
		_attempt_conversion()
		is_stabbing = true
		animated_sprite.play("stab")
		# Start timer as backup
		stab_timer.start()

func update_animation(direction):
	# Handle animations based on movement (but don't override stab animation)
	if not is_stabbing:
		if direction.length() > 0:
			# Player is moving - play run animation
			if animated_sprite.animation != "run":
				animated_sprite.play("run")
		else:
			# Player is not moving - play idle animation
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")

func update_facing_direction(direction):
	if direction.x < 0:
		animated_sprite.flip_h = true
	elif direction.x > 0:
		animated_sprite.flip_h = false
	
	# Debug: Print current animation state every few frames
	if Engine.get_process_frames() % 60 == 0:  # Print every 60 frames (about once per second)
		print("Current animation: ", animated_sprite.animation, " is_stabbing: ", is_stabbing)

func _attempt_conversion():
	var bodies = conversion_area.get_overlapping_bodies()
	var closest_body = null
	var min_distance = INF

	for body in bodies:
		if body.is_in_group("humans"):
			var distance = position.distance_to(body.position)
			if distance < min_distance:
				min_distance = distance
				closest_body = body
	
	if closest_body:
		closest_body.infect()

func _on_animation_finished():
	# When stab animation finishes, return to appropriate movement animation
	print("Animation finished: ", animated_sprite.animation)
	if animated_sprite.animation == "stab":
		print("Stab animation finished, returning to movement animation")
		_return_to_movement_animation()

func _on_stab_timer_timeout():
	# Timer backup in case animation_finished doesn't fire
	if is_stabbing:
		print("Timer timeout - forcing return to movement animation")
		_return_to_movement_animation()

func _return_to_movement_animation():
	print("_return_to_movement_animation called")
	is_stabbing = false
	stab_timer.stop()
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	print("Direction length: ", direction.length())
	if direction.length() > 0:
		print("Playing run animation")
		animated_sprite.play("run")
	else:
		print("Playing idle animation")
		animated_sprite.play("idle")
