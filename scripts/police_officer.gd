extends CharacterBody2D

const PROJECTILE_SCENE = preload("res://scenes/projectile.tscn")

@export var speed = 100.0
@export var wander_range = 200

enum State { IDLE, WANDER, KILL }
var state = State.IDLE
var target_position = Vector2.ZERO
var kill_target = null
var can_fire = true
var is_being_converted = false

func _ready():
	add_to_group("humans")
	add_to_group("police")
	target_position = position
	_start_idle_timer()

func _physics_process(_delta):
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			move_and_slide()
		State.WANDER:
			if position.distance_to(target_position) > 5.0:
				var direction = position.direction_to(target_position)
				velocity = direction * speed
				move_and_slide()
			else:
				state = State.IDLE
				velocity = Vector2.ZERO
				_start_idle_timer()
		State.KILL:
			velocity = Vector2.ZERO
			move_and_slide()
			if is_instance_valid(kill_target) and can_fire:
				_fire_projectile()

func _fire_projectile():
	can_fire = false
	SoundManager.emit_sound(position, 1200.0)
	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.position = position
	projectile.target_position = kill_target.position
	get_parent().add_child(projectile)
	$FireRateTimer.start()

func _pick_new_wander_destination():
	var random_offset = Vector2(randf_range(-wander_range, wander_range), randf_range(-wander_range, wander_range))
	target_position = position + random_offset
	target_position.x = clamp(target_position.x, 0, 1024)
	target_position.y = clamp(target_position.y, 0, 600)

func _start_idle_timer():
	$WanderTimer.wait_time = randf_range(1.0, 2.0)
	$WanderTimer.start()

func _on_wander_timer_timeout():
	if state == State.IDLE:
		state = State.WANDER
		_pick_new_wander_destination()

func _on_detection_area_body_entered(body):
	if body.is_in_group("zombies"):
		if not is_instance_valid(kill_target):
			state = State.KILL
			kill_target = body
			$WanderTimer.stop()

func _on_detection_area_body_exited(body):
	if body == kill_target:
		state = State.WANDER
		kill_target = null
		_pick_new_wander_destination()

func _on_fire_rate_timer_timeout():
	can_fire = true
