extends "res://scripts/person.gd"

const KILL = 3
const PROJECTILE_SCENE = preload("res://scenes/projectile.tscn")

var kill_target = null
var can_fire = true

func _ready():
	super()
	add_to_group("police")
	state = IDLE

func _physics_process(delta):
	if state == IDLE or state == WANDER:
		_scan_for_targets()

	if state == KILL:
		velocity = Vector2.ZERO
		move_and_slide()
		if is_instance_valid(kill_target):
			if kill_target.is_down():
				state = WANDER
				kill_target = null
				_pick_new_wander_destination()
			elif can_fire:
				_fire_projectile()
		else:
			state = WANDER
			kill_target = null
			_pick_new_wander_destination()
	else:
		super(delta)

func _fire_projectile():
	if not has_line_of_sight(kill_target):
		return # Lost line of sight, can't fire

	can_fire = false
	SoundManager.emit_sound(position, 1200.0)
	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.position = position
	projectile.target_position = kill_target.position
	get_parent().add_child(projectile)
	$FireRateTimer.start()
	
func _scan_for_targets():
	var bodies = $DetectionArea.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("zombies"):
			if has_line_of_sight(body):
				if not is_instance_valid(kill_target):
					if body.is_down():
						return
					state = KILL
					kill_target = body
					$WanderTimer.stop()
					return

func _on_detection_area_body_exited(body):
	if body == kill_target:
		state = WANDER
		kill_target = null
		_pick_new_wander_destination()

func _on_fire_rate_timer_timeout():
	can_fire = true
