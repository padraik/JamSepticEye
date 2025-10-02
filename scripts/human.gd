extends "res://scripts/person.gd"

const FLEEING = 3

var flee_target = null

func _ready():
	super()
	state = IDLE

func _physics_process(delta):
	if state == FLEEING:
		if is_instance_valid(flee_target):
			var direction = flee_target.position.direction_to(position)
			velocity = direction * speed * 1.5 # Flee faster than wandering
			move_and_slide()
			
			var zombie_detection_area = flee_target.get_node("DetectionArea")
			if self in zombie_detection_area.get_overlapping_bodies():
				if not $FleeCooldownTimer.is_stopped():
					$FleeCooldownTimer.stop()
			else:
				if $FleeCooldownTimer.is_stopped():
					$FleeCooldownTimer.start()
		else:
			state = IDLE
			flee_target = null
			_start_idle_timer()
	else:
		super(delta)

func _on_detection_area_body_entered(body):
	if body.is_in_group("zombies"):
		if body.is_down():
			return
		if not is_instance_valid(flee_target): # Only acquire a new target if not already fleeing
			state = FLEEING
			flee_target = body
			$WanderTimer.stop()

func _on_flee_cooldown_timer_timeout():
	state = IDLE
	flee_target = null
	_start_idle_timer()
