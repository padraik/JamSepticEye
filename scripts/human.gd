extends "res://scripts/person.gd"

const FLEEING = 3

var flee_target = null
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	super()
	state = IDLE

func _physics_process(delta):
	if state == IDLE or state == WANDER:
		_scan_for_targets()

	if state == FLEEING:
		if is_instance_valid(flee_target):
			var direction = flee_target.position.direction_to(position)
			velocity = direction * speed * 1.5 # Flee faster than wandering
			move_and_slide()
			
			if not flee_target in $DetectionArea.get_overlapping_bodies():
				if $FleeCooldownTimer.is_stopped():
					$FleeCooldownTimer.start()
		else:
			state = IDLE
			flee_target = null
			_start_idle_timer()
	else:
		super(delta)
	
	# Update animations
	_update_animation()

func _scan_for_targets():
	var bodies = $DetectionArea.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("zombies"):
			if has_line_of_sight(body):
				if not is_instance_valid(flee_target):
					state = FLEEING
					flee_target = body
					$WanderTimer.stop()
					return

func _on_flee_cooldown_timer_timeout():
	state = IDLE
	flee_target = null
	_start_idle_timer()

func _update_animation():
	# Handle animations based on state and movement
	if state == FLEEING:
		# When fleeing, always play run animation
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	elif state == WANDER and velocity.length() > 0:
		# When wandering and moving, play run animation
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	elif state == IDLE:
		# When idle, play idle animation
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
	elif state == INFECTED:
		# When infected, play die animation
		if animated_sprite.animation != "die":
			animated_sprite.play("die")
